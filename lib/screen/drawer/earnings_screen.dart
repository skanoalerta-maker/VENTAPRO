import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color darkBg = Color(0xFF05070D);
  static const Color cardBg = Color(0xFF111827);

  String _money(num v) => NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 0,
      ).format(v);

  String _mask(String v) {
    if (v.trim().isEmpty) return "No registrada";
    return v.length < 4 ? "****" : "**** ${v.substring(v.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _LoginRequired();
    }

    final uid = user.uid;
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(
          "Ganancias y pagos",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: neonBlue),
              );
            }

            if (snap.hasError) {
              return const _MessageState(
                icon: Icons.error_outline_rounded,
                title: "No pudimos cargar tus ganancias",
                message: "Revisa tu conexión e intenta nuevamente.",
              );
            }

            final d = snap.data?.data() as Map<String, dynamic>? ?? {};

            final balance = (d["rewards_balance"] ?? 0) as num;
            final bankName = (d["bank_name"] ?? "").toString();
            final accountType = (d["account_type"] ?? "").toString();
            final accountNumber = (d["account_number"] ?? "").toString();

            final bankVerified = d["bank_verified"] == true ||
                d["bank_status"]?.toString() == "approved";

            final withdrawRequested = d["withdraw_request"] == true;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                isSmall ? 14 : 18,
                12,
                isSmall ? 14 : 18,
                28,
              ),
              children: [
                _BalanceHeader(
                  balanceText: _money(balance),
                  isSmall: isSmall,
                ),
                const SizedBox(height: 18),

                _InfoNotice(
                  text:
                      "Las recompensas se liberan después de validación interna de SKANO.",
                  icon: Icons.verified_user_rounded,
                ),

                const SizedBox(height: 18),

                _SectionCard(
                  title: "Datos bancarios",
                  icon: Icons.account_balance_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bankName.trim().isEmpty)
                        const _EmptyBankState()
                      else ...[
                        _DataRow(label: "Banco", value: bankName),
                        _DataRow(
                          label: "Tipo de cuenta",
                          value: accountType.isEmpty
                              ? "No informado"
                              : accountType,
                        ),
                        _DataRow(
                          label: "Cuenta",
                          value: _mask(accountNumber),
                        ),
                        const SizedBox(height: 12),
                        _StatusBadge(
                          label: bankVerified
                              ? "Cuenta verificada"
                              : "Cuenta en revisión",
                          color: bankVerified
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFFACC15),
                          icon: bankVerified
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                        ),
                      ],
                      const SizedBox(height: 18),
                      _PrimaryButton(
                        label: "Subir o modificar datos bancarios",
                        icon: Icons.edit_rounded,
                        onPressed: () {
                          Navigator.pushNamed(context, "/bank_account");
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _SectionCard(
                  title: "Retiro de ganancias",
                  icon: Icons.payments_rounded,
                  child: _WithdrawContent(
                    balance: balance,
                    bankVerified: bankVerified,
                    withdrawRequested: withdrawRequested,
                    onWithdraw: () async {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .update({
                        "withdraw_request": true,
                        "withdraw_amount": balance,
                        "withdraw_requested_at": FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ),

                const SizedBox(height: 18),

                const _SecurityBox(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// =======================================================
/// LOGIN REQUIRED
/// =======================================================

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: EarningsScreen.darkBg,
      body: SafeArea(
        child: _MessageState(
          icon: Icons.lock_outline_rounded,
          title: "Inicia sesión",
          message: "Debes iniciar sesión para ver tus ganancias.",
        ),
      ),
    );
  }
}

/// =======================================================
/// HEADER SALDO
/// =======================================================

class _BalanceHeader extends StatelessWidget {
  final String balanceText;
  final bool isSmall;

  const _BalanceHeader({
    required this.balanceText,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A6CFF),
            Color(0xFF1D4ED8),
            Color(0xFF7C3AED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EarningsScreen.neonBlue.withOpacity(0.42),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmall ? 44 : 52,
                height: isSmall ? 44 : 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Text(
                  "SKANO Rewards",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            "Saldo disponible",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balanceText,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 32 : 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Disponible para retiro cuando tu cuenta bancaria esté verificada.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// CARD GENERAL
/// =======================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIcon(icon: icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// =======================================================
/// RETIRO
/// =======================================================

class _WithdrawContent extends StatelessWidget {
  final num balance;
  final bool bankVerified;
  final bool withdrawRequested;
  final Future<void> Function() onWithdraw;

  const _WithdrawContent({
    required this.balance,
    required this.bankVerified,
    required this.withdrawRequested,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    if (balance <= 0) {
      return const _InlineState(
        icon: Icons.savings_outlined,
        title: "Sin saldo disponible",
        message:
            "Cuando un reporte sea validado y genere recompensa, aparecerá aquí.",
      );
    }

    if (!bankVerified) {
      return const _InlineState(
        icon: Icons.account_balance_outlined,
        title: "Cuenta bancaria pendiente",
        message: "Debes verificar tus datos bancarios antes de retirar.",
      );
    }

    if (withdrawRequested) {
      return const _InlineState(
        icon: Icons.pending_actions_rounded,
        title: "Retiro en proceso",
        message: "Ya existe una solicitud de retiro pendiente de revisión.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tu saldo está disponible para solicitar retiro.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: "Solicitar retiro",
          icon: Icons.payments_rounded,
          onPressed: () async {
            await onWithdraw();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Solicitud de retiro enviada."),
                  backgroundColor: Color(0xFF0A6CFF),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// =======================================================
/// COMPONENTES UI
/// =======================================================

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: EarningsScreen.neonBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: EarningsScreen.neonBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  final IconData icon;

  const _SmallIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: EarningsScreen.neonBlue.withOpacity(0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: EarningsScreen.neonBlue.withOpacity(0.35),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF38BDF8),
        size: 21,
      ),
    );
  }
}

class _EmptyBankState extends StatelessWidget {
  const _EmptyBankState();

  @override
  Widget build(BuildContext context) {
    return const _InlineState(
      icon: Icons.account_balance_wallet_outlined,
      title: "Sin datos bancarios",
      message:
          "Agrega tu cuenta bancaria para poder recibir pagos de recompensas.",
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoNotice({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EarningsScreen.neonBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EarningsScreen.neonBlue.withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.7,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityBox extends StatelessWidget {
  const _SecurityBox();

  @override
  Widget build(BuildContext context) {
    return const _InfoNotice(
      icon: Icons.security_rounded,
      text:
          "Por seguridad, SKANO nunca mostrará tu número de cuenta completo dentro de la app.",
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: EarningsScreen.neonBlue, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// GLASS EFFECT
/// =======================================================

BoxDecoration _glass() {
  return BoxDecoration(
    color: EarningsScreen.cardBg.withOpacity(0.82),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.46),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}