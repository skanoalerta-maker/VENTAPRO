import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportSelfieScreen extends StatefulWidget {
  final String nextRoute;
  final Map<String, dynamic>? reportDraft;

  const ReportSelfieScreen({
    super.key,
    required this.nextRoute,
    this.reportDraft,
  });

  @override
  State<ReportSelfieScreen> createState() => _ReportSelfieScreenState();
}

class _ReportSelfieScreenState extends State<ReportSelfieScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color skanoCyan = Color(0xFF00D5FF);
  static const Color skanoGreen = Color(0xFF00E5A0);
  static const Color bgBlack = Color(0xFF030712);
  static const Color cardDark = Color(0xFF0B1220);

  CameraController? _controller;
  bool _loadingCamera = true;
  bool _processing = false;
  XFile? _capturedFile;

  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _loadingCamera = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCamera = false);
      _snack('No se pudo iniciar la cámara: $e', isError: true);
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_processing) return;

    try {
      final file = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _capturedFile = file);
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudo tomar la selfie: $e', isError: true);
    }
  }

  Future<void> _retakePhoto() async {
    if (!mounted) return;
    setState(() => _capturedFile = null);
  }

  Future<void> _confirmAndContinue() async {
    if (_capturedFile == null || _processing) return;

    setState(() => _processing = true);

    try {
      final file = File(_capturedFile!.path);

      final ref = FirebaseStorage.instance.ref(
        'report_selfies/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;

      final updatedDraft = {
        ...?widget.reportDraft,
        'reporterUid': user.uid,
        'reporterEmail': user.email ?? '',
        'reportSelfieUrl': url,
        'reportSelfieTakenAt': DateTime.now().toIso8601String(),
      };

      Navigator.pushReplacementNamed(
        context,
        widget.nextRoute,
        arguments: updatedDraft,
      );
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudo subir la selfie: $e', isError: true);
      setState(() => _processing = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1F2937),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: neonBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: skanoCyan, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta selfie se usa solo para asociar el reporte a tu cuenta y reforzar la seguridad del protocolo.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraFrame() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _capturedFile == null
                ? neonBlue.withOpacity(0.55)
                : skanoGreen.withOpacity(0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_capturedFile != null)
                Image.file(
                  File(_capturedFile!.path),
                  fit: BoxFit.cover,
                )
              else if (_controller != null && _controller!.value.isInitialized)
                CameraPreview(_controller!)
              else
                const Center(
                  child: Text(
                    'Cámara no disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.18),
                          Colors.transparent,
                          Colors.black.withOpacity(0.28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _capturedFile == null
                            ? Icons.face_retouching_natural_rounded
                            : Icons.check_circle_rounded,
                        color: _capturedFile == null ? skanoCyan : skanoGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capturedFile == null
                              ? 'Ubica tu rostro al centro'
                              : 'Selfie capturada correctamente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_capturedFile == null)
                Center(
                  child: Container(
                    width: 220,
                    height: 290,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      border: Border.all(
                        color: skanoCyan.withOpacity(0.75),
                        width: 2,
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

  Widget _mainButton() {
    if (_capturedFile == null) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonBlue,
            foregroundColor: Colors.white,
            elevation: 10,
            shadowColor: neonBlue.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text(
            'TOMAR SELFIE',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _processing ? null : _retakePhoto,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'REPETIR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: skanoGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _processing ? null : _confirmAndContinue,
            icon: _processing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.6,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              _processing ? 'SUBIENDO...' : 'CONTINUAR',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SKANO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Selfie de seguridad del reporte',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: _loadingCamera
          ? const Center(
              child: CircularProgressIndicator(color: neonBlue),
            )
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgBlack,
                    Color(0xFF050816),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                  child: Column(
                    children: [
                      const Text(
                        'Confirma tu identidad antes de continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toma una selfie actual para asociar este reporte a tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoBox(),
                      const SizedBox(height: 16),
                      _cameraFrame(),
                      const SizedBox(height: 18),
                      _mainButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}