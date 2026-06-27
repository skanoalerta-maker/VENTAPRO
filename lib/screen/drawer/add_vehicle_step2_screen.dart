import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_vehicle_step3_screen.dart';

class AddVehicleStep2Screen extends StatefulWidget {
  static const Color neon = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF00D5FF);
  static const Color bg = Color(0xFF020617);
  static const Color card = Color(0xFF0B1220);
  static const Color green = Color(0xFF14F195);
  static const Color red = Color(0xFFFF4D5E);

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
  File? vehicleFront;
  File? vehicleBack;

  bool _checkingMembership = false;

  Future<void> _pickImage(Function(File) onSelected) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Subir documento o foto",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                title: "Tomar foto",
                subtitle: "Usar cámara del dispositivo",
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                title: "Elegir de galería",
                subtitle: "Seleccionar una imagen existente",
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
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

  int get _uploadedCount {
    return [
      padron,
      permiso,
      vehiclePhoto,
      policeReport,
      vehicleFront,
      vehicleBack,
    ].where((file) => file != null).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AddVehicleStep2Screen.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Agregar vehículo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.18,
            colors: [
              Color(0xFF102D5A),
              Color(0xFF07111F),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(uploadedCount: _uploadedCount),
                const SizedBox(height: 20),
                _SectionCard(
                  title: "Documentos oficiales",
                  subtitle:
                      "Estos antecedentes permiten validar propiedad y denuncia.",
                  icon: Icons.description_outlined,
                  children: [
                    _docTile(
                      title: "Padrón del vehículo *",
                      subtitle: "Documento oficial del vehículo",
                      file: padron,
                      icon: Icons.article_outlined,
                      onTap: () => _pickImage((f) => padron = f),
                    ),
                    _docTile(
                      title: "Permiso de circulación *",
                      subtitle: "Último permiso vigente",
                      file: permiso,
                      icon: Icons.event_available_outlined,
                      onTap: () => _pickImage((f) => permiso = f),
                    ),
                    _docTile(
                      title: "Parte de Carabineros *",
                      subtitle: "Denuncia oficial por robo",
                      file: policeReport,
                      icon: Icons.local_police_outlined,
                      onTap: () => _pickImage((f) => policeReport = f),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: "Fotos del vehículo",
                  subtitle:
                      "Ayudan a comparar visualmente el vehículo durante los reportes.",
                  icon: Icons.camera_alt_outlined,
                  children: [
                    _docTile(
                      title: "Foto general del vehículo *",
                      subtitle: "Vehículo completo y visible",
                      file: vehiclePhoto,
                      icon: Icons.directions_car_rounded,
                      onTap: () => _pickImage((f) => vehiclePhoto = f),
                    ),
                    _docTile(
                      title: "Foto frontal del vehículo *",
                      subtitle: "Debe verse claramente el frontal",
                      file: vehicleFront,
                      icon: Icons.crop_landscape_rounded,
                      onTap: () => _pickImage((f) => vehicleFront = f),
                    ),
                    _docTile(
                      title: "Foto trasera del vehículo *",
                      subtitle: "Debe verse claramente la parte trasera",
                      file: vehicleBack,
                      icon: Icons.crop_16_9_rounded,
                      onTap: () => _pickImage((f) => vehicleBack = f),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SecurityNote(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: _canContinue
                          ? const [
                              Color(0xFF00A3FF),
                              Color(0xFF0057FF),
                            ]
                          : [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.08),
                            ],
                    ),
                    boxShadow: [
                      if (_canContinue)
                        BoxShadow(
                          color: AddVehicleStep2Screen.neon.withOpacity(0.42),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _checkingMembership ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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
                        : Text(
                            _canContinue
                                ? "Continuar a membresía"
                                : "Faltan documentos ($_uploadedCount/6)",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 16.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _docTile({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    bool highlight = false,
  }) {
    final bool uploaded = file != null;
    final Color borderColor = uploaded
        ? AddVehicleStep2Screen.green
        : highlight
            ? AddVehicleStep2Screen.red.withOpacity(0.72)
            : AddVehicleStep2Screen.cyan.withOpacity(0.18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: uploaded
                ? AddVehicleStep2Screen.green.withOpacity(0.075)
                : Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: uploaded
                      ? AddVehicleStep2Screen.green.withOpacity(0.14)
                      : highlight
                          ? AddVehicleStep2Screen.red.withOpacity(0.12)
                          : AddVehicleStep2Screen.neon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: uploaded
                        ? AddVehicleStep2Screen.green.withOpacity(0.28)
                        : highlight
                            ? AddVehicleStep2Screen.red.withOpacity(0.28)
                            : AddVehicleStep2Screen.cyan.withOpacity(0.18),
                  ),
                  image: uploaded
                      ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: uploaded
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AddVehicleStep2Screen.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 15,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: highlight
                            ? AddVehicleStep2Screen.red
                            : AddVehicleStep2Screen.cyan,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaded ? "Archivo cargado correctamente" : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: uploaded
                            ? AddVehicleStep2Screen.green.withOpacity(0.88)
                            : Colors.white.withOpacity(0.58),
                        fontSize: 12.6,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                uploaded
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                color: uploaded
                    ? AddVehicleStep2Screen.green
                    : highlight
                        ? AddVehicleStep2Screen.red
                        : AddVehicleStep2Screen.cyan,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int uploadedCount;

  const _StepHeader({required this.uploadedCount});

  @override
  Widget build(BuildContext context) {
    const Color cyan = AddVehicleStep2Screen.cyan;
    const Color neon = AddVehicleStep2Screen.neon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AddVehicleStep2Screen.card.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cyan.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepPill(text: "Paso 2 de 4"),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: neon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cyan.withOpacity(0.22)),
                ),
                child: Text(
                  "$uploadedCount/6 cargados",
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "Documentos y fotos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sube los antecedentes obligatorios para validar el vehículo y activar el siguiente paso.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.50,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final String text;

  const _StepPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AddVehicleStep2Screen.neon.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AddVehicleStep2Screen.cyan.withOpacity(0.26),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AddVehicleStep2Screen.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: AddVehicleStep2Screen.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AddVehicleStep2Screen.cyan.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AddVehicleStep2Screen.neon.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AddVehicleStep2Screen.cyan.withOpacity(0.18),
                  ),
                ),
                child: Icon(
                  icon,
                  color: AddVehicleStep2Screen.cyan,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AddVehicleStep2Screen.green.withOpacity(0.075),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AddVehicleStep2Screen.green.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AddVehicleStep2Screen.green,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Todos los archivos serán revisados por SKANO antes de activar el vehículo en la plataforma.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 13.5,
                height: 1.38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.045),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AddVehicleStep2Screen.neon.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AddVehicleStep2Screen.cyan,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}