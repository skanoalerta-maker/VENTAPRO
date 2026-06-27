import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;

  File? idFront;
  File? idBack;
  File? addressProof;

  bool loading = false;

  Future<File?> pickImage() async {
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<String> uploadToStorage(File file, String name) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child("users/${user!.uid}/documents/$name");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveDocuments() async {
    if (idFront == null || idBack == null || addressProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes subir los 3 documentos obligatorios."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final idFrontUrl = await uploadToStorage(idFront!, "id_front.jpg");
      final idBackUrl = await uploadToStorage(idBack!, "id_back.jpg");
      final addressUrl =
          await uploadToStorage(addressProof!, "address_proof.jpg");

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({
        // 📄 DOCUMENTOS
        "idFrontUrl": idFrontUrl,
        "idBackUrl": idBackUrl,
        "addressProofUrl": addressUrl,

        // 🔑 FLAGS CLAVE DEL FLUJO
        "documentsCompleted": true,
        "reviewPending": true,
        "verification_status": "pending",
        "documentStatus": "pending_revision",
        "updated_at": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Documentos enviados para revisión"),
          backgroundColor: Colors.green,
        ),
      );

      // 👉 Volvemos al flujo principal (AuthGate)
      Navigator.pushReplacementNamed(context, "/review_pending");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al subir documentos: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Widget documentBox({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: neonBlue.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 1,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.upload_file, color: neonBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                file == null ? title : "$title (completo)",
                style: TextStyle(
                  color:
                      file == null ? Colors.white70 : Colors.greenAccent,
                  fontSize: 16,
                ),
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle,
                  color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Subir Documentos"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Verificación de identidad",
              style: TextStyle(
                color: neonBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Debes subir los siguientes documentos:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // 📄 DOCUMENTOS
            documentBox(
              title: "Frontal del documento",
              file: idFront,
              onTap: () async {
                final img = await pickImage();
                if (mounted) setState(() => idFront = img);
              },
            ),
            documentBox(
              title: "Reverso del documento",
              file: idBack,
              onTap: () async {
                final img = await pickImage();
                if (mounted) setState(() => idBack = img);
              },
            ),
            documentBox(
              title: "Comprobante de domicilio",
              file: addressProof,
              onTap: () async {
                final img = await pickImage();
                if (mounted) setState(() => addressProof = img);
              },
            ),

            const Spacer(),

            // ▶️ BOTÓN CONTINUAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : saveDocuments,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Continuar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
