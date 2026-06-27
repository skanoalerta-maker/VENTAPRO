import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({super.key});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final picker = ImagePicker();
  File? newImage;

  final plateCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  String status = "active";
  String? vehicleId;
  String oldImageUrl = "";

  bool saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final data = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    vehicleId = data["vehicle_id"];

    plateCtrl.text = data["plate"];
    brandCtrl.text = data["brand"];
    modelCtrl.text = data["model"];
    yearCtrl.text = data["year"].toString();
    colorCtrl.text = data["color"];
    typeCtrl.text = data["tipo"];
    status = data["status"];
    oldImageUrl = data["photo_url"];
  }

  // TOMAR O CAMBIAR FOTO
  Future<void> pickNewImage() async {
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (file != null) {
      setState(() => newImage = File(file.path));
    }
  }

  // GUARDAR CAMBIOS
  Future<void> saveChanges() async {
    setState(() => saving = true);

    String imageUrl = oldImageUrl;

    // SI SUBE UNA NUEVA FOTO
    if (newImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("vehicles")
          .child("$vehicleId.jpg");

      await ref.putFile(newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    // GUARDAR CAMBIOS EN FIRESTORE
    await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(vehicleId)
        .update({
      "plate": plateCtrl.text.trim().toUpperCase(),
      "brand": brandCtrl.text.trim(),
      "model": modelCtrl.text.trim(),
      "year": int.parse(yearCtrl.text),
      "color": colorCtrl.text.trim(),
      "tipo": typeCtrl.text.trim(),
      "status": status,
      "photo_url": imageUrl,
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
        title: const Text("Editar Vehículo", style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // FOTO ACTUAL O NUEVA
            GestureDetector(
              onTap: pickNewImage,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: neonBlue, width: 2),
                ),
                child: newImage == null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          oldImageUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(newImage!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            _input("Patente", plateCtrl),
            const SizedBox(height: 15),

            _input("Marca", brandCtrl),
            const SizedBox(height: 15),

            _input("Modelo", modelCtrl),
            const SizedBox(height: 15),

            _input("Año", yearCtrl, type: TextInputType.number),
            const SizedBox(height: 15),

            _input("Color", colorCtrl),
            const SizedBox(height: 15),

            _input("Tipo (auto/camioneta/moto)", typeCtrl),
            const SizedBox(height: 30),

            // ESTADO DEL VEHÍCULO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusButton("Activo", "active", neonBlue),
                _statusButton("Robado", "stolen", Colors.redAccent),
                _statusButton("Recuperado", "recovered", Colors.greenAccent),
              ],
            ),

            const SizedBox(height: 35),

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
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INPUT PRO
  Widget _input(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
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

  // BOTONES DE ESTADO
  Widget _statusButton(String text, String value, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => status = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: status == value ? color.withOpacity(0.3) : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: status == value ? color : Colors.white30,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                  color: status == value ? color : Colors.white70,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
