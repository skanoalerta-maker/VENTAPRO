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
    return Scaffold(
      backgroundColor: deepBg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: neonBlue.withOpacity(0.22),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.35),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.22),
                    blurRadius: 140,
                    spreadRadius: 45,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
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
                          "SEGURIDAD SKANO",
                          style: TextStyle(
                            color: neonBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      Container(
                        width: 104,
                        height: 104,
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
                            width: 74,
                            height: 74,
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

                      const SizedBox(height: 28),

                      const Text(
                        "Actualización obligatoria",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Para continuar usando SKANO, debes instalar la última versión disponible.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: neonBlue,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Esta versión mejora la seguridad, estabilidad y protección de tus reportes.",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

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
                          label: const Text(
                            "Actualizar en Google Play",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "No podrás continuar hasta actualizar la aplicación.",
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