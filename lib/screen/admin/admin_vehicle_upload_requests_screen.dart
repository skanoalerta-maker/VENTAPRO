import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminVehicleUploadRequestsScreen extends StatefulWidget {
  const AdminVehicleUploadRequestsScreen({super.key});

  @override
  State<AdminVehicleUploadRequestsScreen> createState() =>
      _AdminVehicleUploadRequestsScreenState();
}

class _AdminVehicleUploadRequestsScreenState
    extends State<AdminVehicleUploadRequestsScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  bool _loading = false;

  Future<void> _approveRequest({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    setState(() => _loading = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      final uid = data["uid"];

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      batch.set(
        db.collection("users").doc(uid),
        {
          "vehicle_upload_authorized": true,
          "vehicle_upload_authorized_at": FieldValue.serverTimestamp(),
          "vehicle_upload_authorized_by": adminUid,
          "vehicle_upload_authorization_note":
              "Autorizado desde consola interna SKANO",
          "updated_at": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        db.collection("vehicle_upload_requests").doc(requestId),
        {
          "status": "approved",
          "approved_at": FieldValue.serverTimestamp(),
          "approved_by": adminUid,
          "updated_at": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _snack("Usuario autorizado para subir vehículo.");
    } catch (e) {
      _snack("Error: $e", error: true);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() => _loading = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection("vehicle_upload_requests")
          .doc(requestId)
          .set(
        {
          "status": "rejected",
          "rejected_at": FieldValue.serverTimestamp(),
          "rejected_by": adminUid,
          "updated_at": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _snack("Solicitud rechazada.");
    } catch (e) {
      _snack("Error: $e", error: true);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Solicitudes subir vehículo"),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("vehicle_upload_requests")
                .where("status", isEqualTo: "pending")
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: neonBlue),
                );
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No hay solicitudes pendientes.",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _requestCard(doc.id, data);
                },
              );
            },
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

  Widget _requestCard(String requestId, Map<String, dynamic> data) {
    final name = (data["full_name"] ?? "Usuario sin nombre").toString();
    final email = (data["email"] ?? "").toString();
    final phone = (data["phone"] ?? "").toString();
    final plate = (data["plate"] ?? "").toString();
    final brand = (data["brand"] ?? "").toString();
    final model = (data["model"] ?? "").toString();
    final year = (data["year"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text("Correo: $email", style: _infoStyle()),
          Text("Teléfono: $phone", style: _infoStyle()),
          const SizedBox(height: 8),
          Text(
            "Vehículo: $plate · $brand $model $year",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _approveRequest(
                            requestId: requestId,
                            data: data,
                          ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Aprobar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _rejectRequest(requestId),
                  icon: const Icon(Icons.close),
                  label: const Text("Rechazar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _infoStyle() {
    return const TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.35,
    );
  }
}