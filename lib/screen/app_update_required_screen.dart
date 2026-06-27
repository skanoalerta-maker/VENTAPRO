import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateRequiredScreen extends StatelessWidget {
  const AppUpdateRequiredScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color deepBg = Color(0xFF070A12);

  Future<void> _openPlayStore() async {
    final Uri url = Uri.parse(
      "https://play.google.com/store/apps/details?id=cl.skano.app",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("No se pudo abrir Google Play");
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;

    return Scaffold(
      backgroundColor: deepBg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: _GlowCircle(
              size: 260,
              color: neonBlue.withOpacity(0.22),
              shadowColor: neonBlue.withOpacity(0.35),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowCircle(
              size: 280,
              color: Colors.blueAccent.withOpacity(0.12),
              shadowColor: neonBlue.withOpacity(0.22),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmall ? 16 : 22),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    isSmall ? 18 : 22,
                    isSmall ? 24 : 30,
                    isSmall ? 18 : 22,
                    isSmall ? 20 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: neonBlue.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: neonBlue.withOpacity(0.38),
                          ),
                        ),
                        child: const Text(
                          "NUEVA VERSIÓN SKANO",
                          style: TextStyle(
                            color: neonBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        width: isSmall ? 88 : 104,
                        height: isSmall ? 88 : 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              neonBlue.withOpacity(0.42),
                              neonBlue.withOpacity(0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: isSmall ? 66 : 74,
                            height: isSmall ? 66 : 74,
                            decoration: BoxDecoration(
                              color: neonBlue.withOpacity(0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: neonBlue.withOpacity(0.8),
                              ),
                            ),
                            child: const Icon(
                              Icons.security_update_good_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Actualiza SKANO",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Tenemos mejoras importantes para que tu experiencia sea más segura, rápida y completa.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15.5,
                          height: 1.42,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const _UpdateFeature(
                        icon: Icons.document_scanner_rounded,
                        title: "Lector OCR / PPU SKANO",
                        text:
                            "Mejoras en la lectura de patentes y flujo de escaneo.",
                      ),
                      const _UpdateFeature(
                        icon: Icons.directions_walk_rounded,
                        title: "Pasos y kilómetros",
                        text:
                            "Nuevas métricas de colaboración y actividad dentro de SKANO.",
                      ),
                      const _UpdateFeature(
                        icon: Icons.dashboard_customize_rounded,
                        title: "Nueva visual de la app",
                        text:
                            "Pantallas más modernas, limpias y adaptadas a distintos celulares.",
                      ),
                      const _UpdateFeature(
                        icon: Icons.assignment_rounded,
                        title: "Mis reportes mejorado",
                        text:
                            "Mejor seguimiento visual del estado de tus reportes.",
                      ),
                      const _UpdateFeature(
                        icon: Icons.payments_rounded,
                        title: "Ganancias y pagos",
                        text:
                            "Mejoras en la pantalla de recompensas, retiros y datos bancarios.",
                      ),
                      const _UpdateFeature(
                        icon: Icons.verified_user_rounded,
                        title: "Más seguridad",
                        text:
                            "Ajustes internos para proteger mejor tu cuenta y tus reportes.",
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonBlue,
                            foregroundColor: Colors.white,
                            elevation: 14,
                            shadowColor: neonBlue.withOpacity(0.55),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _openPlayStore,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Actualizar en Google Play",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Debes actualizar para continuar usando SKANO con las últimas mejoras.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.5,
                          height: 1.35,
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

class _UpdateFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _UpdateFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.075),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppUpdateRequiredScreen.neonBlue.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppUpdateRequiredScreen.neonBlue.withOpacity(0.32),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF38BDF8),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.3,
                    height: 1.32,
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Color shadowColor;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 130,
            spreadRadius: 42,
          ),
        ],
      ),
    );
  }
}