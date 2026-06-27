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
  State<AdminReviewVehicleScreen> createState() =>
      _AdminReviewVehicleScreenState();
}

class _AdminReviewVehicleScreenState extends State<AdminReviewVehicleScreen> {
  static const Color bg = Color(0xFF080B12);
  static const Color card = Color(0xFF111722);
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

  String _safe(dynamic v) => (v ?? '').toString();

  Future<bool> _confirm({
    required String title,
    required String body,
    String okText = "Confirmar",
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101622),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
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

  Future<void> _ensureStolenDoc({
    required Map<String, dynamic> v,
    required String comment,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    final plateNorm = _normalizePlate(_safe(v["plate"]));
    if (plateNorm.length != 6) {
      throw Exception("Patente inválida en el documento vehicles.");
    }

    final ownerUid = _safe(v["owner_uid"]);
    if (ownerUid.isEmpty) {
      throw Exception("owner_uid vacío en vehicles.");
    }

    final docs = (v["documents"] ?? {}) as Map<String, dynamic>;

    final vehiclePhotoUrl = (
      v["vehicle_photo_url"] ??
      v["vehiclePhotoUrl"] ??
      v["photo_url"] ??
      v["photoUrl"] ??
      docs["vehicle_photo_url"] ??
      docs["vehiclePhotoUrl"] ??
      ""
    ).toString();

    final ownerSnap = await firestore.collection("users").doc(ownerUid).get();
    final owner = ownerSnap.data() ?? {};

    final ownerName = _safe(owner["fullName"] ?? owner["full_name"]);
    final ownerEmail = _safe(owner["email"]);

    final stolenRef =
        firestore.collection("stolen_vehicles").doc(widget.vehicleId);

    await stolenRef.set({
      "vehicle_id": widget.vehicleId,
      "owner_uid": ownerUid,
      "plate": plateNorm,
      "plate_normalized": plateNorm,
      "brand": _safe(v["brand"]),
      "model": _safe(v["model"]),
      "year": v["year"],
      "color": _safe(v["color"]),
      "type": _safe(v["type"]),
      "vehicle_photo_url": vehiclePhotoUrl,
      "ownerName": ownerName,
      "ownerEmail": ownerEmail,
      "status": "stolen",
      "active": true,
      "verified": true,
      "marked_stolen_by": adminUid,
      "marked_stolen_reason": comment,
      "createdAt": now,
      "updatedAt": now,
      "created_at": now,
      "updated_at": now,
    }, SetOptions(merge: true));

    await firestore.collection("admin_logs").add({
      "action": "MARK_STOLEN",
      "adminUid": adminUid,
      "targetCollection": "stolen_vehicles",
      "targetId": widget.vehicleId,
      "createdAt": now,
      "details": {
        "plate": plateNorm,
        "owner_uid": ownerUid,
      },
    });
  }

  Future<void> _approveAndMarkStolen(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Debes ingresar un comentario");
      return;
    }

    final plateNorm = _normalizePlate(_safe(v["plate"]));
    if (plateNorm.length != 6) {
      _msg("Patente inválida");
      return;
    }

    final ok = await _confirm(
      title: "Aprobar y dejar como ROBADO",
      body: "Patente: $plateNorm\n\nEsto aprobará el vehículo y lo dejará activo en stolen_vehicles.",
      okText: "Sí, aprobar",
    );
    if (!ok) return;

    setState(() => processing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      final now = FieldValue.serverTimestamp();

      await firestore.collection("vehicles").doc(widget.vehicleId).update({
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

      await _ensureStolenDoc(v: v, comment: comment);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error aprobando: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> _syncCreateStolen(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Escribe un comentario para crear el encargo");
      return;
    }

    final ok = await _confirm(
      title: "Crear ROBADO",
      body: "Esto creará/actualizará el vehículo en stolen_vehicles.",
      okText: "Crear",
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

  Future<void> _markAsRecovered(Map<String, dynamic> v) async {
    final plateNorm = _normalizePlate(_safe(v["plate"]));

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
      final stolenRef =
          firestore.collection("stolen_vehicles").doc(widget.vehicleId);

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

  Future<void> _rejectVehicle(Map<String, dynamic> v) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      _msg("Debes ingresar un motivo de rechazo");
      return;
    }

    final ok = await _confirm(
      title: "Rechazar vehículo",
      body: "¿Confirmas rechazo?",
      okText: "Rechazar",
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
        "details": {
          "plate": _normalizePlate(_safe(v["plate"])),
          "owner_uid": v["owner_uid"],
        },
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg("Error rechazando: $e");
      if (mounted) setState(() => processing = false);
    }
  }

  Widget _heroVehicle(Map<String, dynamic> v) {
    final photo = _safe(v["vehicle_photo_url"]);
    final plate = _normalizePlate(_safe(v["plate"]));
    final title =
        "${_safe(v["brand"]).toUpperCase()} ${_safe(v["model"]).toUpperCase()}";

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonBlue.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.18),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo.isNotEmpty)
              Image.network(
                photo,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _noImage(),
              )
            else
              _noImage(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF151B26), Color(0xFF0C111A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title.trim().isEmpty ? "Vehículo sin marca/modelo" : title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_safe(v["year"])} • ${_safe(v["color"])} • ${_safe(v["type"])}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noImage() {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFF101622),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, color: Colors.white30, size: 60),
          SizedBox(height: 8),
          Text("Sin foto del vehículo", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _statusPanel(Map<String, dynamic> v, bool stolenExists, String stolenStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Estado del caso",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill("Verificación", _safe(v["verification_status"])),
              _pill("Revisión", _safe(v["review_status"])),
              _pill("Membresía", v["membership_active"] == true ? "ACTIVA" : "INACTIVA"),
              _pill("Documentos", v["documents_completed"] == true ? "COMPLETOS" : "PENDIENTES"),
              _pill("Encargo", stolenExists ? "EXISTE $stolenStatus" : "NO EXISTE"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    final exists = url.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: exists ? color.withOpacity(0.45) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: exists ? color.withOpacity(0.16) : Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: exists ? color : Colors.white30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  exists ? subtitle : "No adjunto",
                  style: TextStyle(
                    color: exists ? Colors.white60 : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (exists)
            IconButton(
              onPressed: () =>
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _documentsSection(Map<String, dynamic> v) {
    final docs = (v["documents"] ?? {}) as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Documentos solicitados",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _documentCard(
            title: "Foto del vehículo",
            subtitle: "Imagen principal cargada por el usuario",
            url: _safe(v["vehicle_photo_url"]),
            icon: Icons.image_outlined,
            color: neonBlue,
          ),
          _documentCard(
            title: "Padrón",
            subtitle: "Documento PDF del padrón",
            url: _safe(docs["padron_url"]),
            icon: Icons.description_outlined,
            color: Colors.orangeAccent,
          ),
          _documentCard(
            title: "Permiso de circulación",
            subtitle: "Documento PDF del permiso",
            url: _safe(docs["permiso_url"]),
            icon: Icons.fact_check_outlined,
            color: Colors.greenAccent,
          ),
          _documentCard(
            title: "Parte policial",
            subtitle: "Documento PDF del encargo/denuncia",
            url: _safe(docs["police_report_url"]),
            icon: Icons.local_police_outlined,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }

  Widget _pill(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        "$k: ${v.isEmpty ? '—' : v}",
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _adminCommentBox() {
    return TextField(
      controller: commentCtrl,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Comentario administrador obligatorio...",
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: neonBlue.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: neonBlue.withOpacity(0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: neonBlue),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: processing ? null : onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Revisión de vehículo",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.collection("vehicles").doc(widget.vehicleId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: neonBlue));
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text("Vehículo no encontrado",
                  style: TextStyle(color: Colors.white70)),
            );
          }

          final v = snap.data!.data()!;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection("stolen_vehicles")
                .doc(widget.vehicleId)
                .snapshots(),
            builder: (context, stolenSnap) {
              final stolenExists =
                  stolenSnap.hasData && (stolenSnap.data?.exists ?? false);
              final stolenStatus =
                  stolenExists ? _safe(stolenSnap.data!.data()?["status"]) : "";

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _heroVehicle(v),
                    const SizedBox(height: 16),
                    _statusPanel(v, stolenExists, stolenStatus),
                    const SizedBox(height: 16),
                    _documentsSection(v),
                    const SizedBox(height: 16),
                    _adminCommentBox(),
                    const SizedBox(height: 18),
                    _actionButton(
                      text: "APROBAR Y DEJAR ROBADO",
                      icon: Icons.verified_outlined,
                      color: Colors.green.shade700,
                      onTap: () => _approveAndMarkStolen(v),
                    ),
                    if (!stolenExists) ...[
                      const SizedBox(height: 10),
                      _actionButton(
                        text: "CREAR ROBADO (SYNC)",
                        icon: Icons.sync,
                        color: const Color(0xFFA855F7),
                        onTap: () => _syncCreateStolen(v),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actionButton(
                      text: "MARCAR COMO RECUPERADO",
                      icon: Icons.check_circle_outline,
                      color: Colors.blueAccent,
                      onTap: () => _markAsRecovered(v),
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      text: "RECHAZAR VEHÍCULO",
                      icon: Icons.cancel_outlined,
                      color: Colors.red.shade700,
                      onTap: () => _rejectVehicle(v),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}