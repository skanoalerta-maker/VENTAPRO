import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Premios y niveles",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0A6CFF),
              ),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // ================= DATOS USUARIO =================
          final String fullName =
              data['full_name'] ?? 'Usuario';
          final String? photoUrl =
              (data['faceUrl'] != null && data['faceUrl'] != '')
                  ? data['faceUrl']
                  : null;

          final String levelRaw =
              (data['level'] ?? 'bronce').toString();
          final String level =
              "Nivel ${levelRaw[0].toUpperCase()}${levelRaw.substring(1)}";

          // ================= STATS =================
          final int reportesEnviados =
              (data['reportes_enviados'] ?? 0) as int;
          final int reportesAcertados =
              (data['reportes_acertados'] ?? 0) as int;

          final int effectiveness = reportesEnviados == 0
              ? 0
              : ((reportesAcertados / reportesEnviados) * 100).round();

          // Regla actual (Bronce)
          final int nextHits = 6;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ---------------- HEADER ----------------
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _glass(),
                  child: Row(
                    children: [
                      // FOTO
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF38BDF8),
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(width: 14),

                      // NOMBRE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Reportero gratuito",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // NIVEL
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF97316),
                              Color(0xFFFACC15)
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ---------------- PROGRESO ----------------
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Progreso hacia el siguiente nivel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$reportesAcertados / $nextHits aciertos",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: reportesAcertados / nextHits,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade900,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF22C55E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Te faltan ${nextHits - reportesAcertados} reportes acertados para subir a Nivel Plata.",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ---------------- STATS ----------------
                Row(
                  children: [
                    Expanded(
                      child: _miniStat(
                        icon: Icons.assignment_outlined,
                        title: "Reportes enviados",
                        value: "$reportesEnviados",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniStat(
                        icon: Icons.verified,
                        title: "Aciertos",
                        value: "$reportesAcertados",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniStat(
                        icon: Icons.bolt_outlined,
                        title: "Efectividad",
                        value: "$effectiveness%",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------------- INFO ----------------
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _glass(),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tus recompensas SKANO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "En Nivel Bronce puedes recibir hasta \$50.000 por cada hallazgo verificado.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Al subir a Nivel Plata puedes optar a hasta \$75.000 por hallazgo confirmado.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- GLASS ----------------
BoxDecoration _glass() {
  return BoxDecoration(
    color: const Color(0x331A1F2E),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0x22FFFFFF)),
    boxShadow: const [
      BoxShadow(
        color: Colors.black87,
        blurRadius: 18,
        offset: Offset(0, 10),
      )
    ],
  );
}
