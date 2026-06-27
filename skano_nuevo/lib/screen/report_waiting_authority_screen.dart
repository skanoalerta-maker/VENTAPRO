import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ReportWaitingAuthorityScreen extends StatefulWidget {
  final String reportId;

  const ReportWaitingAuthorityScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportWaitingAuthorityScreen> createState() =>
      _ReportWaitingAuthorityScreenState();
}

class _ReportWaitingAuthorityScreenState
    extends State<ReportWaitingAuthorityScreen> {
  File? finalPhoto;
  bool sending = false;

  final picker = ImagePicker();

  // ================= FOTO FINAL =================
  Future<void> _takeFinalPhoto() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 70,
    );

    if (file != null) {
      setState(() => finalPhoto = File(file.path));
    }
  }

  // ================= CERRAR REPORTE =================
  Future<void> _closeReport() async {
    if (finalPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Para cerrar el reporte debes tomar una foto que confirme "
            "que la autoridad tiene el vehículo.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => sending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 📸 SUBIR FOTO FINAL A STORAGE
      final ref = FirebaseStorage.instance.ref(
        "reports/${widget.reportId}/authority_${DateTime.now().millisecondsSinceEpoch}${path.extension(finalPhoto!.path)}",
      );

      await ref.putFile(finalPhoto!);
      final finalPhotoUrl = await ref.getDownloadURL();

      // 🔒 ACTUALIZAR REPORTE
      await FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId)
          .update({
        "status": "closed",
        "authority_confirmed": true,
        "final_photo_url": finalPhotoUrl,
        "closed_by": uid,
        "closed_at": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ✅ CONFIRMACIÓN FINAL
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Text(
            "Reporte cerrado",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Gracias por tu ayuda.\n\n"
            "El reporte fue cerrado correctamente tras la "
            "confirmación de la autoridad competente.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("/home", (_) => false);
              },
              child: const Text("Finalizar"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cerrar reporte: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text("Reporte en observación"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.visibility, size: 64, color: neonBlue),
            const SizedBox(height: 20),

            const Text(
              "Reporte en observación",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Tu reporte fue enviado correctamente.\n\n"
              "Tu seguridad es lo más importante. "
              "No enfrentes a terceros ni intentes recuperar el vehículo.\n\n"
              "SKANO no contacta autoridades ni servicios de emergencia.\n"
              "Si la autoridad competente toma el vehículo bajo su control, "
              "puedes confirmarlo para cerrar el reporte.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            // 📸 FOTO FINAL
            GestureDetector(
              onTap: _takeFinalPhoto,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: neonBlue),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white10,
                ),
                child: finalPhoto == null
                    ? const Center(
                        child: Icon(Icons.camera_alt,
                            size: 60, color: Colors.white38),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(finalPhoto!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Solo toma esta foto si la autoridad competente "
              "tiene el vehículo bajo su control.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonBlue,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: sending ? null : _closeReport,
              child: sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "LA AUTORIDAD TOMÓ EL VEHÍCULO",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("/home", (_) => false);
              },
              child: const Text(
                "Salir sin cerrar el reporte",
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
