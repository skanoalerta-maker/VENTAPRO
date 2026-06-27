import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase/ocr_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveScannerScreen extends StatefulWidget {
  const LiveScannerScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cyanGlow = Color(0xFF00D4FF);
  static const Color bgDark = Color(0xFF020617);
  static const Color panelDark = Color(0xFF05070B);

  @override
  State<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<LiveScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;

  late final TextRecognizer _textRecognizer;
  late final AnimationController _scanAnimationController;
  late final Animation<double> _scanAnimation;

  final TextEditingController _manualPlateController = TextEditingController();

  bool _initializing = true;
  bool _processing = false;
  bool _saving = false;
  bool _flashOn = false;
  bool _cameraReady = false;

  String _detectedPlate = '';
  String _rawText = '';
  String _statusText = 'Inicializando lector SKANO PPU...';
  String? _errorMessage;

  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _cameraReady = false;
          _statusText = 'Cámara no disponible';
          _errorMessage = 'No se encontró una cámara disponible.';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      await _cameraController!.startImageStream(_processCameraImage);

      if (!mounted) return;

      setState(() {
        _initializing = false;
        _cameraReady = true;
        _statusText = 'Centra la patente dentro del marco';
      });
    } catch (e) {
      debugPrint('ERROR INIT CAMERA: $e');

      if (!mounted) return;

      setState(() {
        _initializing = false;
        _cameraReady = false;
        _statusText = 'Error al iniciar cámara';
        _errorMessage = 'No se pudo iniciar la cámara. Revisa los permisos.';
      });
    }
  }

  String _normalizePlate(String value) {
    return value
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(':', '')
        .replaceAll(';', '')
        .replaceAll('|', '')
        .replaceAll('Ñ', 'N')
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _fixAsLetter(String c) {
    switch (c) {
      case '0':
        return 'O';
      case '1':
        return 'I';
      case '2':
        return 'Z';
      case '5':
        return 'S';
      case '8':
        return 'B';
      default:
        return c;
    }
  }

  String _fixAsNumber(String c) {
    switch (c) {
      case 'O':
        return '0';
      case 'I':
        return '1';
      case 'Z':
        return '2';
      case 'S':
        return '5';
      case 'B':
        return '8';
      default:
        return c;
    }
  }

  String _normalizeChileanPlate(String plate) {
    final clean = _normalizePlate(plate);

    if (clean.length != 6) return clean;

    final chars = clean.split('');

    final possibleNew =
        '${_fixAsLetter(chars[0])}'
        '${_fixAsLetter(chars[1])}'
        '${_fixAsLetter(chars[2])}'
        '${_fixAsLetter(chars[3])}'
        '${_fixAsNumber(chars[4])}'
        '${_fixAsNumber(chars[5])}';

    if (_isValidNewPlate(possibleNew)) return possibleNew;

    final possibleOld =
        '${_fixAsLetter(chars[0])}'
        '${_fixAsLetter(chars[1])}'
        '${_fixAsNumber(chars[2])}'
        '${_fixAsNumber(chars[3])}'
        '${_fixAsNumber(chars[4])}'
        '${_fixAsNumber(chars[5])}';

    if (_isValidOldPlate(possibleOld)) return possibleOld;

    return clean;
  }

  String _extractPlate(String text) {
    final clean = _normalizePlate(text);

    final candidates = <String>[];

    final looseRegex = RegExp(r'[A-Z0-9]{6}');
    for (final match in looseRegex.allMatches(clean)) {
      candidates.add(match.group(0)!);
    }

    for (final candidate in candidates) {
      final normalized = _normalizeChileanPlate(candidate);

      if (_isValidChileanPlate(normalized)) {
        return normalized;
      }
    }

    return '';
  }

  Rect _scannerRoiForImage(Size imageSize) {
    final width = imageSize.width;
    final height = imageSize.height;

    // Zona útil del lector.
    // Esto evita que el OCR reaccione a textos fuera del marco central.
    final left = width * 0.09;
    final right = width * 0.91;
    final top = height * 0.34;
    final bottom = height * 0.66;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  bool _isTextBoxInsideScanner(Rect box, Rect scannerRoi) {
    final center = box.center;

    return scannerRoi.contains(center);
  }

  String _textInsideScannerArea(RecognizedText recognizedText, Size imageSize) {
    final scannerRoi = _scannerRoiForImage(imageSize);
    final linesInside = <String>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;

        if (_isTextBoxInsideScanner(box, scannerRoi)) {
          linesInside.add(line.text);
        }
      }
    }

    return linesInside.join(' ');
  }

  bool _isValidChileanPlate(String plate) {
    return _isValidNewPlate(plate) || _isValidOldPlate(plate);
  }

  bool _isValidNewPlate(String plate) {
    return RegExp(r'^[A-Z]{4}[0-9]{2}$').hasMatch(plate);
  }

  bool _isValidOldPlate(String plate) {
    return RegExp(r'^[A-Z]{2}[0-9]{4}$').hasMatch(plate);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processing || _saving) return;

    final now = DateTime.now();

    if (now.difference(_lastScan).inMilliseconds < 1000) return;

    _lastScan = now;
    _processing = true;

    try {
      final controller = _cameraController;

      if (controller == null || !controller.value.isInitialized) {
        _processing = false;
        return;
      }

      final WriteBuffer allBytes = WriteBuffer();

      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      final bytes = allBytes.done().buffer.asUint8List();

      final rotation = InputImageRotationValue.fromRawValue(
            controller.description.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(
            image.format.raw,
          ) ??
          InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );

      final recognizedText = await _textRecognizer.processImage(inputImage);

      final scannerText = _textInsideScannerArea(
        recognizedText,
        Size(image.width.toDouble(), image.height.toDouble()),
      );

      final plate = _extractPlate(scannerText);

      if (!mounted) return;

      if (plate.isNotEmpty && plate != _detectedPlate) {
        _manualPlateController.text = plate;

        setState(() {
          _detectedPlate = plate;
          _rawText = scannerText;
          _statusText = 'Patente detectada dentro del marco. Confirma antes de guardar.';
          _errorMessage = null;
        });
      } else if (_detectedPlate.isEmpty) {
        setState(() {
          _statusText = scannerText.trim().isEmpty
              ? 'Apunta la patente dentro del marco...'
              : 'Buscando patente solo dentro del marco...';
        });
      }
    } catch (e) {
      debugPrint('ERROR OCR: $e');
    } finally {
      _processing = false;
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) return;

    try {
      _flashOn = !_flashOn;

      await controller.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('ERROR FLASH: $e');
    }
  }

  Future<void> _saveScan(String correctedPlate) async {
    if (_saving) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _saving = true;
      _statusText = 'Verificando patente...';
      _errorMessage = null;
    });

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      await Future.delayed(const Duration(milliseconds: 50));

      final XFile capturedFile = await controller.takePicture();
      final imageFile = File(capturedFile.path);

      final now = DateTime.now();
      final fileName = 'scan_${now.millisecondsSinceEpoch}.jpg';
      final storagePath = 'ocr_scans/$fileName';

      final ocrStorage = FirebaseStorage.instanceFor(app: ocrFirebaseApp!);
      final ocrFirestore = FirebaseFirestore.instanceFor(app: ocrFirebaseApp!);

      final storageRef = ocrStorage.ref().child(storagePath);
      final docRef = ocrFirestore.collection('ocr_scans').doc();

      final stolenSnap = await FirebaseFirestore.instance
          .collection('stolen_vehicles')
          .doc(correctedPlate)
          .get();

      await docRef.set({
        'detected_text': _detectedPlate,
        'corrected_text': correctedPlate,
        'was_corrected': correctedPlate != _detectedPlate,
        'raw_text': _rawText,
        'photo_url': null,
        'storage_path': storagePath,
        'upload_status': 'pending',
        'has_stolen_report': stolenSnap.exists,
        'stolen_vehicle_id': stolenSnap.exists ? stolenSnap.id : null,
        'created_at': FieldValue.serverTimestamp(),
        'source': 'skano_ppu_live',
        'country': 'CL',
        'engine_version': 'skano_ppu_live_v3_fast',
      });

final uid = FirebaseAuth.instance.currentUser?.uid;

if (uid != null) {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .set({
    "plate_reads_count": FieldValue.increment(1),
    "last_plate_read_at": FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
      unawaited(
        storageRef.putFile(imageFile).then((_) async {
          final photoUrl = await storageRef.getDownloadURL();

          await docRef.update({
            'photo_url': photoUrl,
            'upload_status': 'completed',
            'uploaded_at': FieldValue.serverTimestamp(),
          });
        }).catchError((e) async {
          debugPrint('ERROR BACKGROUND UPLOAD OCR: $e');

          await docRef.update({
            'upload_status': 'failed',
            'upload_error': e.toString(),
            'upload_failed_at': FieldValue.serverTimestamp(),
          });
        }),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stolenSnap.exists
                ? '🚨 Patente con encargo encontrada en SKANO'
                : 'Escaneo guardado. Patente sin encargo en SKANO',
          ),
          backgroundColor: stolenSnap.exists ? Colors.redAccent : Colors.green,
        ),
      );

      Navigator.pop(context, correctedPlate);
    } catch (e) {
      debugPrint('ERROR SAVE OCR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );

      setState(() {
        _saving = false;
        _statusText = 'No se pudo guardar. Intenta nuevamente.';
        _errorMessage = 'Error guardando el escaneo.';
      }); 

      try {
        await controller.startImageStream(_processCameraImage);
      } catch (_) {}
    }
  }

  Future<void> _confirmPlate() async {
    if (_saving) return;

    final plate = _normalizeChileanPlate(_manualPlateController.text);

    if (plate.isEmpty) {
      setState(() {
        _errorMessage = 'Primero escanea o escribe una patente.';
      });
      return;
    }

    if (!_isValidChileanPlate(plate)) {
      setState(() {
        _errorMessage =
            'Formato inválido. Ejemplo nueva: ABCD12. Ejemplo antigua: AB1234.';
      });
      return;
    }

    await _saveScan(plate);
  }

  @override
  void dispose() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}

    _cameraController?.dispose();
    _textRecognizer.close();
    _manualPlateController.dispose();
    _scanAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: LiveScannerScreen.bgDark,
      body: _initializing
          ? const Center(
              child: CircularProgressIndicator(
                color: LiveScannerScreen.cyanGlow,
              ),
            )
          : !_cameraReady || controller == null || !controller.value.isInitialized
              ? _buildFatalError()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: CameraPreview(controller),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.70),
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LiveScannerOverlayPainter(),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          _buildTopBar(),
                          Expanded(child: _buildScannerArea()),
                          _buildBottomPanel(),
                        ],
                      ),
                    ),
                    if (_saving) _buildSavingOverlay(),
                  ],
                ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'SKANO PPU LIVE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'LECTOR DE PATENTES',
                  style: TextStyle(
                    color: Color(0xFF9FDBFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : _toggleFlash,
            icon: Icon(
              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: LiveScannerScreen.cyanGlow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scannerWidth = constraints.maxWidth * 0.82;
        const scannerHeight = 150.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 26,
              left: 20,
              right: 20,
              child: _buildStatusPill(),
            ),
            Container(
              width: scannerWidth,
              height: scannerHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: LiveScannerScreen.cyanGlow.withOpacity(0.92),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LiveScannerScreen.neonBlue.withOpacity(0.55),
                    blurRadius: 34,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScannerCornerPainter(),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 14 + ((scannerHeight - 28) * _scanAnimation.value),
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                LiveScannerScreen.cyanGlow,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LiveScannerScreen.cyanGlow.withOpacity(0.95),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Text(
                      _detectedPlate.isEmpty
                          ? 'ALINEA LA PATENTE AQUÍ'
                          : _detectedPlate,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _detectedPlate.isEmpty
                            ? Colors.white.withOpacity(0.55)
                            : Colors.white,
                        fontSize: _detectedPlate.isEmpty ? 14 : 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: _detectedPlate.isEmpty ? 1.2 : 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 22,
              left: 26,
              right: 26,
              child: Text(
                'No persigas vehículos. Usa SKANO PPU solo con vehículos detenidos o visibles de forma segura.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusPill() {
    final detected = _detectedPlate.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: detected
              ? Colors.greenAccent.withOpacity(0.45)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            detected
                ? Icons.check_circle_rounded
                : Icons.center_focus_strong_rounded,
            color: detected ? Colors.greenAccent : LiveScannerScreen.cyanGlow,
            size: 19,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: LiveScannerScreen.panelDark.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(
            color: LiveScannerScreen.neonBlue.withOpacity(0.28),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: LiveScannerScreen.neonBlue.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Confirmación de patente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Corrige la patente si el lector se equivoca. Este dato se guardará para mejorar SKANO PPU.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _manualPlateController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: 'ABCD12',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.20),
                fontWeight: FontWeight.w900,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.075),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: LiveScannerScreen.cyanGlow,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              final normalized = _normalizePlate(value);
              if (normalized != value) {
                _manualPlateController.value = TextEditingValue(
                  text: normalized,
                  selection: TextSelection.collapsed(
                    offset: normalized.length,
                  ),
                );
              }
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _confirmPlate,
              icon: const Icon(Icons.verified_rounded),
              label: Text(
                _saving ? 'Guardando...' : 'Confirmar y guardar',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LiveScannerScreen.neonBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: LiveScannerScreen.cyanGlow,
              ),
              SizedBox(height: 20),
              Text(
                'Guardando escaneo...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFatalError() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                size: 76,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'No pudimos abrir el lector',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Revisa los permisos de cámara.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LiveScannerScreen.neonBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final rectWidth = size.width * 0.82;
    const rectHeight = 150.0;

    final left = (size.width - rectWidth) / 2;
    final top = size.height * 0.32;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      const Radius.circular(24),
    );

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(scanRect, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = LiveScannerScreen.cyanGlow;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const corner = 28.0;

    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, corner), paint);

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - corner, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, corner),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(corner, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - corner),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - corner, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}