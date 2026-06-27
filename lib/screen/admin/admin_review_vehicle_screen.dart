import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReviewVehicleScreen extends StatefulWidget {
  final String vehicleId;

  const AdminReviewVehicleScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<AdminReviewVehicleScreen> createState() => _AdminReviewVehicleScreenState();
}

class _AdminReviewVehicleScreenState extends State<AdminReviewVehicleScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);

  final TextEditingController commentCtrl = TextEditingController();
  bool processing = false;

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _normalizePlate(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    String okText = "Confirmar",
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(okText),
          ),
        ],
      ),
    );
    return res == true;
  }

  // =============================================================
  // 🔥 CREA / ACTUALIZA stolen_vehicles (ROBADO) DESDE vehicles + users
  // =============================================================
  Future<void> _ensureStolenDoc({
    required Map<String, dynamic> v,
    required String comment,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    final plateNorm = _normalizePlate((v["plate"] ?? "").toString());
    if (plateNorm.length != 6) {
      throw Exception("Patente inválida en el documento vehicles (debe tener 6 caracteres).");
    }

    final ownerUid = (v["owner_uid"] ?? "").toString();
    if (ownerUid.isEmpty) {
      throw Exception("owner_uid vacío en vehicles.");
    }

    // Traer datos del dueño (para ownerName/ownerEmail que tu lista muestra)
    final ownerSnap = await firestore.collection("users").doc(ownerUid).get();
    final owner = ownerSnap.data() ?? {};

    final ownerName = (owner["fullName"] ?? owner["full_name"] ?? "").toString();
    final ownerEmail = (owner["email"] ?? "").toString();

    final stolenRef = firestore.collection("stolen_vehicles").doc(widget.vehicleId);

    // Guarda campos que tu AdminStolenVehiclesScreen intenta leer (brand/model/createdAt/etc)
    await stolenRef.set({
      // identidad
      "vehicle_id": widget.vehicleId,
      "owner_uid": ownerUid,
      "plate": plateNorm,
      "plate_normalized": plateNorm,

      // compat UI robados
      "brand": (v["brand"] ?? "").toString(),
      "model": (v["model"] ?? "").toString(),
      "year": v["year"],
      "vehicle_photo_url": (v["vehicle_photo_url"] ?? "").toString(),
      "ownerName": ownerName,
      "ownerEmail": ownerEmail,

      // estado robado
      "status": "stolen",
      "active": true,
      "verified": true,

      // auditoría
      "marked_stolen_by": adminUid,
      "marked_stolen_reason": comment,

      // timestamps (NUEVOS + legacy)
      "createdAt": now,
      "updatedAt": now,
      "created_at": now,
      "updated_at": now,
    }, SetOptions(merge: true));

    // log
    await firestore.collection("admin_logs").add({
      "action": "MARK_STOLEN",
      "adminUid": adminUid,
      "targetCollection": "stolen_vehicles",
      "targetId": widget.vehicleId,
      "createdAt": now,
      "details": {
        "plate": plateNorm,
        "source": "ensureStolenDoc",
        "owner_uid": ownerUid,
      },
    });
  }

  // =============================================================
  // ✅ APROBAR VEHÍCULO + ROBADO (CICLO COMPLETO)
  // =============================================================
  Future<void> _approveAndMarkStolen(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Debes ingresar un comentario (obligatorio)");
      return;
    }

    final plateNorm = _normalizePlate((v["plate"] ?? "").toString());
    if (plateNorm.length != 6) {
      _msg("Patente inválida en el documento (debe tener 6 caracteres)");
      return;
    }

    final ok = await _confirm(
      title: "Aprobar y dejar como ROBADO",
      body:
          "Esto aprobará el vehículo y lo dejará como ROBADO en stolen_vehicles.\n\n"
          "Patente: $plateNorm\n\n¿Confirmas?",
      okText: "Sí, aprobar",
    );
    if (!ok) return;

    setState(() => processing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      final now = FieldValue.serverTimestamp();

      final vehicleRef = firestore.collection("vehicles").doc(widget.vehicleId);

      // 1) aprobar vehículo (tu flujo)
      await vehicleRef.update({
        "verification_status": "approved",
        "review_status": "approved",
        "status": "approved",
        "verified": true,
        "active": true,
        "admin_comment": comment,
        "approved_at": now,
        "approved_by": adminUid,
        "status_updated_at": now,
        "updated_at": now,
      });

      await firestore.collection("admin_logs").add({
        "action": "APPROVE_VEHICLE",
        "adminUid": adminUid,
        "targetCollection": "vehicles",
        "targetId": widget.vehicleId,
        "createdAt": now,
        "details": {
          "plate": plateNorm,
          "owner_uid": v["owner_uid"],
        },
      });

      // 2) crear robado (stolen_vehicles)
      await _ensureStolenDoc(v: v, comment: comment);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error aprobando/robado: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  // =============================================================
  // 🟣 SYNC: si ya está aprobado pero NO existe stolen_vehicles
  // =============================================================
  Future<void> _syncCreateStolen(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Escribe un comentario (motivo) para marcar como robado");
      return;
    }

    final plateNorm = _normalizePlate((v["plate"] ?? "").toString());
    final ok = await _confirm(
      title: "Crear ROBADO (SYNC)",
      body:
          "Este vehículo ya puede estar aprobado.\n\n"
          "Esto SOLO creará/actualizará stolen_vehicles como ROBADO.\n\n"
          "Patente: $plateNorm\n\n¿Confirmas?",
      okText: "Sí, crear robado",
    );
    if (!ok) return;

    setState(() => processing = true);

    try {
      await _ensureStolenDoc(v: v, comment: comment);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error creando robado: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  // =============================================================
  // 🔵 RECUPERADO
  // =============================================================
  Future<void> _markAsRecovered(Map<String, dynamic> v) async {
    final plateNorm = _normalizePlate((v["plate"] ?? "").toString());

    final ok = await _confirm(
      title: "Marcar como recuperado",
      body: "Patente: $plateNorm\n\n¿Confirmas?",
      okText: "Sí, recuperado",
    );
    if (!ok) return;

    setState(() => processing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      final now = FieldValue.serverTimestamp();

      final vehicleRef = firestore.collection("vehicles").doc(widget.vehicleId);
      final stolenRef = firestore.collection("stolen_vehicles").doc(widget.vehicleId);

      final stolenSnap = await stolenRef.get();

      await vehicleRef.update({
        "status": "recovered",
        "updated_at": now,
      });

      if (stolenSnap.exists) {
        await stolenRef.update({
          "status": "recovered",
          "active": false,
          "verified": true,
          "recoveredAt": now,
          "recovered_at": now,
          "recovered_by": adminUid,
          "updatedAt": now,
          "updated_at": now,
        });
      }

      await firestore.collection("admin_logs").add({
        "action": "MARK_RECOVERED",
        "adminUid": adminUid,
        "targetCollection": stolenSnap.exists ? "stolen_vehicles" : "vehicles",
        "targetId": widget.vehicleId,
        "createdAt": now,
        "details": {
          "plate": plateNorm,
          "stolen_doc_exists": stolenSnap.exists,
        },
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error recuperado: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  // =============================================================
  // ❌ RECHAZAR
  // =============================================================
  Future<void> _rejectVehicle(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Debes ingresar un motivo de rechazo");
      return;
    }

    final plateNorm = _normalizePlate((v["plate"] ?? "").toString());
    final ok = await _confirm(
      title: "Rechazar vehículo",
      body: "Patente: $plateNorm\n\n¿Confirmas rechazo?",
      okText: "Sí, rechazar",
    );
    if (!ok) return;

    setState(() => processing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      final now = FieldValue.serverTimestamp();

      await firestore.collection("vehicles").doc(widget.vehicleId).update({
        "verification_status": "rejected",
        "review_status": "rejected",
        "status": "rejected",
        "verified": false,
        "active": false,
        "admin_comment": comment,
        "rejected_at": now,
        "rejected_by": adminUid,
        "status_updated_at": now,
        "updated_at": now,
      });

      await firestore.collection("admin_logs").add({
        "action": "REJECT_VEHICLE",
        "adminUid": adminUid,
        "targetCollection": "vehicles",
        "targetId": widget.vehicleId,
        "createdAt": now,
        "details": {"plate": plateNorm, "owner_uid": v["owner_uid"]},
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error rechazando: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  // =============================================================
  // UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Revisión de vehículo"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.collection("vehicles").doc(widget.vehicleId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: neonBlue));
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text("Vehículo no encontrado", style: TextStyle(color: Colors.white70)),
            );
          }

          final v = snap.data!.data()!;
          final docs = (v["documents"] ?? {}) as Map<String, dynamic>;

          final plateNorm = _normalizePlate((v["plate"] ?? "").toString());

          // chequeo en vivo si existe stolen_vehicles
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: firestore.collection("stolen_vehicles").doc(widget.vehicleId).snapshots(),
            builder: (context, stolenSnap) {
              final stolenExists = stolenSnap.hasData && (stolenSnap.data?.exists ?? false);
              final stolenStatus = stolenExists ? (stolenSnap.data!.data()?["status"] ?? "") : "";

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patente: $plateNorm",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${(v["brand"] ?? "").toString()} • ${(v["model"] ?? "").toString()} • ${(v["year"] ?? "").toString()}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _pill("vehicle.verification_status", (v["verification_status"] ?? "").toString()),
                        const SizedBox(width: 8),
                        _pill("stolen_vehicles", stolenExists ? "EXISTE ($stolenStatus)" : "NO EXISTE"),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _docImage("Foto del vehículo", (v["vehicle_photo_url"] ?? "").toString()),
                    const SizedBox(height: 12),
                    _docLink("Padrón", (docs["padron_url"] ?? "").toString()),
                    _docLink("Permiso", (docs["permiso_url"] ?? "").toString()),
                    _docLink("Parte policial", (docs["police_report_url"] ?? "").toString()),

                    const SizedBox(height: 20),

                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Comentario administrador (obligatorio)",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: neonBlue.withOpacity(0.35)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: neonBlue.withOpacity(0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: neonBlue.withOpacity(0.55)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Flujo principal: aprobar + robado
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processing ? null : () => _approveAndMarkStolen(v),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("APROBAR Y DEJAR ROBADO"),
                      ),
                    ),

                    // 🟣 Si ya aprobaste antes con versión vieja: SYNC
                    if (!stolenExists) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: processing ? null : () => _syncCreateStolen(v),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
                          child: const Text("CREAR ROBADO (SYNC)"),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processing ? null : () => _markAsRecovered(v),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: const Text("MARCAR COMO RECUPERADO"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processing ? null : () => _rejectVehicle(v),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("RECHAZAR"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pill(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text("$k: $v", style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _docImage(String t, String url) {
    if (url.isEmpty) {
      return Text("$t: No adjunto", style: const TextStyle(color: Colors.white38));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url, height: 220, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _docLink(String t, String url) {
    if (url.isEmpty) {
      return Text("$t: No adjunto", style: const TextStyle(color: Colors.white38));
    }
    return TextButton(
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text("Abrir $t"),
    );
  }
}
