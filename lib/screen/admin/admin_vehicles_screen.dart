import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_review_vehicle_screen.dart';

class AdminVehiclesScreen extends StatelessWidget {
  const AdminVehiclesScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("vehicles")
        // ✅ OFICIAL: el admin se guía SOLO por verification_status
        .where("verification_status", isEqualTo: "pending")
        // ⚠️ submitted_at puede ser null al inicio si viene de serverTimestamp,
        // por eso usamos orderBy pero el render aguanta nulls.
        .orderBy("submitted_at", descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Vehículos pendientes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error Firestore:\n${snap.error}",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: Text(
                "Cargando datos…",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay vehículos pendientes",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final v = docs[i];
              final data = v.data() as Map<String, dynamic>;

              final plate = (data["plate"] ?? "").toString();
              final brand = (data["brand"] ?? "").toString();
              final model = (data["model"] ?? "").toString();
              final ownerUid = (data["owner_uid"] ?? "").toString();
              final membershipExempt = data["membership_exempt"] == true;

              // submitted_at puede venir null (serverTimestamp recién escribiéndose)
              final Timestamp? submittedAt =
                  data["submitted_at"] is Timestamp ? data["submitted_at"] as Timestamp : null;

              return _vehicleCard(
                context,
                vehicleId: v.id,
                plate: plate,
                brandModel: "$brand • $model",
                ownerUid: ownerUid,
                membershipExempt: membershipExempt,
                submittedAt: submittedAt,
              );
            },
          );
        },
      ),
    );
  }

  // ===================================================
  // VEHICLE CARD
  // ===================================================
  Widget _vehicleCard(
    BuildContext context, {
    required String vehicleId,
    required String plate,
    required String brandModel,
    required String ownerUid,
    required bool membershipExempt,
    required Timestamp? submittedAt,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminReviewVehicleScreen(vehicleId: vehicleId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: neonBlue.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: neonBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: neonBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brandModel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Dueño: $ownerUid",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      submittedAt != null
                          ? "Enviado: ${submittedAt.toDate()}"
                          : "Enviado: (procesando...)",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (membershipExempt)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "FOUNDER",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
