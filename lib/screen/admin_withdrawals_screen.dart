import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  String money(num v) => NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 0,
      ).format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        title: const Text("Retiros solicitados"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('withdraw_request', isEqualTo: true)
            .orderBy('withdraw_requested_at', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay retiros pendientes",
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
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row("Usuario", d['email'] ?? ''),
                    _row("Monto", money(d['withdraw_amount'] ?? 0)),
                    _row("Banco", d['bank_name'] ?? ''),
                    _row("Cuenta", d['account_type'] ?? ''),
                    _row(
                      "N°",
                      d['account_number']
                              ?.toString()
                              .replaceAll(RegExp(r'.(?=.{4})'), '*') ??
                          '',
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _markPaid(context, doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Marcar como pagado"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _reject(context, doc.id),
                            child: const Text("Rechazar"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(l,
                  style: const TextStyle(color: Colors.white70))),
          Text(v,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      "withdraw_request": false,
      "rewards_balance": 0,
      "withdraw_amount": 0,
      "withdraw_requested_at": null,
      "bank_verified": true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Retiro marcado como pagado")),
    );
  }

  Future<void> _reject(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      "withdraw_request": false,
      "withdraw_amount": 0,
      "withdraw_requested_at": null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Retiro rechazado")),
    );
  }
}
