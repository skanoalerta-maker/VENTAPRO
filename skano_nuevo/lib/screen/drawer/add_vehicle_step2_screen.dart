import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_vehicle_step3_screen.dart';

class AddVehicleStep2Screen extends StatefulWidget {
  final String plate;
  final String brand;
  final String model;
  final String year;
  final String color;
  final String type;

  const AddVehicleStep2Screen({
    super.key,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
  });

  @override
  State<AddVehicleStep2Screen> createState() => _AddVehicleStep2ScreenState();
}

class _AddVehicleStep2ScreenState extends State<AddVehicleStep2Screen> {
  final ImagePicker _picker = ImagePicker();

  File? padron;
  File? permiso;
  File? vehiclePhoto;
  File? policeReport;

  // 🆕 Fotos visibles para validación ciudadana
  File? vehicleFront;
  File? vehicleBack;

  bool _checkingMembership = false;

  // =====================================================
  // 📷 SELECCIONAR IMAGEN (CÁMARA O GALERÍA)
  // =====================================================
  Future<void> _pickImage(Function(File) onSelected) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                "Tomar foto",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                "Elegir de galería",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() => onSelected(File(picked.path)));
    }
  }

  bool get _canContinue =>
      padron != null &&
      permiso != null &&
      vehiclePhoto != null &&
      policeReport != null &&
      vehicleFront != null &&
      vehicleBack != null;

  Future<void> _continue() async {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes subir todos los documentos y fotos obligatorias"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesión inválida. Inicia sesión nuevamente."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _checkingMembership = true);

      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final hasMembership = data["membership_active"] == true;

      if (!mounted) return;

      // 🚨 NO TIENE MEMBRESÍA → IR A PAGO
      if (!hasMembership) {
        setState(() => _checkingMembership = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes activar tu membresía para continuar"),
            backgroundColor: Colors.orangeAccent,
          ),
        );

        await Navigator.pushNamed(context, "/my_membership");
        return;
      }

      setState(() => _checkingMembership = false);

      // ✅ TIENE MEMBRESÍA → CONTINÚA
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddVehicleStep3Screen(
            plate: widget.plate,
            brand: widget.brand,
            model: widget.model,
            year: widget.year,
            color: widget.color,
            type: widget.type,
            vehicleDocs: {
              "vehicle_photo_file": vehiclePhoto!,
              "padron_file": padron!,
              "permiso_file": permiso!,
              "police_report_file": policeReport!,
              "vehicle_front_file": vehicleFront!,
              "vehicle_back_file": vehicleBack!,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _checkingMembership = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al validar la membresía: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Agregar vehículo (2/4)",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Documentos del vehículo",
              style: TextStyle(
                color: neon,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Todos los documentos y fotos son obligatorios.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),

            _docTile(
              title: "Padrón del vehículo *",
              subtitle: "Documento oficial",
              file: padron,
              onTap: () => _pickImage((f) => padron = f),
            ),
            _docTile(
              title: "Permiso de circulación *",
              subtitle: "Último permiso vigente",
              file: permiso,
              onTap: () => _pickImage((f) => permiso = f),
            ),
            _docTile(
              title: "Foto general del vehículo *",
              subtitle: "Vehículo completo",
              file: vehiclePhoto,
              onTap: () => _pickImage((f) => vehiclePhoto = f),
            ),
            _docTile(
              title: "Parte de Carabineros *",
              subtitle: "Denuncia oficial",
              file: policeReport,
              onTap: () => _pickImage((f) => policeReport = f),
              highlight: true,
            ),

            const SizedBox(height: 24),

            const Text(
              "Fotos visibles para validación",
              style: TextStyle(
                color: neon,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Estas fotos serán visibles para los usuarios que reporten el vehículo, "
              "permitiendo confirmar que corresponde al mismo.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),

            _docTile(
              title: "Foto frontal del vehículo *",
              subtitle: "Debe verse claramente el frontal",
              file: vehicleFront,
              onTap: () => _pickImage((f) => vehicleFront = f),
            ),
            _docTile(
              title: "Foto trasera del vehículo *",
              subtitle: "Debe verse claramente la parte trasera",
              file: vehicleBack,
              onTap: () => _pickImage((f) => vehicleBack = f),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkingMembership ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _checkingMembership
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Continuar a membresía (3/4)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    const neon = Color(0xFF0A6CFF);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? Colors.redAccent
                  : file != null
                      ? neon
                      : neon.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                file != null ? Icons.check_circle : Icons.upload_file,
                color: file != null
                    ? Colors.greenAccent
                    : highlight
                        ? Colors.redAccent
                        : neon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}