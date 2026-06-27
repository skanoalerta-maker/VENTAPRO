import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static const neonBlue = Color(0xFF0A6CFF);

  String _money(num v) => NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 0,
      ).format(v);

  String _mask(String v) => v.length < 4 ? "****" : "**** ${v.substring(v.length - 4)}";

  @override
  Widget build(BuildContext context) {
    // ✅ QUIRÚRGICO: evitar crash si se cae sesión
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Inicia sesión para ver tus ganancias",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Ganancias y pagos"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          final d = snap.data!.data() as Map<String, dynamic>? ?? {};

          final balance = (d["rewards_balance"] ?? 0) as num;
          final bankName = (d["bank_name"] ?? "").toString();
          final accountType = (d["account_type"] ?? "").toString();
          final accountNumber = (d["account_number"] ?? "").toString();

          // ✅ QUIRÚRGICO: compatibilidad (muchos docs NO traen bank_verified)
          final bankVerified =
              d["bank_verified"] == true || (d["bank_status"]?.toString() == "approved");

          // ✅ QUIRÚRGICO: evitar spam de solicitudes de retiro
          final withdrawRequested = d["withdraw_request"] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ================= HEADER SALDO =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6CFF), Color(0xFF7C4DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonBlue.withOpacity(0.4),
                        blurRadius: 30,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saldo disponible",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _money(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ================= DATOS BANCARIOS =================
                _card(
                  title: "Datos bancarios",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bankName.isEmpty)
                        const Text(
                          "Aún no has registrado tus datos bancarios.",
                          style: TextStyle(color: Colors.white70),
                        )
                      else ...[
                        _row("Banco", bankName),
                        _row("Tipo", accountType),
                        _row("Cuenta", _mask(accountNumber)),
                        const SizedBox(height: 8),
                        Text(
                          bankVerified ? "Cuenta verificada" : "Cuenta en revisión",
                          style: TextStyle(
                            color: bankVerified ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // 🔥 BOTÓN QUE SÍ SE NOTA Y SÍ FUNCIONA
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_balance),
                          label: const Text(
                            "Subir o modificar datos bancarios",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              "/bank_account",
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // ================= RETIRO =================
                _card(
                  title: "Retiro de ganancias",
                  child: Center(
                    child: balance <= 0
                        ? const Text(
                            "No tienes saldo disponible para retirar.",
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          )
                        : !bankVerified
                            ? const Text(
                                "Debes verificar tus datos bancarios antes de retirar.",
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              )
                            : withdrawRequested
                                ? const Text(
                                    "Ya existe una solicitud de retiro en proceso.",
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(uid)
                                          .update({
                                        "withdraw_request": true,
                                        "withdraw_amount": balance,
                                        "withdraw_requested_at":
                                            FieldValue.serverTimestamp(),
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: neonBlue,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      "Solicitar retiro",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: neonBlue.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
