import 'package:flutter/material.dart';

class ResponsibleAccessScreen extends StatelessWidget {
  const ResponsibleAccessScreen({super.key});

  static const Color bgTop = Color(0xFF07091F);
  static const Color bgBottom = Color(0xFF000000);
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cardColor = Color(0xFF101827);
  static const Color softCard = Color(0xFF0B1220);

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgBottom,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgTop,
                Color(0xFF030712),
                bgBottom,
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -90,
                right: -70,
                child: _GlowCircle(size: 210, opacity: 0.20),
              ),
              const Positioned(
                bottom: 90,
                left: -95,
                child: _GlowCircle(size: 190, opacity: 0.13),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 22, 24, 20 + safeBottom),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _logoHeader(),
                        const SizedBox(height: 24),
                        _mainCard(),
                        const SizedBox(height: 20),
                        _securityPoints(),
                        const SizedBox(height: 26),
                        _continueButton(context),
                        const SizedBox(height: 16),
                        const Text(
                          'Detecta • Reporta • Protege',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Control automático de seguridad SKANO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoHeader() {
    return Column(
      children: [
        Container(
          width: 122,
          height: 122,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: neonBlue.withOpacity(0.35), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: neonBlue.withOpacity(0.38),
                blurRadius: 38,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/skano_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shield_outlined,
              size: 68,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'REINGRESO SEGURO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: neonBlue.withOpacity(0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: neonBlue.withOpacity(0.30)),
          ),
          child: const Text(
            'SKANO protegió tu sesión por inactividad',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFBFD8FF),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: neonBlue.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: neonBlue.withOpacity(0.28)),
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  color: neonBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Detectamos un periodo de inactividad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Estuviste fuera de la aplicación durante algunos minutos. Antes de continuar, SKANO necesita confirmar que eres tú quien retoma el acceso.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1208).withOpacity(0.70),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.30)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este control ayuda a prevenir reportes accidentales, accesos no autorizados y uso involuntario de la plataforma.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityPoints() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softCard.withOpacity(0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        children: [
          _PointRow(
            icon: Icons.verified_user_outlined,
            text: 'Confirma acceso responsable antes de reportar.',
          ),
          SizedBox(height: 12),
          _PointRow(
            icon: Icons.touch_app_outlined,
            text: 'Evita acciones involuntarias al volver a la app.',
          ),
          SizedBox(height: 12),
          _PointRow(
            icon: Icons.groups_2_outlined,
            text: 'Protege la seguridad de la comunidad SKANO.',
          ),
        ],
      ),
    );
  }

  Widget _continueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A6CFF),
              Color(0xFF4A8DFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.42),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CONTINUAR EN SKANO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const Color neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: neonBlue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: neonBlue.withOpacity(0.20)),
          ),
          child: Icon(icon, color: neonBlue, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.8,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A6CFF).withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A6CFF).withOpacity(opacity),
              blurRadius: 90,
              spreadRadius: 35,
            ),
          ],
        ),
      ),
    );
  }
}
