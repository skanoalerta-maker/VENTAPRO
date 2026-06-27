import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

  File? newImage;

  // Controllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final rutCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final accountTypeCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();

  String profilePicUrl = "";
  bool saving = false;

  late AnimationController fadeController;
  late Animation<double> fadeIn;

  @override
  void initState() {
    super.initState();
    loadUserData();

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    fadeIn = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);
    fadeController.forward();
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data() ?? {};

    setState(() {
      nameCtrl.text = data["full_name"] ?? "";
      phoneCtrl.text = data["phone"] ?? "";
      rutCtrl.text = data["nationalId"] ?? "";
      bankNameCtrl.text = data["bank_name"] ?? "";
      accountTypeCtrl.text = data["account_type"] ?? "";
      accountNumberCtrl.text = data["account_number"] ?? "";
      profilePicUrl = data["profile_pic"] ?? "";
    });
  }

  // TOMAR IMAGEN
  Future<void> pickImage() async {
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked != null) {
      setState(() {
        newImage = File(picked.path);
      });
    }
  }

  // GUARDAR CAMBIOS
  Future<void> saveChanges() async {
    setState(() => saving = true);

    // SUBIR FOTO SI HAY NUEVA
    String imageUrl = profilePicUrl;

    if (newImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profiles/${user!.uid}.jpg");

      await ref.putFile(newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    // GUARDAR EN FIRESTORE
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({
      "full_name": nameCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "nationalId": rutCtrl.text.trim(),
      "bank_name": bankNameCtrl.text.trim(),
      "account_type": accountTypeCtrl.text.trim(),
      "account_number": accountNumberCtrl.text.trim(),
      "profile_pic": imageUrl,
      "updated_at": FieldValue.serverTimestamp(),
    });

    setState(() => saving = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Editar Perfil", style: TextStyle(color: Colors.white)),
      ),

      body: FadeTransition(
        opacity: fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // FOTO DE PERFIL
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: newImage != null
                        ? FileImage(newImage!)
                        : (profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : null),
                    child: (profilePicUrl.isEmpty && newImage == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.white54)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _input("Nombre Completo", nameCtrl),
              const SizedBox(height: 15),

              _input("Teléfono", phoneCtrl, type: TextInputType.phone),
              const SizedBox(height: 15),

              _input("RUT", rutCtrl),
              const SizedBox(height: 25),

              // CUENTA BANCARIA
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Cuenta Bancaria",
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              _input("Banco", bankNameCtrl),
              const SizedBox(height: 15),

              _input("Tipo de Cuenta", accountTypeCtrl),
              const SizedBox(height: 15),

              _input("Número de Cuenta", accountNumberCtrl,
                  type: TextInputType.number),

              const SizedBox(height: 40),

              // BOTÓN GUARDAR
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
                  onPressed: saving ? null : saveChanges,
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Guardar Cambios",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // INPUT PREMIUM
  Widget _input(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
