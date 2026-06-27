import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// =====================================================
/// SKANO — GANANCIAS Y PAGOS
/// -----------------------------------------------------
/// ESTA PANTALLA ES SOLO DE LECTURA:
/// - Saldo
/// - Reportes acertados
/// - Estado de datos bancarios
/// 
/// ❌ NO edita banco
/// ❌ NO guarda banco
/// ✅ Redirige a /bank_account
/// =====================================================
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool loading = true;

  int rewardsBalance = 0;
  int reportesAcertados = 0;

  String bankName = "";
  bool bankVerified = false;

  /// ================= FORMATO MONEDA =================
  String _money(num value) {
    return NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// ================= CARGA DATOS =================
  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final d = doc.data() ?? {};

    if (!mounted) return;

    setState(() {
      rewardsBalance = (d["rewards_balance"] ?? 0).toInt();
      reportesAcertados = (d["reportes_acertados"] ?? 0).toInt();
      bankName = d["bank_name"] ?? "";
      bankVerified = d["bank_verified"] == true;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Ganancias y pagos"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= SALDO =================
            _card(
              "Saldo disponible",
              _money(rewardsBalance),
              Icons.account_balance_wallet,
              Colors.greenAccent,
            ),

            /// ================= REPORTES =================
            _card(
              "Reportes acertados",
              reportesAcertados.toString(),
              Icons.check_circle,
              Colors.orangeAccent,
            ),

            const SizedBox(height: 30),

            /// ================= CUENTA BANCARIA =================
            const Text(
              "Cuenta bancaria",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// ESTADO CUENTA
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    bankVerified ? Icons.verified : Icons.warning_amber,
                    color: bankVerified
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bankName.isEmpty
                          ? "No has registrado una cuenta bancaria"
                          : bankVerified
                              ? "Cuenta verificada ($bankName)"
                              : "Cuenta pendiente de verificación ($bankName)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// BOTÓN → DATOS BANCARIOS
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_balance),
                label: const Text("Administrar datos bancarios"),
                onPressed: () {
                  Navigator.pushNamed(context, "/bank_account");
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: neonBlue,
                  side: const BorderSide(color: neonBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TARJETA REUTILIZABLE =================
  Widget _card(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
