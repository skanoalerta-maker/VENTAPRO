import 'dart:math' as math;
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController logoController;
  late final AnimationController fadeController;
  late final AnimationController backgroundController;

  late final Animation<double> logoScale;
  late final Animation<double> fadeIn;
  late final Animation<Offset> slideUp;

  static const Color bgDeep = Color(0xFF02030A);
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF1DEBFF);

  bool _small(BuildContext context) =>
      MediaQuery.of(context).size.width < 370;

  bool _short(BuildContext context) =>
      MediaQuery.of(context).size.height < 680;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    logoScale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: logoController, curve: Curves.easeInOut),
    );

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeIn = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );

    slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeOutCubic),
    );

    backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    fadeController.forward();
  }

  @override
  void dispose() {
    logoController.dispose();
    fadeController.dispose();
    backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final small = _small(context);
    final short = _short(context);

    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          const _GradientBackground(),
          AnimatedBuilder(
            animation: backgroundController,
            builder: (_, __) => CustomPaint(
              painter: _TechGridPainter(
                progress: backgroundController.value,
                color: neonBlue,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: -size.width * 0.30,
            right: -size.width * 0.32,
            child: _GlowOrb(
              size: size.width * 0.82,
              color: neonBlue.withOpacity(0.26),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.28,
            left: -size.width * 0.32,
            child: _GlowOrb(
              size: size.width * 0.74,
              color: cyan.withOpacity(0.13),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(
                position: slideUp,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    small ? 18 : 24,
                    small ? 12 : 18,
                    small ? 18 : 24,
                    14 + bottomSafe,
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: _StatusPill(),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScaleTransition(
                                  scale: logoScale,
                                  child: _LogoBadge(
                                    child: Image.asset(
                                      'assets/images/skano_logo.png',
                                      width: small ? 140 : short ? 155 : 180,
                                      height: small ? 140 : short ? 155 : 180,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(height: small ? 18 : 28),
                                Text(
                                  'SKANO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: small ? 34 : short ? 40 : 46,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: small ? 2.4 : 3.2,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 24,
                                        color: neonBlue,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: small ? 9 : 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: small ? 11 : 14,
                                    vertical: small ? 6 : 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                                  child: Text(
                                    'Detecta • Reporta • Protege',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: small ? 12 : 13.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                SizedBox(height: small ? 16 : 22),
                                Text(
                                  'La comunidad chilena ayudando a detectar\nvehículos con encargo por robo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: small ? 15 : 18,
                                    color: Colors.white70,
                                    height: 1.38,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: small ? 18 : 24),
                                const _FeatureStrip(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _NeonButton(
                        label: 'CREAR CUENTA',
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () => Navigator.pushNamed(context, '/register'),
                      ),
                      SizedBox(height: small ? 10 : 14),
                      _OutlinedNeonButton(
                        label: 'YA TENGO CUENTA',
                        icon: Icons.login_rounded,
                        onTap: () => Navigator.pushNamed(context, '/login'),
                      ),
                      SizedBox(height: small ? 10 : 16),
                      Text(
                        'Plataforma ciudadana de colaboración informativa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: small ? 11.5 : 12.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF07142F),
            Color(0xFF050814),
            Color(0xFF02030A),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final small = width < 370;
    final short = height < 680;

    final badgeSize = small ? 170.0 : short ? 185.0 : 210.0;

    return Container(
      width: badgeSize,
      height: badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.035),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A6CFF).withOpacity(0.55),
            blurRadius: small ? 32 : 42,
            spreadRadius: small ? 2 : 4,
          ),
          BoxShadow(
            color: const Color(0xFF1DEBFF).withOpacity(0.12),
            blurRadius: small ? 55 : 75,
            spreadRadius: small ? 10 : 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 370;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            color: const Color(0xFF1DEBFF),
            size: small ? 15 : 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Seguridad comunitaria',
            style: TextStyle(
              color: Colors.white70,
              fontSize: small ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 330;

        if (small) {
          return const Column(
            children: [
              _MiniFeature(
                icon: Icons.location_on_outlined,
                label: 'Alertas comunitarias',
              ),
              SizedBox(height: 8),
              _MiniFeature(
                icon: Icons.directions_car_filled_outlined,
                label: 'Vehículos registrados',
              ),
              SizedBox(height: 8),
              _MiniFeature(
                icon: Icons.verified_user_outlined,
                label: 'Uso seguro',
              ),
            ],
          );
        }

        return const Row(
          children: [
            Expanded(
              child: _MiniFeature(
                icon: Icons.location_on_outlined,
                label: 'Alertas\ncomunitarias',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniFeature(
                icon: Icons.directions_car_filled_outlined,
                label: 'Vehículos\nregistrados',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniFeature(
                icon: Icons.verified_user_outlined,
                label: 'Uso\nseguro',
              ),
            ),
          ],
        );
      },
    );
  }
}
class _MiniFeature extends StatelessWidget {
  const _MiniFeature({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 370;
    final compactRow = MediaQuery.of(context).size.width < 330;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compactRow ? 58 : small ? 76 : 86,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10,
          vertical: compactRow ? 9 : small ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        child: compactRow
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF0A6CFF),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF0A6CFF),
                    size: small ? 20 : 23,
                  ),
                  SizedBox(height: small ? 6 : 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: small ? 11 : 12.5,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 370;

    return SizedBox(
      width: double.infinity,
      height: small ? 52 : 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(small ? 16 : 18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A6CFF), Color(0xFF1DEBFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A6CFF).withOpacity(0.42),
              blurRadius: small ? 20 : 28,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.black, size: small ? 19 : 21),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: small ? 14.5 : 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(small ? 16 : 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedNeonButton extends StatelessWidget {
  const _OutlinedNeonButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 370;

    return SizedBox(
      width: double.infinity,
      height: small ? 52 : 58,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: const Color(0xFF1DEBFF),
          size: small ? 19 : 21,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF1DEBFF),
            fontSize: small ? 14.5 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.16), width: 1.4),
          backgroundColor: Colors.white.withOpacity(0.045),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(small ? 16 : 18),
          ),
        ),
      ),
    );
  }
}

class _TechGridPainter extends CustomPainter {
  _TechGridPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.055)
      ..strokeWidth = 1;

    const spacing = 42.0;
    final dy = progress * spacing;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y + dy), Offset(size.width, y + dy), paint);
    }

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final ringPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.5, size.height * 0.33);

    for (int i = 0; i < 3; i++) {
      final radius = 115.0 + (i * 42) + math.sin(progress * math.pi * 2) * 4;
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TechGridPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}