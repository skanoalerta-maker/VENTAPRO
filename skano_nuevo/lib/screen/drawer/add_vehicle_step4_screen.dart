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

  // =====================================================
  // ⬆️ SUBIDA A STORAGE
  // =====================================================
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

  // =====================================================
  // 💾 PROCESO PRINCIPAL
  // =====================================================
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

      // =====================================================
      // ✅ VALIDAR MEMBRESÍA REAL ANTES DE GUARDAR
      // =====================================================
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

      // =====================================================
      // 🔁 BUSCAR VEHÍCULO EXISTENTE
      // =====================================================
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

      // =====================================================
      // ⬆️ SUBIR ARCHIVOS
      // =====================================================
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

      // =====================================================
      // 💾 GUARDAR / ACTUALIZAR VEHÍCULO
      // =====================================================
      await vehicleRef.set({
        // PROPIETARIO
        "owner_uid": uid,

        // DATOS
        "plate": plate,
        "brand": brand,
        "model": model,
        "year": year,
        "color": color,
        "type": type,

        // MEMBRESÍA
        "membership_required": true,
        "membership_active": membershipActive,
        "membership_exempt": membershipExempt && founder,

        // STATUS
        "status": "draft",

        // ESTADO OFICIAL ADMIN
        "verification_status": "pending",
        "review_status": "pending",

        "verified": false,
        "active": false,

        // ARCHIVOS
        "vehicle_photo_url": photoUrl,
        "documents": {
          "padron_url": padronUrl,
          "permiso_url": permisoUrl,
          "police_report_url": policeUrl,
        },

        "documents_completed": true,

        // TIEMPOS
        "submitted_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =====================================================
      // 👤 ACTUALIZAR USER (SIN INFLAR CONTADOR)
      // =====================================================
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

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text("Vehículo enviado a revisión"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: _saving
            ? const Center(
                child: CircularProgressIndicator(color: neon),
              )
            : _error != null
                ? _errorState()
                : _successState(),
      ),
    );
  }

  Widget _errorState() => Column(
        children: [
          const Spacer(),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 70),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          _goVehiclesBtn(),
        ],
      );

  Widget _successState() => Column(
        children: [
          const Spacer(),
          const Icon(Icons.pending_actions, color: Colors.white, size: 70),
          const SizedBox(height: 20),
          const Text(
            "Vehículo en revisión",
            style: TextStyle(
              color: neon,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$_brand • $_plate\n\n"
            "Tu vehículo fue enviado a revisión administrativa.\n"
            "Tiempo estimado: 1 a 2 horas.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          _goVehiclesBtn(),
        ],
      );

  Widget _goVehiclesBtn() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            "/my_vehicles",
            (_) => false,
          ),
          style: ElevatedButton.styleFrom(backgroundColor: neon),
          child: const Text(
            "Ver mis vehículos",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
}