import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminInternalConsoleScreen extends StatefulWidget {
  const AdminInternalConsoleScreen({super.key});

  @override
  State<AdminInternalConsoleScreen> createState() =>
      _AdminInternalConsoleScreenState();
}

class _AdminInternalConsoleScreenState
    extends State<AdminInternalConsoleScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);

  bool _loading = false;

  Future<void> _initializeUserMetrics() async {
    setState(() => _loading = true);

    try {
      final users = await FirebaseFirestore.instance.collection("users").get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in users.docs) {
        final data = doc.data();

        batch.set(
          doc.reference,
          {
            "plate_reads_count": data["plate_reads_count"] ?? 0,
            "steps_count": data["steps_count"] ?? 0,
            "distance_km": data["distance_km"] ?? 0.0,
            "distance_meters": data["distance_meters"] ?? 0,
            "last_tracking_at": data["last_tracking_at"],
            "metrics_initialized": true,
            "metrics_initialized_at": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      _snack("Métricas inicializadas en ${users.docs.length} usuarios.");
    } catch (e) {
      _showError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initializeVehicleUploadAuthorization() async {
    final ok = await _confirm(
      title: "Inicializar autorización de vehículos",
      message:
          "Esto agregará vehicle_upload_authorized: false a todos los usuarios que aún no tengan ese campo. No borrará datos existentes.",
    );

    if (!ok) return;

    setState(() => _loading = true);

    try {
      final users = await FirebaseFirestore.instance.collection("users").get();
      final batch = FirebaseFirestore.instance.batch();

      int updated = 0;

      for (final doc in users.docs) {
        final data = doc.data();

        if (!data.containsKey("vehicle_upload_authorized")) {
          batch.set(
            doc.reference,
            {
              "vehicle_upload_authorized": false,
              "vehicle_upload_authorized_at": null,
              "vehicle_upload_authorized_by": null,
              "vehicle_upload_authorization_note": "",
              "vehicle_upload_authorization_initialized": true,
              "vehicle_upload_authorization_initialized_at":
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          updated++;
        }
      }

      await batch.commit();

      if (!mounted) return;
      _snack("Campo agregado a $updated usuarios.");
    } catch (e) {
      _showError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initializeReportEvidenceSystem() async {
    final ok = await _confirm(
      title: "Inicializar evidencias de reportes",
      message:
          "Esto agregará campos para fotos extra, videos cortos y revisión admin a todos los usuarios. No borrará datos existentes.",
    );

    if (!ok) return;

    setState(() => _loading = true);

    try {
      final users = await FirebaseFirestore.instance.collection("users").get();
      final batch = FirebaseFirestore.instance.batch();

      int updated = 0;

      for (final doc in users.docs) {
        final data = doc.data();

        batch.set(
          doc.reference,
          {
            "extra_photos_uploaded_count":
                data["extra_photos_uploaded_count"] ?? 0,
            "videos_uploaded_count": data["videos_uploaded_count"] ?? 0,
            "reports_sent_to_admin_count":
                data["reports_sent_to_admin_count"] ?? 0,
            "reports_shared_with_owner_count":
                data["reports_shared_with_owner_count"] ?? 0,
            "report_evidence_initialized": true,
            "report_evidence_initialized_at": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        updated++;
      }

      await batch.commit();

      if (!mounted) return;
      _snack("Sistema de evidencias inicializado en $updated usuarios.");
    } catch (e) {
      _showError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _movePendingUsersToIncomplete() async {
    final ok = await _confirm(
      title: "Mover pendientes incompletos",
      message:
          "Esto moverá usuarios pendientes que no tienen documentación completa a incomplete_users y actualizará su estado.",
    );

    if (!ok) return;

    setState(() => _loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("reviewPending", isEqualTo: true)
          .get();

      int moved = 0;
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snap.docs) {
        final data = doc.data();

        final documentsCompleted = data["documentsCompleted"] == true;
        final faceRegistered = data["faceRegistered"] == true;
        final hasRut = (data["nationalId"] ?? "").toString().trim().isNotEmpty;
        final hasPhone = (data["phone"] ?? "").toString().trim().isNotEmpty;

        final isIncomplete =
            !documentsCompleted || !faceRegistered || !hasRut || !hasPhone;

        if (!isIncomplete) continue;

        final uid = doc.id;

        final incompleteRef =
            FirebaseFirestore.instance.collection("incomplete_users").doc(uid);

        batch.set(
          incompleteRef,
          {
            ...data,
            "uid": uid,
            "source": "admin_internal_console",
            "moved_to_incomplete_at": FieldValue.serverTimestamp(),
            "reason": "Documentación o datos obligatorios incompletos",
          },
          SetOptions(merge: true),
        );

        batch.set(
          doc.reference,
          {
            "reviewPending": false,
            "verification_status": "incomplete",
            "documentStatus": "incomplete",
            "updated_at": FieldValue.serverTimestamp(),
            "admin_comment":
                "Movido a incompletos desde consola interna SKANO.",
          },
          SetOptions(merge: true),
        );

        moved++;
      }

      await batch.commit();

      if (!mounted) return;
      _snack("Usuarios movidos a incompletos: $moved");
    } catch (e) {
      _showError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _activatePendingVehicles() async {
    final ok = await _confirm(
      title: "Activar vehículos pendientes",
      message:
          "Esto aprobará vehículos con status pending_review. Úsalo solo si ya revisaste que corresponden.",
    );

    if (!ok) return;

    setState(() => _loading = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;

      final snap = await FirebaseFirestore.instance
          .collection("vehicles")
          .where("status", isEqualTo: "pending_review")
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snap.docs) {
        batch.set(
          doc.reference,
          {
            "status": "active",
            "active": true,
            "verified_vehicle": true,
            "approved_at": FieldValue.serverTimestamp(),
            "approved_by": adminUid,
            "updated_at": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;
      _snack("Vehículos activados: ${snap.docs.length}");
    } catch (e) {
      _showError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirmar"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "CONSOLA INTERNA SKANO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _hero(),
              const SizedBox(height: 18),

              _section("USUARIOS"),
              _actionCard(
                title: "Mover pendientes incompletos",
                subtitle:
                    "Mueve usuarios pendientes sin datos completos a incomplete_users.",
                icon: Icons.person_off,
                color: Colors.orangeAccent,
                onTap: _movePendingUsersToIncomplete,
              ),

              const SizedBox(height: 18),
              _section("VEHÍCULOS"),
              _actionCard(
                title: "Activar vehículos pendientes",
                subtitle: "Aprueba vehículos en revisión y los deja activos.",
                icon: Icons.directions_car,
                color: Colors.lightBlueAccent,
                onTap: _activatePendingVehicles,
              ),

              const SizedBox(height: 18),
              _section("SISTEMA"),
              _actionCard(
                title: "Inicializar métricas de usuarios",
                subtitle:
                    "Agrega patentes leídas, pasos, kilómetros y distancia a todos los usuarios.",
                icon: Icons.analytics,
                color: Colors.purpleAccent,
                onTap: _initializeUserMetrics,
              ),

              _actionCard(
                title: "Inicializar autorización para subir vehículo",
                subtitle:
                    "Agrega vehicle_upload_authorized: false a usuarios antiguos.",
                icon: Icons.car_rental,
                color: Colors.cyanAccent,
                onTap: _initializeVehicleUploadAuthorization,
              ),

              _actionCard(
                title: "Inicializar evidencias de reportes",
                subtitle:
                    "Agrega campos para fotos extra, videos cortos y revisión admin.",
                icon: Icons.video_camera_back,
                color: Colors.redAccent,
                onTap: _initializeReportEvidenceSystem,
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: const Center(
                child: CircularProgressIndicator(color: neonBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neonBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.dashboard_customize, color: neonBlue, size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Centro de acciones internas. Desde aquí puedes reparar usuarios, activar vehículos y ejecutar mantenimiento sin tocar Firebase manualmente.",
              style: TextStyle(color: Colors.white70, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withOpacity(0.55)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 13),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}