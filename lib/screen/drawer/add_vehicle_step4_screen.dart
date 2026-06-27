import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddVehicleStep4Screen extends StatefulWidget {
  const AddVehicleStep4Screen({super.key});

  @override
  State<AddVehicleStep4Screen> createState() => _AddVehicleStep4ScreenState();
}

class _AddVehicleStep4ScreenState extends State<AddVehicleStep4Screen> {
  static const Color neon = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF00D5FF);
  static const Color green = Color(0xFF14F195);
  static const Color red = Color(0xFFFF4D5E);
  static const Color bg = Color(0xFF020617);
  static const Color card = Color(0xFF0B1220);

  bool _saving = true;
  bool _initialized = false;
  String? _error;

  String? _plate;
  String? _brand;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        _initAndSave();
      }
    });
  }

  Future<String> _uploadFile({
    required File file,
    required String vehicleId,
    required String name,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child("vehicles")
        .child(vehicleId)
        .child(name);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _initAndSave() async {
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      final draft = args?["vehicleDraft"] as Map<String, dynamic>?;
      final docs = args?["vehicleDocs"] as Map<String, File>?;

      if (draft == null || docs == null) {
        _fail("Datos incompletos del vehículo.");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _fail("Sesión inválida.");
        return;
      }

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      final plate = (draft["plate"] ?? "").toString().toUpperCase().trim();
      final brand = (draft["brand"] ?? "").toString().trim();
      final model = (draft["model"] ?? "").toString().trim();
      final int year = int.tryParse((draft["year"] ?? "0").toString()) ?? 0;
      final color = (draft["color"] ?? "").toString().trim();
      final type = (draft["type"] ?? "").toString().trim();

      if (plate.isEmpty || brand.isEmpty || model.isEmpty || year <= 0) {
        _fail("Datos del vehículo inválidos (patente/marca/modelo/año).");
        return;
      }

      setState(() {
        _plate = plate;
        _brand = brand;
      });

      final userSnap = await firestore.collection("users").doc(uid).get();
      final userData = userSnap.data();

      if (userData == null) {
        _fail("No se encontró la información del usuario.");
        return;
      }

      final bool membershipActive = userData["membership_active"] == true;
      final bool membershipExempt = userData["membership_exempt"] == true;
      final bool founder = userData["founder"] == true;

      final bool canRegister =
          membershipActive || (membershipExempt && founder);

      if (!canRegister) {
        _fail("Debes tener una membresía activa para registrar el vehículo.");
        return;
      }

      final dup = await firestore
          .collection("vehicles")
          .where("owner_uid", isEqualTo: uid)
          .where("plate", isEqualTo: plate)
          .limit(1)
          .get();

      DocumentReference vehicleRef;
      bool isNew = false;

      if (dup.docs.isNotEmpty) {
        final doc = dup.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final vStatus = (data["verification_status"] ??
                data["review_status"] ??
                data["status"] ??
                "draft")
            .toString();

        if (vStatus == "pending" || vStatus == "approved") {
          _fail("Este vehículo ya está en proceso de revisión o aprobado.");
          return;
        }

        vehicleRef = doc.reference;
      } else {
        vehicleRef = firestore.collection("vehicles").doc();
        isNew = true;
      }

      final vehicleId = vehicleRef.id;

      final photoUrl = docs["vehicle_photo_file"] != null
          ? await _uploadFile(
              file: docs["vehicle_photo_file"]!,
              vehicleId: vehicleId,
              name: "vehicle_photo.jpg",
            )
          : "";

      final padronUrl = docs["padron_file"] != null
          ? await _uploadFile(
              file: docs["padron_file"]!,
              vehicleId: vehicleId,
              name: "padron.pdf",
            )
          : "";

      final permisoUrl = docs["permiso_file"] != null
          ? await _uploadFile(
              file: docs["permiso_file"]!,
              vehicleId: vehicleId,
              name: "permiso.pdf",
            )
          : "";

      final policeUrl = docs["police_report_file"] != null
          ? await _uploadFile(
              file: docs["police_report_file"]!,
              vehicleId: vehicleId,
              name: "police_report.pdf",
            )
          : "";

      final docsOk = photoUrl.isNotEmpty &&
          padronUrl.isNotEmpty &&
          permisoUrl.isNotEmpty &&
          policeUrl.isNotEmpty;

      if (!docsOk) {
        _fail("Faltan documentos obligatorios (foto, padrón, permiso, denuncia).");
        return;
      }

      await vehicleRef.set({
        "owner_uid": uid,
        "plate": plate,
        "brand": brand,
        "model": model,
        "year": year,
        "color": color,
        "type": type,
        "membership_required": true,
        "membership_active": membershipActive,
        "membership_exempt": membershipExempt && founder,
        "status": "draft",
        "verification_status": "pending",
        "review_status": "pending",
        "verified": false,
        "active": false,
        "vehicle_photo_url": photoUrl,
        "documents": {
          "padron_url": padronUrl,
          "permiso_url": permisoUrl,
          "police_report_url": policeUrl,
        },
        "documents_completed": true,
        "submitted_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userUpdate = <String, dynamic>{
        "last_activity": FieldValue.serverTimestamp(),
      };

      if (isNew) {
        userUpdate["vehicles_count"] = FieldValue.increment(1);
      }

      await firestore.collection("users").doc(uid).update(userUpdate);

      if (!mounted) return;
      setState(() => _saving = false);
    } catch (e) {
      _fail("Error guardando vehículo: $e");
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _error = msg;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Registro de vehículo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: _saving
                ? _savingState()
                : _error != null
                    ? _errorState()
                    : _successState(),
          ),
        ),
      ),
    );
  }

  Widget _savingState() {
    return Column(
      children: [
        _StepHeader(statusText: "Guardando"),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _mainCardDecoration(),
          child: Column(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neon.withOpacity(0.10),
                  border: Border.all(color: cyan.withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: neon.withOpacity(0.35),
                      blurRadius: 42,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: cyan,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                "Subiendo antecedentes",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Estamos guardando los documentos y preparando el vehículo para revisión administrativa.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.45,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _errorState() {
    return Column(
      children: [
        _StepHeader(statusText: "Error"),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _mainCardDecoration(borderColor: red.withOpacity(0.25)),
          child: Column(
            children: [
              _StatusIcon(
                icon: Icons.error_outline_rounded,
                color: red,
              ),
              const SizedBox(height: 22),
              const Text(
                "No se pudo completar",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.45,
                  fontSize: 14.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _goVehiclesBtn(label: "Volver a mis vehículos"),
      ],
    );
  }

  Widget _successState() {
    return Column(
      children: [
        _StepHeader(statusText: "En revisión"),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _mainCardDecoration(borderColor: green.withOpacity(0.22)),
          child: Column(
            children: [
              _StatusIcon(
                icon: Icons.pending_actions_rounded,
                color: green,
              ),
              const SizedBox(height: 22),
              const Text(
                "Vehículo en revisión",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${_brand ?? "Vehículo"} • ${_plate ?? ""}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: cyan,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _InfoLine(
                icon: Icons.verified_user_outlined,
                text: "Tu vehículo fue enviado a revisión administrativa.",
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.access_time_rounded,
                text: "Tiempo estimado de revisión: 1 a 2 horas.",
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.notifications_active_outlined,
                text: "Te notificaremos cuando el equipo SKANO lo revise.",
              ),
            ],
          ),
        ),
        const Spacer(),
        _goVehiclesBtn(label: "Ver mis vehículos"),
      ],
    );
  }

  BoxDecoration _mainCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: card.withOpacity(0.92),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: borderColor ?? cyan.withOpacity(0.16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.34),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: neon.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _goVehiclesBtn({required String label}) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00A3FF),
            Color(0xFF0057FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.42),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          "/my_vehicles",
          (_) => false,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 16.5,
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String statusText;

  const _StepHeader({required this.statusText});

  @override
  Widget build(BuildContext context) {
    const Color cyan = _AddVehicleStep4ScreenState.cyan;
    const Color neon = _AddVehicleStep4ScreenState.neon;
    const Color card = _AddVehicleStep4ScreenState.card;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cyan.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepPill(text: "Paso 4 de 4"),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: neon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cyan.withOpacity(0.22)),
                ),
                child: Text(
                  statusText.toUpperCase(),
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
            "Finalizando registro",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "SKANO está procesando la información del vehículo para enviarla a revisión.",
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
              value: 1,
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
    const Color neon = _AddVehicleStep4ScreenState.neon;
    const Color cyan = _AddVehicleStep4ScreenState.cyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: neon.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cyan.withOpacity(0.26)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.32),
            blurRadius: 38,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 56,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const Color cyan = _AddVehicleStep4ScreenState.cyan;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: cyan,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 13.6,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}