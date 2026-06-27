import 'dart:async';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PlateScannerScreen extends StatefulWidget {
  const PlateScannerScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cyanGlow = Color(0xFF00D4FF);
  static const Color dangerRed = Color(0xFFFF2D55);
  static const Color bgDark = Color(0xFF020617);

  @override
  State<PlateScannerScreen> createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;
  late final AnimationController _scanAnimationController;
  late final Animation<double> _scanAnimation;

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _cameraReady = false;

  String? _detectedPlate;
  String? _errorMessage;
  String _statusText = 'Inicializando lector SKANO...';

  final TextEditingController _manualPlateController = TextEditingController();

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

  Future<void> _registerPlateSearch() async {
    final now = DateTime.now();

    final todayId =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection("stats_daily").doc(todayId).set(
      {
        "plate_searches": FieldValue.increment(1),
        "updated_at": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontró cámara disponible.';
          _statusText = 'Cámara no disponible';
          _isLoading = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _cameraReady = true;
        _isLoading = false;
        _statusText = 'Apunta la cámara hacia la patente';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo iniciar la cámara. Revisa los permisos.';
        _statusText = 'Error al iniciar cámara';
        _isLoading = false;
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
        .replaceAll('Ñ', 'N');
  }

  String? _extractChilePlate(String rawText) {
    final clean = _normalizePlate(rawText);

    final newPlateRegex = RegExp(r'[A-Z]{4}[0-9]{2}');
    final oldPlateRegex = RegExp(r'[A-Z]{2}[0-9]{4}');

    final newMatch = newPlateRegex.firstMatch(clean);
    if (newMatch != null) return newMatch.group(0);

    final oldMatch = oldPlateRegex.firstMatch(clean);
    if (oldMatch != null) return oldMatch.group(0);

    return null;
  }

  bool _isValidPlate(String plate) {
    final validNew = RegExp(r'^[A-Z]{4}[0-9]{2}$').hasMatch(plate);
    final validOld = RegExp(r'^[A-Z]{2}[0-9]{4}$').hasMatch(plate);
    return validNew || validOld;
  }

  Future<void> _scanPlate() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;
      _detectedPlate = null;
      _errorMessage = null;
      _statusText = 'Analizando patente...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final plate = _extractChilePlate(recognizedText.text);

      if (!mounted) return;

      if (plate == null) {
        setState(() {
          _statusText = 'No se detectó una patente clara';
          _errorMessage =
              'Acércate un poco, enfoca la patente dentro del marco o escríbela manualmente.';
          _isProcessing = false;
        });
        return;
      }

      _manualPlateController.text = plate;

      setState(() {
        _detectedPlate = plate;
        _statusText = 'Patente detectada. Confirma antes de verificar.';
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _statusText = 'Error al leer patente';
        _errorMessage = 'No pudimos procesar la imagen. Intenta nuevamente.';
        _isProcessing = false;
      });
    }
  }

  Future<void> _confirmPlate() async {
    final plate = _normalizePlate(_manualPlateController.text);

    if (plate.isEmpty) {
      setState(() {
        _errorMessage = 'Primero escanea o escribe una patente.';
      });
      return;
    }

    if (!_isValidPlate(plate)) {
      setState(() {
        _errorMessage =
            'Formato inválido. Ejemplo patente nueva: ABCD12. Ejemplo antigua: AB1234.';
      });
      return;
    }

    try {
      await _registerPlateSearch();

      if (!mounted) return;
      Navigator.pop(context, plate);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo registrar la revisión. Intenta nuevamente.';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _manualPlateController.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = PlateScannerScreen.neonBlue;

    return Scaffold(
      backgroundColor: PlateScannerScreen.bgDark,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: neonBlue),
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
                              Colors.black.withOpacity(0.70),
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.82),
                            ],
                          ),
                        ),
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Lector de patente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SKANO OCR básico',
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
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScannerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scannerWidth = constraints.maxWidth * 0.82;
        const scannerHeight = 132.0;

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
                  color: PlateScannerScreen.cyanGlow.withOpacity(0.92),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PlateScannerScreen.neonBlue.withOpacity(0.55),
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
                                PlateScannerScreen.cyanGlow,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: PlateScannerScreen.cyanGlow
                                    .withOpacity(0.95),
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
                      _detectedPlate ?? 'ALINEA LA PATENTE AQUÍ',
                      style: TextStyle(
                        color: _detectedPlate == null
                            ? Colors.white.withOpacity(0.55)
                            : Colors.white,
                        fontSize: _detectedPlate == null ? 14 : 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: _detectedPlate == null ? 1.2 : 3,
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
                'No persigas vehículos. Verifica visualmente la patente antes de continuar.',
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
    final bool detected = _detectedPlate != null;

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

  Widget _buildBottomPanel() {
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
            color: PlateScannerScreen.neonBlue.withOpacity(0.28),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: PlateScannerScreen.neonBlue.withOpacity(0.18),
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
            'Puedes corregirla manualmente si el lector se equivoca.',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: PlateScannerScreen.neonBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: _isProcessing ? null : _scanPlate,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.document_scanner_rounded),
              label: Text(
                _isProcessing ? 'Leyendo patente...' : 'Leer patente',
                style: const TextStyle(
                  fontSize: 16.5,
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
                  color: Colors.white.withOpacity(0.24),
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
                  fontSize: 16.5,
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
                    backgroundColor: PlateScannerScreen.neonBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver al ingreso manual',
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

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = PlateScannerScreen.cyanGlow;

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