import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRecoveredVehiclesScreen extends StatelessWidget {
  const AdminRecoveredVehiclesScreen({super.key});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        title: const Text("Vehículos recuperados"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stolen_vehicles')
            .where('status', isEqualTo: 'recovered')
            .orderBy('recoveredAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no hay vehículos recuperados",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🚗 PATENTE
                    Text(
                      d['plate'] ?? 'SIN PATENTE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 🚙 VEHÍCULO
                    Text(
                      "${d['brand'] ?? ''} ${d['model'] ?? ''}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 6),

                    // 👤 DUEÑO
                    Text(
                      "Dueño: ${d['ownerName'] ?? ''}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      d['ownerEmail'] ?? '',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 📅 FECHAS
                    Text(
                      "Reportado: ${_formatDate(d['createdAt'])}",
                      style: const TextStyle(color: Colors.white38),
                    ),
                    Text(
                      "Recuperado: ${_formatDate(d['recoveredAt'])}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ ESTADO
                    const Chip(
                      label: Text(
                        "RECUPERADO",
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.greenAccent,
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
