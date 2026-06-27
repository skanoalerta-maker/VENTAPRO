import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Protocolo de Contacto con Autoridades",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- CABECERA (LEGAL/INSTITUCIONAL) ----------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _glass(),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: Color(0xFF38BDF8), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Importante: Esta sección es informativa. "
                      "SKANO no realiza llamadas telefónicas por ti ni "
                      "conecta automáticamente con Carabineros o PDI.\n\n"
                      "El contacto con autoridades es una acción personal del usuario "
                      "y solo corresponde cuando existe un reporte real y validado.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              "Cuándo corresponde contactar a Carabineros o PDI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _req(
              "1. El vehículo debe tener encargo vigente por robo (información confirmada por SKANO).",
            ),
            _req(
              "2. Debe existir un reporte válido generado dentro de SKANO (no basta con “ver un auto parecido”).",
            ),
            _req(
              "3. El vehículo debe estar en un lugar donde puedas reportar sin ponerte en riesgo.",
            ),
            _req(
              "4. Nunca persigas, enfrentes ni intervengas. Observa a distancia y reporta a la autoridad.",
            ),

            const SizedBox(height: 22),

            // ---------------- ANTI-ABUSO (EXPLÍCITO) ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _glass(),
              child: const Text(
                "⚠️ Uso indebido\n"
                "• Queda prohibido usar SKANO para bromas, amenazas o reportes falsos.\n"
                "• Si detectamos abuso, la cuenta puede ser bloqueada y enviada a revisión.\n"
                "• El mal uso contra servicios de emergencia puede tener consecuencias legales.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              "Estado del acceso",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // ---------------- “NO ES UN BOTÓN DE LLAMADA” ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x22FFFFFF)),
                color: const Color(0x331A1F2E),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Acceso condicional",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    "No hay llamada disponible desde aquí.\n"
                    "Cuando exista un reporte real y validado, SKANO podrá mostrar "
                    "un acceso específico dentro del flujo del reporte.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ---------------- CTA SEGURO (SIN LLAMADA) ----------------
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: const Center(
                child: Text(
                  "Entendido",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _req(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _glass(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF38BDF8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          )
        ],
      ),
    );
  }
}

BoxDecoration _glass() {
  return BoxDecoration(
    color: const Color(0x331A1F2E),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0x22FFFFFF)),
    boxShadow: const [
      BoxShadow(
        color: Colors.black87,
        blurRadius: 18,
        offset: Offset(0, 10),
      )
    ],
  );
}
