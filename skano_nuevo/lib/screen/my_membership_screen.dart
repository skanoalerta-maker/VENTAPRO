import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyMembershipScreen extends StatefulWidget {
  const MyMembershipScreen({super.key});

  @override
  State<MyMembershipScreen> createState() => _MyMembershipScreenState();
}

class _MyMembershipScreenState extends State<MyMembershipScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cardBg = Color(0xFF0F1724);

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'No registrada';
    final d = ts.toDate().toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  String _formatDateOnly(Timestamp? ts) {
    if (ts == null) return 'No registrada';
    final d = ts.toDate().toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  Color _statusColor(bool active, String status) {
    if (active) return Colors.greenAccent;
    if (status == 'pending') return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _statusText(bool active, String status) {
    if (active) return 'Membresía activa';
    if (status == 'pending') return 'Pago en proceso';
    return 'Membresía inactiva';
  }

  String _planText(String plan) {
    switch (plan) {
      case 'owner_monthly':
      case 'mensual':
        return 'Plan Dueño';
      case 'company':
        return 'Plan Empresa';
      default:
        return 'Sin plan activo';
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: neonBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.circle,
              color: Colors.transparent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _statusCard({
    required bool active,
    required String status,
    required String plan,
    required Timestamp? paidAt,
    required Timestamp? until,
    required Timestamp? updatedAt,
  }) {
    final color = _statusColor(active, status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  active
                      ? Icons.verified_rounded
                      : status == 'pending'
                          ? Icons.hourglass_top_rounded
                          : Icons.lock_outline_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText(active, status),
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _planText(plan),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 18),
          _infoRow(
            icon: Icons.payments_outlined,
            label: 'Último pago registrado',
            value: _formatTimestamp(paidAt),
            valueColor: paidAt != null ? Colors.white : Colors.white54,
          ),
          _infoRow(
            icon: Icons.event_available_rounded,
            label: 'Vigencia hasta',
            value: _formatDateOnly(until),
            valueColor: until != null ? Colors.white : Colors.white54,
          ),
          _infoRow(
            icon: Icons.update_rounded,
            label: 'Última actualización',
            value: _formatTimestamp(updatedAt),
            valueColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cobertura del plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _BenefitItem(text: 'Activación del vehículo en el sistema'),
          _BenefitItem(text: 'Encargo por robo visible en la plataforma'),
          _BenefitItem(text: 'Recepción de reportes de usuarios'),
          _BenefitItem(text: 'Seguimiento operativo del vehículo'),
          _BenefitItem(text: 'Soporte y gestión dentro de SKANO'),
        ],
      ),
    );
  }

  Widget _inactiveInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1010),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importante',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Esta pantalla es solo informativa. La activación de la membresía se realiza únicamente dentro del flujo correspondiente al registrar o activar un vehículo robado.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 20),
      child: Text(
        'La información mostrada aquí corresponde al estado actual de tu membresía en SKANO.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Debes iniciar sesión',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi Membresía',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          final data = (snap.data!.data() as Map<String, dynamic>?) ?? {};

          final bool active = data['membership_active'] == true;
          final String status = (data['membership_status'] ?? 'inactive').toString();
          final String plan = (data['membership_plan'] ?? 'free').toString();

          final Timestamp? paidAt = data['membership_paid_at'] as Timestamp?;
          final Timestamp? until = data['membership_until'] as Timestamp?;
          final Timestamp? updatedAt = data['updated_at'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/skano_logo.png',
                        height: 54,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Estado actual de tu membresía',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aquí puedes revisar si tu plan está activo, cuándo se registró el último pago y hasta cuándo se mantiene vigente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _statusCard(
                  active: active,
                  status: status,
                  plan: plan,
                  paidAt: paidAt,
                  until: until,
                  updatedAt: updatedAt,
                ),
                const SizedBox(height: 18),
                _benefitsCard(),
                const SizedBox(height: 18),
                if (!active) _inactiveInfoCard(),
                _footer(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;
  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}