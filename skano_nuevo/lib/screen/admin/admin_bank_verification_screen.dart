import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBankVerificationScreen extends StatelessWidget {
  const AdminBankVerificationScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Verificaciones bancarias"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('payout_verification_status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Error al cargar verificaciones bancarias",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No hay verificaciones bancarias pendientes",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data();

              final fullName = (d['full_name'] ?? 'Sin nombre').toString();
              final email = (d['email'] ?? 'Sin email').toString();
              final rut = (d['nationalId'] ?? '-').toString();
              final bankName = (d['bank_name'] ?? '-').toString();
              final accountType = (d['account_type'] ?? '-').toString();
              final accountNumber = (d['account_number'] ?? '-').toString();
              final status =
                  (d['payout_verification_status'] ?? 'pending').toString();

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line("Email", email),
                        _line("RUT", rut),
                        _line("Banco", bankName),
                        _line("Tipo", accountType),
                        _line("Cuenta", accountNumber),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            "Estado: $status",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin_review_bank_verification',
                      arguments: {
                        'userId': doc.id,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13.5,
        ),
      ),
    );
  }
}