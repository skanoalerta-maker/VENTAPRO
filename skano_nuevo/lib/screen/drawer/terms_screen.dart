import 'dart:ui';
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const Color bg0 = Color(0xFF070A12);
  static const Color bg1 = Color(0xFF0B1020);
  static const Color neon = Color(0xFF0A6CFF);
  static const Color neonCyan = Color(0xFF38BDF8);
  static const Color neonPurple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg0,
      body: Stack(
        children: [
          // ================= BACKGROUND (NEON BLOBS) =================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [bg0, bg1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // blobs
          Positioned(
            top: -120,
            left: -90,
            child: _blob(neon, 260, 0.22),
          ),
          Positioned(
            top: 80,
            right: -120,
            child: _blob(neonPurple, 280, 0.18),
          ),
          Positioned(
            bottom: -140,
            left: 40,
            child: _blob(neonCyan, 300, 0.16),
          ),

          // blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ================= HEADER =================
                _topBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroDoc(),

                        const SizedBox(height: 18),

                        _section(
                          n: "01",
                          title: "Naturaleza del servicio",
                          body:
                              "SKANO es una plataforma tecnológica de aviso ciudadano para reportes "
                              "informativos sobre vehículos con encargo por robo.\n\n"
                              "SKANO NO es institución policial, NO es empresa de seguridad privada, "
                              "ni realiza recuperación de vehículos.\n\n"
                              "La aplicación funciona como intermediario tecnológico de información.",
                        ),

                        _section(
                          n: "02",
                          title: "Uso responsable",
                          body:
                              "El uso es voluntario y bajo exclusiva responsabilidad del usuario.\n\n"
                              "SKANO no incentiva persecuciones ni confrontaciones. Mantén distancia "
                              "segura y prioriza tu integridad.\n\n"
                              "Cualquier acción fuera de la plataforma es decisión personal del usuario.",
                        ),

                        _section(
                          n: "03",
                          title: "Requisito de edad",
                          body:
                              "La aplicación está destinada exclusivamente a mayores de 18 años.\n\n"
                              "Al registrarte declaras cumplir este requisito legal.",
                        ),

                        _section(
                          n: "04",
                          title: "Protección de datos",
                          body:
                              "SKANO aplica medidas técnicas razonables para proteger la información.\n\n"
                              "Los datos no son públicos y solo se entregarán a autoridades competentes "
                              "cuando exista obligación legal válida (Ley N° 19.628).",
                        ),

                        _section(
                          n: "05",
                          title: "Cero tolerancia a reportes falsos",
                          body:
                              "Queda estrictamente prohibido generar reportes falsos, manipulados o "
                              "maliciosos.\n\n"
                              "Esto puede derivar en bloqueo temporal o permanente, pérdida de recompensas "
                              "y eventuales responsabilidades legales.",
                        ),

                        const SizedBox(height: 18),

                        _finalCard(),

                        const SizedBox(height: 10),
                      ],
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

  // ================= TOP BAR =================
  Widget _topBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        border: Border(
          bottom: BorderSide(color: neon.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: neon.withOpacity(0.22)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Términos y Condiciones",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  neon.withOpacity(0.20),
                  neonCyan.withOpacity(0.14),
                ],
              ),
              border: Border.all(color: neon.withOpacity(0.25)),
            ),
            child: const Text(
              "LEGAL",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HERO =================
  Widget _heroDoc() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _neonCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _glowIcon(Icons.shield_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Documento Oficial de Uso",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Última actualización: Febrero 2026\n"
            "Este documento regula el uso responsable de la plataforma SKANO.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  neon.withOpacity(0.18),
                  neonPurple.withOpacity(0.10),
                ],
              ),
              border: Border.all(color: neon.withOpacity(0.25)),
            ),
            child: const Text(
              "SKANO no es Carabineros ni PDI, y no reemplaza a las autoridades. "
              "Es una herramienta tecnológica de aviso ciudadano.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION =================
  Widget _section({
    required String n,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _neonCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _numChip(n),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          _dividerGlow(),
        ],
      ),
    );
  }

  // ================= FINAL =================
  Widget _finalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            neon.withOpacity(0.22),
            neonCyan.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: neon.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Text(
        "El uso de SKANO implica la aceptación íntegra de estos Términos y Condiciones.\n\n"
        "Si no estás de acuerdo, no uses la plataforma.",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _numChip(String n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            neon.withOpacity(0.28),
            neonPurple.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: neon.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        n,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _dividerGlow() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: [
            neon.withOpacity(0.0),
            neon.withOpacity(0.55),
            neonCyan.withOpacity(0.55),
            neon.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _glowIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            neon.withOpacity(0.22),
            neonCyan.withOpacity(0.14),
          ],
        ),
        border: Border.all(color: neon.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  BoxDecoration _neonCard() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withOpacity(0.05),
      border: Border.all(color: neon.withOpacity(0.22)),
      boxShadow: [
        BoxShadow(
          color: neon.withOpacity(0.10),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  Widget _blob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}
