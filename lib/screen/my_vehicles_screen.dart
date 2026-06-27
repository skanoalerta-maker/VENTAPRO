import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyVehiclesScreen extends StatelessWidget {
  const MyVehiclesScreen({super.key});

  static const Color neon = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Sesión inválida",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Mis vehículos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Agregar vehículo",
            onPressed: () {
              Navigator.pushNamed(context, "/add_vehicle");
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("vehicles")
            .where("owner_uid", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: neon),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(context);
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final doc = vehicles[index];
              final data = doc.data() as Map<String, dynamic>;

              // 🔒 Asegura id (por si no viene dentro del mapa)
              data["id"] ??= doc.id;

              return _vehicleCard(context, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: neon,
        icon: const Icon(Icons.add),
        label: const Text("Agregar otro vehículo"),
        onPressed: () {
          Navigator.pushNamed(context, "/add_vehicle");
        },
      ),
    );
  }

  // =====================================================
  // 🧾 CARD PREMIUM DE VEHÍCULO (con foto + badge inteligente)
  // =====================================================
  Widget _vehicleCard(BuildContext context, Map<String, dynamic> data) {
    final plate = (data["plate"] ?? "").toString().trim();
    final plateNorm = (data["plate_normalized"] ?? plate).toString().trim().toUpperCase();
    final brand = (data["brand"] ?? "").toString().trim();
    final model = (data["model"] ?? "").toString().trim();

    final String vehicleId = (data["vehicle_id"] ?? data["id"] ?? "").toString().trim();

    // ✅ Foto principal
    final String vehiclePhotoUrl = (data["vehicle_photo_url"] ?? "").toString();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadStolenStatus(vehicleId: vehicleId, plateNorm: plateNorm),
      builder: (context, snap) {
        final stolen = snap.data; // puede ser null
        final stolenStatus = (stolen?["status"] ?? "").toString().trim().toLowerCase();
        final stolenActive = stolen?["active"] == true;

        // ✅ Campos del vehículo
        final bool membershipActive = data["membership_active"] == true;
        final bool verified = data["verified"] == true;

        final String status = (data["status"] ?? "").toString().trim().toLowerCase();
        final String reviewStatus =
            (data["review_status"] ?? "").toString().trim().toLowerCase();

        // =====================================================
        // ✅ BADGE: prioridad basada en stolen_vehicles primero
        // =====================================================
        String statusLabel;
        Color statusColor;
        IconData statusIcon;

        final bool isRecovered = stolenStatus == "recovered";
        final bool isStolenOrReported = (stolenStatus == "stolen" || stolenStatus == "reported");

        final bool isPendingReview =
            status == "pending" || reviewStatus == "pending" || verified == false;

        if (isRecovered) {
          statusLabel = "RECUPERADO";
          statusColor = Colors.tealAccent;
          statusIcon = Icons.check_circle_rounded;
        } else if (isStolenOrReported && (stolenActive || stolenStatus == "reported")) {
          // si está "reported" normalmente active ya es false, pero igual queremos mostrarlo
          statusLabel = (stolenStatus == "stolen") ? "ROBADO (ACTIVO)" : "REPORTADO";
          statusColor = Colors.redAccent;
          statusIcon = Icons.report_rounded;
        } else if (membershipActive) {
          statusLabel = "PROTECCIÓN ACTIVA";
          statusColor = Colors.greenAccent;
          statusIcon = Icons.verified_rounded;
        } else if (isPendingReview) {
          statusLabel = "EN VERIFICACIÓN";
          statusColor = Colors.orangeAccent;
          statusIcon = Icons.hourglass_top_rounded;
        } else {
          statusLabel = "INACTIVO";
          statusColor = Colors.redAccent;
          statusIcon = Icons.lock_rounded;
        }

        final String titleLine = plate.isNotEmpty ? plate : "SIN PATENTE";
        final String subtitleLine =
            ("$brand $model").trim().isNotEmpty ? ("$brand $model").trim() : "Vehículo";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // Navigator.pushNamed(context, "/vehicle_detail", arguments: data);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // ================= FOTO / PLACEHOLDER =================
                      SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: (vehiclePhotoUrl.isNotEmpty)
                            ? Image.network(
                                vehiclePhotoUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.white.withOpacity(0.04),
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      height: 26,
                                      width: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: neon,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return _photoFallback();
                                },
                              )
                            : _photoFallback(),
                      ),

                      // ================= OVERLAY GRADIENTE =================
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.black.withOpacity(0.35),
                                Colors.black.withOpacity(0.80),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ================= BORDE NEON SUAVE =================
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: neon.withOpacity(0.22)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),

                      // ================= CONTENIDO =================
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ================= BADGE ESTADO =================
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _statusBadge(
                          label: statusLabel,
                          color: statusColor,
                          icon: statusIcon,
                        ),
                      ),

                      // ================= TAG SKANO =================
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: neon,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "SKANO",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // 🔎 Busca estado en stolen_vehicles
  // Prioridad:
  // 1) where vehicle_id == <vehicleId>
  // 2) where plate_normalized == <plateNorm>
  // Devuelve data del doc o null si no existe
  // =====================================================
  Future<Map<String, dynamic>?> _loadStolenStatus({
    required String vehicleId,
    required String plateNorm,
  }) async {
    try {
      final col = FirebaseFirestore.instance.collection("stolen_vehicles");

      if (vehicleId.isNotEmpty) {
        final q1 = await col.where("vehicle_id", isEqualTo: vehicleId).limit(1).get();
        if (q1.docs.isNotEmpty) return q1.docs.first.data();
      }

      if (plateNorm.isNotEmpty) {
        final q2 = await col.where("plate_normalized", isEqualTo: plateNorm).limit(1).get();
        if (q2.docs.isNotEmpty) return q2.docs.first.data();
      }

      return null;
    } catch (_) {
      // si falla el lookup, no rompemos la UI
      return null;
    }
  }

  Widget _photoFallback() {
    return Container(
      color: const Color(0xFF0B0E14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neon.withOpacity(0.25)),
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: Colors.white.withOpacity(0.55),
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📭 ESTADO VACÍO
  // =====================================================
  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            const Text(
              "Aún no tienes vehículos registrados",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Agregar vehículo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, "/add_vehicle");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
