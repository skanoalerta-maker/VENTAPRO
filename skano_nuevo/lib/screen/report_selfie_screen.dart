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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo iniciar la cámara: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo tomar la selfie: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        "report_selfies/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;

      final updatedDraft = {
        ...?widget.reportDraft,
        "reporterUid": user.uid,
        "reporterEmail": user.email ?? "",
        "reportSelfieUrl": url,
        "reportSelfieTakenAt": DateTime.now().toIso8601String(),
      };

      Navigator.pushReplacementNamed(
        context,
        widget.nextRoute,
        arguments: updatedDraft,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo subir la selfie: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Selfie de reporte"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _loadingCamera
          ? const Center(
              child: CircularProgressIndicator(color: neonBlue),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Antes de continuar, toma una selfie actual para asociar este reporte a tu cuenta.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _capturedFile != null
                            ? Image.file(
                                File(_capturedFile!.path),
                                fit: BoxFit.cover,
                              )
                            : (_controller != null &&
                                    _controller!.value.isInitialized)
                                ? CameraPreview(_controller!)
                                : const Center(
                                    child: Text(
                                      "Cámara no disponible",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_capturedFile == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _takePhoto,
                        child: const Text(
                          "Tomar selfie",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: _processing ? null : _retakePhoto,
                            child: const Text("Repetir"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonBlue,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed:
                                _processing ? null : _confirmAndContinue,
                            child: Text(
                              _processing ? "Subiendo..." : "Continuar",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}