import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// =======================================================
/// SKANO DRAWER CORPORATIVO
/// Menú lateral principal de la aplicación
/// - Carga datos reales del usuario
/// - Navega a las secciones principales
/// - Maneja cierre de sesión
/// - UI premium SKANO, sobria y profesional
/// =======================================================

class SkanoDrawer extends StatelessWidget {
  /// Nombre del usuario mostrado en el header
  final String userName;

  /// Métricas
  final int correctReports;
  final int totalReports;

  const SkanoDrawer({
    super.key,
    required this.userName,
    required this.correctReports,
    required this.totalReports,
  });

  static const Color skanoBg = Color(0xFF040814);
  static const Color skanoSurface = Color(0xFF0B1220);
  static const Color skanoSurfaceSoft = Color(0xFF101827);
  static const Color skanoBlue = Color(0xFF0A6CFF);
  static const Color skanoCyan = Color(0xFF00D5FF);
  static const Color skanoGreen = Color(0xFF14F195);
  static const Color skanoGold = Color(0xFFFFC857);
  static const Color skanoOrange = Color(0xFFFF9F43);
  static const Color skanoRed = Color(0xFFFF4D5E);
  static const Color skanoMuted = Color(0xFF8EA0BD);

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data() ?? {};
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/start_gate",
      (route) => false,
    );
  }

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _verificationLabel(Map<String, dynamic> data) {
    final role = (data['role'] ?? '').toString();
    final status = (data['verification_status'] ?? '').toString();
    final reviewPending = data['reviewPending'] == true;

    if (role == 'admin' || role == 'superadmin') return 'Administrador SKANO';
    if (status == 'approved' && !reviewPending) return 'Usuario verificado';
    if (reviewPending || status == 'pending') return 'Cuenta en revisión';
    return 'Perfil SKANO';
  }

  Color _verificationColor(Map<String, dynamic> data) {
    final role = (data['role'] ?? '').toString();
    final status = (data['verification_status'] ?? '').toString();
    final reviewPending = data['reviewPending'] == true;

    if (role == 'admin' || role == 'superadmin') return skanoGold;
    if (status == 'approved' && !reviewPending) return skanoGreen;
    if (reviewPending || status == 'pending') return skanoOrange;
    return skanoCyan;
  }

  String _levelName() {
    if (correctReports >= 30) return 'ELITE';
    if (correctReports >= 10) return 'ORO';
    if (correctReports >= 6) return 'PLATA';
    return 'BRONCE';
  }

  Color _levelColor() {
    if (correctReports >= 30) return const Color(0xFFB388FF);
    if (correctReports >= 10) return skanoGold;
    if (correctReports >= 6) return const Color(0xFFBFC7D5);
    return const Color(0xFFCD7F32);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 322,
      backgroundColor: skanoBg,
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadUserData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};

            final String faceUrl = _firstNonEmpty(
              data,
              [
                'faceUrl',
                'selfieUrl',
                'selfie_url',
                'photoURL',
                'photoUrl',
                'profile_photo_url',
              ],
            );

            final verificationLabel = _verificationLabel(data);
            final verificationColor = _verificationColor(data);
            final level = _levelName();
            final levelColor = _levelColor();

            return Stack(
              children: [
                const Positioned.fill(child: _DrawerBackground()),
                Column(
                  children: [
                    _BrandTopBar(),
                    _DrawerHeaderSkano(
                      userName: userName,
                      faceUrl: faceUrl,
                      statusLabel: verificationLabel,
                      statusColor: verificationColor,
                      levelName: level,
                      levelColor: levelColor,
                      totalReports: totalReports,
                      correctReports: correctReports,
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        children: [
                          const _SectionTitle("Tu actividad"),

                          _DrawerItem(
                            icon: Icons.payments_outlined,
                            iconColor: skanoGreen,
                            title: "Ganancias y pagos",
                            subtitle: "Saldo acumulado y pagos pendientes",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/earnings");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.account_balance_outlined,
                            iconColor: const Color(0xFF4ADE80),
                            title: "Datos bancarios",
                            subtitle: "Cuenta para recibir recompensas",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/bank_account");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.workspace_premium_outlined,
                            iconColor: skanoGold,
                            title: "Premios y niveles",
                            subtitle: "Rangos, metas y beneficios SKANO",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/stats");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.receipt_long_outlined,
                            iconColor: skanoCyan,
                            title: "Historial de reportes",
                            subtitle: "Todos tus reportes enviados",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/my_reports");
                            },
                          ),

                          const _DrawerDivider(),

                          const _SectionTitle("Tu seguridad"),

                          _DrawerItem(
                            icon: Icons.directions_car_filled_outlined,
                            iconColor: skanoRed,
                            title: "Mis vehículos registrados",
                            subtitle: "Agrega o revisa tus vehículos",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/my_vehicles");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.policy_outlined,
                            iconColor: const Color(0xFFA78BFA),
                            title: "Acciones al encontrar un vehículo",
                            subtitle: "Guía segura con autoridades",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/how_it_works");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.local_police_outlined,
                            iconColor: skanoOrange,
                            title: "Emergencia 133",
                            subtitle: "Contacto inmediato y protocolo",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/emergency");
                            },
                          ),

                          const _DrawerDivider(),

                          const _SectionTitle("Mi perfil"),

                          _DrawerItem(
                            icon: Icons.person_outline,
                            iconColor: skanoBlue,
                            title: "Mi Cuenta",
                            subtitle: "Datos personales y verificación",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/my_account");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.verified_user_outlined,
                            iconColor: skanoGold,
                            title: "Mi Membresía",
                            subtitle: "Estado, plan y activación",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/my_membership");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.group_add_outlined,
                            iconColor: skanoCyan,
                            title: "Invitar amigos",
                            subtitle: "Comparte SKANO con tu comunidad",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/invite_friends");
                            },
                          ),

                          _DrawerItem(
                            icon: Icons.description_outlined,
                            iconColor: skanoMuted,
                            title: "Términos y condiciones",
                            subtitle: "Condiciones de uso de SKANO",
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, "/terms");
                            },
                          ),

                          const _DrawerDivider(),

                          _DrawerItem(
                            icon: Icons.logout_rounded,
                            iconColor: skanoRed,
                            title: "Salir de mi cuenta",
                            subtitle: "Cerrar sesión de forma segura",
                            danger: true,
                            onTap: () async {
                              Navigator.pop(context);
                              await _logout(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// =======================================================
/// COMPONENTES AUXILIARES
/// =======================================================

class _BrandTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SkanoDrawer.skanoBlue.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SkanoDrawer.skanoCyan.withOpacity(0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: SkanoDrawer.skanoBlue.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: SkanoDrawer.skanoCyan,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SKANO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  "Panel ciudadano seguro",
                  style: TextStyle(
                    color: SkanoDrawer.skanoMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
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

class _DrawerBackground extends StatelessWidget {
  const _DrawerBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071226),
            Color(0xFF040814),
            Color(0xFF02040A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -110,
            child: _Glow(
              size: 250,
              color: SkanoDrawer.skanoBlue.withOpacity(0.18),
            ),
          ),
          Positioned(
            top: 150,
            right: -150,
            child: _Glow(
              size: 220,
              color: SkanoDrawer.skanoCyan.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: _Glow(
              size: 280,
              color: SkanoDrawer.skanoGreen.withOpacity(0.055),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: CustomPaint(painter: _DrawerGridPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 125,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.55;

    const step = 42.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrawerHeaderSkano extends StatelessWidget {
  final String userName;
  final String faceUrl;
  final String statusLabel;
  final Color statusColor;
  final String levelName;
  final Color levelColor;
  final int totalReports;
  final int correctReports;

  const _DrawerHeaderSkano({
    required this.userName,
    required this.faceUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.levelName,
    required this.levelColor,
    required this.totalReports,
    required this.correctReports,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalReports <= 0
        ? 0
        : ((correctReports / totalReports) * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: SkanoDrawer.skanoSurface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SkanoDrawer.skanoCyan.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: SkanoDrawer.skanoBlue.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarSkano(faceUrl: faceUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.trim().isEmpty ? "Usuario SKANO" : userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(
                      label: statusLabel,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CompactMetric(
                    label: "Reportes",
                    value: "$totalReports",
                    color: SkanoDrawer.skanoCyan,
                  ),
                ),
                _SoftDivider(),
                Expanded(
                  child: _CompactMetric(
                    label: "Correctos",
                    value: "$correctReports",
                    color: SkanoDrawer.skanoGreen,
                  ),
                ),
                _SoftDivider(),
                Expanded(
                  child: _CompactMetric(
                    label: "Precisión",
                    value: "$accuracy%",
                    color: levelColor,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _LevelBar(
            levelName: levelName,
            levelColor: levelColor,
            correctReports: correctReports,
          ),
        ],
      ),
    );
  }
}

class _AvatarSkano extends StatelessWidget {
  final String faceUrl;

  const _AvatarSkano({required this.faceUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SkanoDrawer.skanoCyan,
            SkanoDrawer.skanoBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SkanoDrawer.skanoBlue.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: SkanoDrawer.skanoBg,
        backgroundImage: faceUrl.isNotEmpty ? NetworkImage(faceUrl) : null,
        child: faceUrl.isEmpty
            ? const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 31,
              )
            : null,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.105),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: compact ? 13.2 : 15.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SkanoDrawer.skanoMuted,
            fontSize: 10.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: Colors.white.withOpacity(0.075),
    );
  }
}

class _LevelBar extends StatelessWidget {
  final String levelName;
  final Color levelColor;
  final int correctReports;

  const _LevelBar({
    required this.levelName,
    required this.levelColor,
    required this.correctReports,
  });

  double get _progress {
    if (correctReports >= 30) return 1;
    if (correctReports >= 10) return (correctReports / 30).clamp(0, 1);
    if (correctReports >= 6) return (correctReports / 10).clamp(0, 1);
    return (correctReports / 6).clamp(0, 1);
  }

  String get _nextGoal {
    if (correctReports >= 30) return 'Nivel máximo activo';
    if (correctReports >= 10) return 'Meta ELITE: 30 reportes correctos';
    if (correctReports >= 6) return 'Meta ORO: 10 reportes correctos';
    return 'Meta PLATA: 6 reportes correctos';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.075),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: levelColor.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech_rounded,
                color: levelColor,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Nivel $levelName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                '$correctReports correctos',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: levelColor,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _nextGoal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SkanoDrawer.skanoMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 11, 5, 7),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: SkanoDrawer.skanoCyan,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: SkanoDrawer.skanoCyan.withOpacity(0.36),
                  blurRadius: 9,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: SkanoDrawer.skanoMuted,
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 13, 5, 5),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = danger ? SkanoDrawer.skanoRed : iconColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: danger
            ? SkanoDrawer.skanoRed.withOpacity(0.055)
            : SkanoDrawer.skanoSurfaceSoft.withOpacity(0.50),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: danger
              ? SkanoDrawer.skanoRed.withOpacity(0.20)
              : Colors.white.withOpacity(0.055),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          splashColor: effectiveColor.withOpacity(0.08),
          highlightColor: effectiveColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.115),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: effectiveColor.withOpacity(0.18),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: 20.5,
                  ),
                ),
                const SizedBox(width: 10.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: danger ? SkanoDrawer.skanoRed : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: danger
                              ? SkanoDrawer.skanoRed.withOpacity(0.68)
                              : SkanoDrawer.skanoMuted.withOpacity(0.82),
                          fontSize: 10.9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger
                      ? SkanoDrawer.skanoRed.withOpacity(0.70)
                      : Colors.white.withOpacity(0.28),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
