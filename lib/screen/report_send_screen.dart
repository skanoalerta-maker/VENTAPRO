import 'package:flutter/material.dart';

class ReportSendScreen extends StatelessWidget {
  const ReportSendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF07111F),
                Color(0xFF061A35),
                Color(0xFF020617),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              children: [
                const SizedBox(height: 18),

                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B5CFF).withOpacity(0.12),
                    border: Border.all(
                      color: const Color(0xFF1E90FF).withOpacity(0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007BFF).withOpacity(0.45),
                        blurRadius: 42,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF1E90FF),
                    size: 64,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Reporte enviado",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Tu reporte fue recibido correctamente por SKANO.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 16.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB020).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFFFFB020).withOpacity(0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFFB020),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "En revisión por SKANO",
                        style: TextStyle(
                          color: Color(0xFFFFC766),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _InfoCard(
                  icon: Icons.shield_rounded,
                  title: "Procedimiento seguro",
                  text:
                      "El reporte quedó registrado con la información enviada durante el protocolo.",
                ),

                const SizedBox(height: 14),

                _InfoCard(
                  icon: Icons.fact_check_rounded,
                  title: "Validación del equipo",
                  text:
                      "El equipo SKANO revisará la evidencia, ubicación y datos asociados al reporte.",
                ),

                const SizedBox(height: 14),

                _InfoCard(
                  icon: Icons.workspace_premium_rounded,
                  title: "Posible recompensa",
                  text:
                      "Si el procedimiento es validado, podrás acceder a una recompensa según las condiciones de SKANO.",
                ),

                const SizedBox(height: 34),

                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF007BFF),
                        Color(0xFF0057FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007BFF).withOpacity(0.42),
                        blurRadius: 22,
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
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      "Finalizar",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Reporta seguro que los buenos somos más.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007BFF).withOpacity(0.13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1E90FF),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 14.2,
                    height: 1.38,
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