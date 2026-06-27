import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PlateScannerScreen extends StatefulWidget {
  const PlateScannerScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cyanGlow = Color(0xFF00D4FF);
  static const Color bgDark = Color(0xFF020617);

  @override
  State<PlateScannerScreen> createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _camera;
  late final TextRecognizer _textRecognizer;
  late final AnimationController _laserController;

  bool _isLoading = true;
  bool _cameraReady = false;
  bool _isProcessingFrame = false;
  bool _streamStarted = false;
  bool _locked = false;

  String? _detectedPlate;
  String? _errorMessage;
  String _statusText = 'Inicializando lector SKANO...';

  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);

  final TextEditingController _manualPlateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró cámara disponible.';
          _statusText = 'Cámara no disponible';
        });
        return;
      }

      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _cameraReady = true;
        _isLoading = false;
        _statusText = 'Buscando patente en tiempo real...';
      });

      await _startLiveScanner();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo iniciar la cámara. Revisa los permisos.';
        _statusText = 'Error al iniciar cámara';
      });
    }
  }

  Future<void> _startLiveScanner() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _streamStarted) {
      return;
    }

    _streamStarted = true;

    await _cameraController!.startImageStream((CameraImage image) async {
      if (_locked || _isProcessingFrame) return;

      final now = DateTime.now();

      if (now.difference(_lastProcess).inMilliseconds < 700) return;

      _lastProcess = now;
      _isProcessingFrame = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) {
          _isProcessingFrame = false;
          return;
        }

        final recognizedText = await _textRecognizer.processImage(inputImage);
        final plate = _extractChilePlate(recognizedText.text);

        if (plate != null && mounted) {
          _locked = true;

          try {
            await _cameraController?.stopImageStream();
          } catch (_) {}

          _manualPlateController.text = plate;

          await HapticFeedback.mediumImpact();

          setState(() {
            _detectedPlate = plate;
            _statusText = 'Patente detectada. Confirma antes de verificar.';
            _errorMessage = null;
          });
        }
      } catch (_) {
        // No mostramos errores por cada frame para mantener una experiencia limpia.
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_camera == null) return null;

    final WriteBuffer allBytes = WriteBuffer();

    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    final rotation =
        InputImageRotationValue.fromRawValue(_camera!.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  String _normalizePlate(String value) {
    return value
        .toUpperCase()
        .replaceAll('CHILE', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('.', '')
        .replaceAll('·', '')
        .replaceAll(',', '')
        .replaceAll(':', '')
        .replaceAll(';', '')
        .replaceAll('|', '')
        .replaceAll('/', '')
        .replaceAll('\\', '')
        .replaceAll('_', '')
        .replaceAll('Ñ', 'N');
  }

  String? _extractChilePlate(String rawText) {
    final lines = rawText
        .toUpperCase()
        .split('\n')
        .map(_normalizePlate)
        .where((line) => line.length >= 5 && line.length <= 8)
        .toList();

    final patterns = [
      RegExp(r'^[A-Z]{4}[0-9]{2}$'), // LHFH98
      RegExp(r'^[A-Z]{2}[0-9]{4}$'), // AB1234
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        if (pattern.hasMatch(line)) {
          return line;
        }
      }
    }

    return null;
  }

  bool _isValidPlate(String plate) {
    final clean = _normalizePlate(plate);

    return RegExp(r'^[A-Z]{4}[0-9]{2}$').hasMatch(clean) ||
        RegExp(r'^[A-Z]{2}[0-9]{4}$').hasMatch(clean);
  }

  Future<void> _scanAgain() async {
    try {
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController?.stopImageStream();
      }
    } catch (_) {}

    _locked = false;
    _streamStarted = false;
    _detectedPlate = null;
    _manualPlateController.clear();

    setState(() {
      _statusText = 'Buscando patente en tiempo real...';
      _errorMessage = null;
    });

    await _startLiveScanner();
  }

  void _confirmPlate() {
    final plate = _normalizePlate(_manualPlateController.text);

    if (plate.isEmpty) {
      setState(() {
        _errorMessage = 'Primero escanea o escribe una patente.';
      });
      return;
    }

    if (!_isValidPlate(plate)) {
      setState(() {
        _errorMessage = 'Formato inválido. Ejemplo: LHFH98, ABCD12 o AB1234.';
      });
      return;
    }

    Navigator.pop(context, plate);
  }

  @override
  void dispose() {
    try {
      if (_cameraController?.value.isStreamingImages == true) {
        _cameraController?.stopImageStream();
      }
    } catch (_) {}

    _cameraController?.dispose();
    _textRecognizer.close();
    _manualPlateController.dispose();
    _laserController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlateScannerScreen.bgDark,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: PlateScannerScreen.neonBlue,
              ),
            )
          : _errorMessage != null && !_cameraReady
              ? _buildFatalError()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: _cameraReady && _cameraController != null
                          ? CameraPreview(_cameraController!)
                          : Container(color: Colors.black),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.72),
                              Colors.transparent,
                              Colors.black.withOpacity(0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          _topBar(),
                          Expanded(child: _scannerArea()),
                          _bottomPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Lector de patente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SKANO lectura en vivo',
                  style: TextStyle(
                    color: Color(0xFF9FDBFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _scannerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scannerWidth = constraints.maxWidth * 0.86;
        const scannerHeight = 138.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 26,
              left: 20,
              right: 20,
              child: _statusPill(),
            ),
            Container(
              width: scannerWidth,
              height: scannerHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: PlateScannerScreen.cyanGlow.withOpacity(0.92),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PlateScannerScreen.neonBlue.withOpacity(0.58),
                    blurRadius: 38,
                    spreadRadius: 5,
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
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: 16 + ((scannerHeight - 32) * _laserController.value),
                        left: 18,
                        right: 18,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                PlateScannerScreen.cyanGlow,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: PlateScannerScreen.cyanGlow
                                    .withOpacity(0.95),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Text(
                      _detectedPlate ?? 'ALINEA LA PATENTE AQUÍ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _detectedPlate == null
                            ? Colors.white.withOpacity(0.55)
                            : Colors.white,
                        fontSize: _detectedPlate == null ? 14 : 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: _detectedPlate == null ? 1.2 : 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Text(
                'Mantén el teléfono firme. No persigas vehículos. Confirma visualmente antes de continuar.',
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

  Widget _statusPill() {
    final detected = _detectedPlate != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: detected
              ? Colors.greenAccent.withOpacity(0.48)
              : Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            detected
                ? Icons.check_circle_rounded
                : Icons.center_focus_strong_rounded,
            color: detected ? Colors.greenAccent : PlateScannerScreen.cyanGlow,
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

  Widget _bottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF05070B).withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(
            color: PlateScannerScreen.neonBlue.withOpacity(0.30),
          ),
        ),
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
            'Si el lector se equivoca, corrige manualmente antes de verificar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 13,
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
              hintText: 'LHFH98',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.22),
                fontWeight: FontWeight.w900,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.075),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
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
                  color: PlateScannerScreen.cyanGlow,
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
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_detectedPlate == null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlateScannerScreen.neonBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _statusText = 'Buscando patente en tiempo real...';
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.document_scanner_rounded),
                label: const Text(
                  'Escaneo automático activo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PlateScannerScreen.neonBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                onPressed: _scanAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Escanear nuevamente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: _confirmPlate,
              icon: const Icon(Icons.verified_rounded),
              label: const Text(
                'Confirmar patente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
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
                    backgroundColor: PlateScannerScreen.neonBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al ingreso manual'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PlateScannerScreen.cyanGlow
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const corner = 30.0;

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