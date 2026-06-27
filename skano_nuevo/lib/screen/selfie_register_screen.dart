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
  CameraController? _camera;
  CameraDescription? _cameraDesc;

  bool cameraActive = false;
  bool loadingCamera = false;
  bool saving = false;

  File? selfieFile;

  String pin1 = "";
  String pin2 = "";
  bool showPin = false;

  // ================= CAMERA =================
  Future<void> _openCamera() async {
    setState(() => loadingCamera = true);

    try {
      final cameras = await availableCameras();
      _cameraDesc = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _camera = CameraController(
        _cameraDesc!,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _camera!.initialize();

      if (!mounted) return;

      setState(() {
        cameraActive = true;
        loadingCamera = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingCamera = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No se pudo abrir la cámara: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (_camera == null) return;

    try {
      final file = await _camera!.takePicture();
      selfieFile = File(file.path);

      await _camera!.dispose();
      _camera = null;

      if (!mounted) return;

      setState(() {
        cameraActive = false;
      });
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

  // ================= VALIDACIÓN =================
  bool get _pinValid =>
      pin1.length == 6 &&
      pin1 == pin2 &&
      selfieFile != null &&
      !saving;

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_pinValid) return;

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuario no autenticado");
      }

      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'identity_photos/$fileName';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      await ref.putFile(selfieFile!);
      final url = await ref.getDownloadURL();

      final pinHash = sha256.convert(utf8.encode(pin1)).toString();

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};

      final bool docsDone =
          userData["documentsCompleted"] == true ||
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

        // ✅ CIERRE DE FLUJO HACIA REVISIÓN
        "verification_status": "pending",
        "reviewPending": true,

        // ✅ Mantiene coherencia con documentos ya cargados
        "documentsCompleted": docsDone,

        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Selfie y PIN registrados. Tu cuenta quedó en revisión."),
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Verificación de identidad"),
      ),
      body: Stack(
        children: [
          if (cameraActive && _camera != null)
            CameraPreview(_camera!)
          else
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              "SKANO",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: neonBlue,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Para proteger a la comunidad SKANO,\n"
                              "necesitamos confirmar que eres una persona real.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Indicaciones para la foto:\n"
                              "• Rostro completamente visible\n"
                              "• Sin lentes de sol ni gorra\n"
                              "• Mira directamente a la cámara\n"
                              "• Buena iluminación",
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.camera_front),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: neonBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: loadingCamera ? null : _openCamera,
                                label: Text(
                                  loadingCamera
                                      ? "Abriendo cámara..."
                                      : "Tomar foto de mi rostro",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (selfieFile != null) ...[
                              const SizedBox(height: 12),
                              const Text(
                                "✅ Foto capturada correctamente",
                                style: TextStyle(color: Colors.greenAccent),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 28),
                            TextField(
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              maxLength: 6,
                              obscureText: !showPin,
                              decoration: _pinDecoration("PIN de 6 dígitos"),
                              onChanged: (v) => setState(() => pin1 = v.trim()),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              obscureText: !showPin,
                              decoration: _pinDecoration("Repite tu PIN"),
                              onChanged: (v) => setState(() => pin2 = v.trim()),
                              onSubmitted: (_) {
                                if (_pinValid) _submit();
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => showPin = !showPin),
                                child: Text(
                                  showPin ? "Ocultar PIN" : "Mostrar PIN",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _pinValid ? neonBlue : Colors.grey,
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
                                        "Continuar",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (cameraActive)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _takePhoto,
                  child: const Text(
                    "Capturar foto",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _pinDecoration(String hint) {
    return InputDecoration(
      counterText: "",
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.black54,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0A6CFF), width: 1.4),
      ),
    );
  }
}