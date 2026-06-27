import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';

class SelfieRegisterScreen extends StatefulWidget {
  const SelfieRegisterScreen({super.key});

  @override
  State<SelfieRegisterScreen> createState() => _SelfieRegisterScreenState();
}

class _SelfieRegisterScreenState extends State<SelfieRegisterScreen> {
  static const Color bgDark = Color(0xFF030712);
  static const Color cardDark = Color(0xFF0B1220);
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF00D5FF);
  static const Color green = Color(0xFF00E5A0);

  CameraController? _camera;
  CameraDescription? _cameraDesc;

  bool cameraActive = false;
  bool loadingCamera = false;
  bool saving = false;
  bool _disposingCamera = false;

  File? selfieFile;

  String pin1 = "";
  String pin2 = "";
  bool showPin = false;

  bool get _pinValid =>
      pin1.length == 6 && pin1 == pin2 && selfieFile != null && !saving;

  Future<void> _openCamera() async {
    if (loadingCamera || _disposingCamera) return;

    setState(() => loadingCamera = true);

    try {
      final cameras = await availableCameras();

      _cameraDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _cameraDesc!,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _camera = controller;

      await controller.initialize();

      if (!mounted || _camera != controller) {
        await controller.dispose();
        return;
      }

      setState(() {
        cameraActive = true;
        loadingCamera = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingCamera = false;
        cameraActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No se pudo abrir la cámara: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _closeCamera() async {
    final camera = _camera;

    if (camera == null || _disposingCamera) return;

    _disposingCamera = true;
    _camera = null;

    if (mounted) {
      setState(() {
        cameraActive = false;
        loadingCamera = false;
      });
    }

    try {
      await camera.dispose();
    } catch (e) {
      debugPrint("CAMERA DISPOSE ERROR: $e");
    }

    _disposingCamera = false;
  }

  Future<void> _takePhoto() async {
    final camera = _camera;

    if (camera == null || !camera.value.isInitialized || _disposingCamera) {
      return;
    }

    try {
      final file = await camera.takePicture();

      if (!mounted) return;

      selfieFile = File(file.path);

      await _closeCamera();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No se pudo capturar la foto: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_pinValid) return;

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'identity_photos/$fileName';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      await ref.putFile(selfieFile!);
      final url = await ref.getDownloadURL();

      final pinHash = sha256.convert(utf8.encode(pin1)).toString();

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};

      final bool docsDone = userData["documentsCompleted"] == true ||
          ((userData["idFrontUrl"] ?? "").toString().isNotEmpty &&
              (userData["idBackUrl"] ?? "").toString().isNotEmpty &&
              (userData["addressProofUrl"] ?? "").toString().isNotEmpty);

      await userRef.set({
        "faceUrl": url,
        "identity_photo_url": url,
        "identityPhotoUrl": url,
        "identity_photo_path": storagePath,
        "faceRegistered": true,
        "faceVerificationLevel": 2,
        "lastFaceCheck": FieldValue.serverTimestamp(),
        "report_pin_hash": pinHash,
        "pin_created_at": FieldValue.serverTimestamp(),
        "verification_status": "pending",
        "reviewPending": true,
        "documentStatus": docsDone ? "pending" : "draft",
        "documentsCompleted": docsDone,
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Selfie y PIN registrados correctamente."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/my_account');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Firebase: ${e.code} — ${e.message}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    final camera = _camera;
    _camera = null;

    try {
      camera?.dispose();
    } catch (e) {
      debugPrint("CAMERA DISPOSE ERROR: $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraActive && _camera != null) {
      return _cameraView();
    }

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SKANO",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              "Verificación de identidad",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _backgroundGlow(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        _instructionsCard(),
                        const SizedBox(height: 16),
                        _cameraCard(),
                        const SizedBox(height: 16),
                        _pinCard(),
                        const SizedBox(height: 22),
                        _continueButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (saving) _loadingOverlay("Guardando verificación..."),
        ],
      ),
    );
  }

  Widget _cameraView() {
    final camera = _camera;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (camera != null && camera.value.isInitialized)
            Positioned.fill(child: CameraPreview(camera)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.70),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _disposingCamera ? null : _closeCamera,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                      const Expanded(
                        child: Text(
                          "Selfie de verificación",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cyan.withOpacity(0.45)),
                    ),
                    child: const Text(
                      "Mira directamente a la cámara. Asegúrate de tener buena iluminación y el rostro completamente visible.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _disposingCamera ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        "CAPTURAR SELFIE",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.25,
          colors: [
            Color(0xFF10275A),
            Color(0xFF07111F),
            Color(0xFF030712),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            neonBlue.withOpacity(0.28),
            Colors.black.withOpacity(0.38),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonBlue.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: cyan, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "Protegemos la comunidad verificando que cada cuenta corresponda a una persona real.",
              style: TextStyle(
                color: Colors.white,
                height: 1.35,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.face_retouching_natural_rounded,
            title: "Indicaciones para la selfie",
          ),
          SizedBox(height: 12),
          _CheckText("Rostro completamente visible"),
          _CheckText("Sin lentes de sol ni gorra"),
          _CheckText("Mira directamente a la cámara"),
          _CheckText("Usa buena iluminación"),
        ],
      ),
    );
  }

  Widget _cameraCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.camera_front_rounded,
            title: "Foto de identidad",
          ),
          const SizedBox(height: 14),
          if (selfieFile != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: green.withOpacity(0.42)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Selfie capturada correctamente",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon: loadingCamera
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.camera_front_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: loadingCamera ? null : _openCamera,
              label: Text(
                loadingCamera ? "Abriendo cámara..." : "Tomar selfie",
                style: const TextStyle(
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

  Widget _pinCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.lock_rounded,
            title: "PIN de seguridad",
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            obscureText: !showPin,
            style: const TextStyle(color: Colors.white),
            decoration: _pinDecoration("PIN de 6 dígitos"),
            onChanged: (v) => setState(() => pin1 = v.trim()),
          ),
          const SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            obscureText: !showPin,
            style: const TextStyle(color: Colors.white),
            decoration: _pinDecoration("Repite tu PIN"),
            onChanged: (v) => setState(() => pin2 = v.trim()),
            onSubmitted: (_) {
              if (_pinValid) _submit();
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => showPin = !showPin),
              icon: Icon(
                showPin ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                showPin ? "Ocultar PIN" : "Mostrar PIN",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _pinValid ? neonBlue : const Color(0xFF263244),
          foregroundColor: _pinValid ? Colors.white : Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _pinValid ? _submit : null,
        child: saving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "CONTINUAR",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _loadingOverlay(String text) {
    return Container(
      color: Colors.black.withOpacity(0.74),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: neonBlue.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: cyan),
              const SizedBox(height: 18),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _pinDecoration(String hint) {
    return InputDecoration(
      counterText: "",
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.black.withOpacity(0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cyan, width: 1.4),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _SelfieRegisterScreenState.cyan, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckText extends StatelessWidget {
  final String text;

  const _CheckText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}