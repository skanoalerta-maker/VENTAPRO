import 'package:flutter/material.dart';

class ResponsibleAccessScreen extends StatelessWidget {
  const ResponsibleAccessScreen({super.key});

  static const Color bg = Color(0xFF0D0F14);
  static const Color neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ================= ICON / LOGO =================
                  Image.asset(
                    "assets/img/skano_logo.png",
                    height: 92,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shield_outlined,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "SKANO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Reingreso seguro a la plataforma",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // ================= INFO BOX =================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121724),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detectamos un periodo de inactividad",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Estuviste fuera de la aplicación durante algunos minutos.\n\n"
                          "Por seguridad y uso responsable, SKANO requiere confirmar "
                          "tu intención de continuar antes de retomar el acceso.\n\n"
                          "Este control ayuda a prevenir usos accidentales, accesos no "
                          "autorizados y reportes involuntarios.",
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ================= ACTION =================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "CONTINUAR DE FORMA RESPONSABLE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= FOOTER =================
                  const Text(
                    "Control automático de seguridad",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
