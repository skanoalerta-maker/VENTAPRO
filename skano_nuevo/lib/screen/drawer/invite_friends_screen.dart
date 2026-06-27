import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bg = Color(0xFF0D0F14);

  String userCode = "";
  int invitedTotal = 0;
  int downloads = 0;
  int approvedReportsFromInvites = 0;
  int goal = 5;
  int cycleCount = 0;
  bool rewardEnabled = false;
  bool cycleCompleted = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() => loading = false);
      }
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final data = snap.data() ?? {};
      final stats = data["referralStats"] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        userCode = (data["referralCode"] ?? "").toString();
        invitedTotal = (stats["invitedUsers"] as num?)?.toInt() ?? 0;
        downloads = (stats["downloads"] as num?)?.toInt() ?? 0;
        approvedReportsFromInvites =
            (stats["validReports"] as num?)?.toInt() ?? 0;
        goal = (stats["goal"] as num?)?.toInt() ?? 5;
        rewardEnabled = stats["rewardEnabled"] == true;
        cycleCompleted = stats["cycleCompleted"] == true;
        cycleCount = (data["cycleCount"] as num?)?.toInt() ?? 0;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final code = userCode.isEmpty ? "MI-CODIGO-SKANO" : userCode;

    final message =
        "🚨 SKANO – Seguridad Comunitaria 🚨\n\n"
        "Estoy usando SKANO para reportar vehículos con encargo por robo.\n\n"
        "Usa mi código de invitación:\n"
        "$code\n\n"
        "Si te registras y realizas un reporte válido aprobado, me ayudas a completar "
        "mi ciclo de invitación.\n\n"
        "👉 Descarga oficial: https://www.skano.cl\n\n"
        "Gracias por apoyar la seguridad 🙌";

    final uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: neonBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Invitar amigos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReferralData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              const SizedBox(height: 18),
              _howItWorks(),
              const SizedBox(height: 18),
              _progressCard(),
              const SizedBox(height: 18),
              _statusBox(),
              const SizedBox(height: 18),

              const Text(
                "Niveles de recompensa",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),

              _levelCard(
                title: "Ciclo 5 reportes válidos",
                badge: "Básico",
                desc:
                    "Tus invitados deben realizar reportes válidos aprobados por SKANO.\n"
                    "Al completar el ciclo, se habilita tu pago.",
                amount: "\$50.000 CLP",
                required: 5,
              ),
              const SizedBox(height: 12),

              _levelCard(
                title: "Ciclo 7 reportes válidos",
                badge: "Avanzado",
                desc:
                    "Tus invitados deben realizar reportes válidos aprobados por SKANO.\n"
                    "Al completar el ciclo, se habilita tu pago.",
                amount: "\$70.000 CLP",
                required: 7,
              ),
              const SizedBox(height: 12),

              _levelCard(
                title: "Ciclo 10 reportes válidos",
                badge: "Pro",
                desc:
                    "Tus invitados deben realizar reportes válidos aprobados por SKANO.\n"
                    "Al completar el ciclo, se habilita tu pago.",
                amount: "\$100.000 CLP",
                required: 10,
              ),

              const SizedBox(height: 22),

              const Text(
                "Tu código de invitación",
                style: TextStyle(
                  color: neonBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),

              _inviteCodeBox(context),
              const SizedBox(height: 16),
              _whatsAppButton(context),
              const SizedBox(height: 22),
              _legalBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.25)),
        gradient: LinearGradient(
          colors: [
            neonBlue.withOpacity(0.22),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Invita y gana recompensas reales",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Los pagos se habilitan cuando tus invitados realizan reportes válidos "
            "y aprobados por SKANO.\n\n"
            "Esto es un sistema real: se valida reporte, ubicación y evidencia.",
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "¿Cómo funciona?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _StepRow(
            icon: Icons.share_outlined,
            title: "1) Comparte tu código",
            desc: "Tus amigos se registran y usan tu código de invitación.",
          ),
          SizedBox(height: 10),
          _StepRow(
            icon: Icons.verified_outlined,
            title: "2) Reporte validado",
            desc: "El reporte debe ser real, con evidencia y revisión de SKANO.",
          ),
          SizedBox(height: 10),
          _StepRow(
            icon: Icons.monetization_on_outlined,
            title: "3) Ciclo completado",
            desc: "Al completar la meta, se habilita tu recompensa.",
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final minRequired = goal <= 0 ? 5 : goal;
    final progress =
        (approvedReportsFromInvites / minRequired).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Estado de tu ciclo",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric("Invitados", "$invitedTotal"),
              const SizedBox(width: 8),
              _metric("Descargas", "$downloads"),
              const SizedBox(width: 8),
              _metric("Válidos", "$approvedReportsFromInvites"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metric("Meta", "$minRequired"),
              const SizedBox(width: 8),
              _metric("Ciclos", "$cycleCount"),
              const SizedBox(width: 8),
              _metric("Pago", rewardEnabled ? "Listo" : "Pendiente"),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  AlwaysStoppedAnimation<Color>(neonBlue.withOpacity(0.9)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Progreso: $approvedReportsFromInvites / $minRequired reportes válidos aprobados.",
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            "Nota: el progreso se confirma solo con reportes válidos y aprobados.",
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _statusBox() {
    final text = rewardEnabled || cycleCompleted
        ? "Recompensa habilitada. Tu ciclo ya fue completado y queda pendiente la gestión de pago por SKANO."
        : "Aún no completas la meta. Sigue compartiendo tu código para avanzar.";

    final icon = rewardEnabled || cycleCompleted
        ? Icons.verified_rounded
        : Icons.hourglass_bottom_rounded;

    final color = rewardEnabled || cycleCompleted
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard({
    required String title,
    required String badge,
    required String desc,
    required String amount,
    required int required,
  }) {
    final pct =
        (approvedReportsFromInvites / required).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: neonBlue.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: neonBlue.withOpacity(0.25)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc,
              style: const TextStyle(color: Colors.white70, height: 1.35)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  AlwaysStoppedAnimation<Color>(neonBlue.withOpacity(0.9)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Progreso: $approvedReportsFromInvites / $required aprobados",
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              color: neonBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCodeBox(BuildContext context) {
    final code = userCode.isEmpty ? "SIN-CODIGO" : userCode;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neonBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            tooltip: "Copiar código",
            icon: const Icon(Icons.copy, color: neonBlue),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Código copiado")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _whatsAppButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async => _shareWhatsApp(context),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text(
          "Compartir por WhatsApp",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _legalBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: const Text(
        "⚠️ Condiciones\n\n"
        "• Las recompensas se pagan exclusivamente al usuario que invita y completa el ciclo.\n"
        "• Los invitados no reciben pagos por invitación.\n"
        "• Solo cuentan reportes válidos y aprobados por SKANO, con evidencia y verificación.\n"
        "• Intentos de fraude, suplantación o reportes falsos anulan el beneficio y pueden bloquear la cuenta.",
        style: TextStyle(color: Colors.white70, height: 1.45),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _StepRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _InviteFriendsScreenState.neonBlue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}