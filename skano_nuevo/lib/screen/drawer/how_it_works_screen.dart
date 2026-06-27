import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  static const Color bg = Color(0xFF0D0F14);
  static const Color neon = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Funcionamiento del sistema SKANO",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER PRO =================
            _header(),

            const SizedBox(height: 22),

            // ================= ETAPAS =================
            _sectionTitle("ETAPAS DEL SISTEMA"),

            _stepCard(
              step: "1",
              icon: Icons.verified_user_rounded,
              title: "Verificación obligatoria de identidad",
              desc:
                  "Todo usuario debe acreditar su identidad mediante cédula de identidad "
                  "(frontal y reverso) y validación facial anti-fraude.\n\n"
                  "La información es revisada manualmente por el equipo SKANO. "
                  "Mientras el proceso esté pendiente, el usuario no puede reportar "
                  "ni registrar vehículos.",
            ),

            _stepCard(
              step: "2",
              icon: Icons.drive_eta_rounded,
              title: "Registro de vehículos (solo titulares legítimos)",
              desc:
                  "El registro de un vehículo solo puede ser realizado por su dueño legal.\n\n"
                  "No se aceptan cartas de poder. En caso de vehículos en prenda, "
                  "solo el titular de la prenda o el representante legal de la empresa "
                  "propietaria puede efectuar el registro.\n\n"
                  "Documentación requerida:\n"
                  "• Padrón del vehículo\n"
                  "• Permiso de circulación\n"
                  "• Fotografías del vehículo\n"
                  "• Información técnica",
            ),

            _stepCard(
              step: "3",
              icon: Icons.report_rounded,
              title: "Declaración de encargo por robo",
              desc:
                  "Cuando un vehículo es sustraído, el dueño debe subir el parte policial "
                  "y antecedentes del hecho.\n\n"
                  "El equipo SKANO valida manualmente esta información y confirma el encargo "
                  "con la autoridad correspondiente.\n\n"
                  "Solo tras esta validación el vehículo queda activo como robado dentro "
                  "del sistema SKANO.",
            ),

            _stepCard(
              step: "4",
              icon: Icons.camera_alt_rounded,
              title: "Reportes de avistamiento por la comunidad",
              desc:
                  "Solo usuarios previamente verificados pueden generar reportes.\n\n"
                  "El sistema permite ingresar una patente manualmente o mediante fotografía "
                  "(lectura asistida por OCR).\n\n"
                  "Cada ingreso se compara automáticamente con la base interna de SKANO.",
            ),

            _stepCard(
              step: "5",
              icon: Icons.notifications_active_rounded,
              title: "Alertas inmediatas al propietario",
              desc:
                  "Cuando se detecta una coincidencia válida, el propietario recibe "
                  "una notificación con la ubicación, fecha, hora y evidencia asociada "
                  "al avistamiento.\n\n"
                  "SKANO no ejecuta acciones policiales ni operativas.",
            ),

            _stepCard(
              step: "6",
              icon: Icons.storage_rounded,
              title: "Base de datos interna y controlada",
              desc:
                  "SKANO no consulta bases de datos externas.\n\n"
                  "Solo los vehículos validados manualmente por el sistema "
                  "son considerados robados dentro de la plataforma.\n\n"
                  "Si un vehículo no está registrado en SKANO, no generará alertas, "
                  "aunque exista un encargo policial externo.",
            ),

            _stepCard(
              step: "7",
              icon: Icons.group_add_rounded,
              title: "Invitaciones responsables",
              desc:
                  "SKANO permite invitar personas para ampliar la red de detección.\n\n"
                  "Las invitaciones por sí solas no generan pagos automáticos.\n\n"
                  "Las recompensas monetarias se otorgan únicamente cuando los usuarios "
                  "invitados realizan reportes reales, válidos y aprobados.\n\n"
                  "El incentivo económico corresponde exclusivamente al usuario que "
                  "invita y completa el ciclo. Los invitados no reciben pagos.",
            ),

            const SizedBox(height: 26),

            // ================= LEGAL =================
            _legalBox(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neon.withOpacity(0.22)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.10),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip("Guía oficial SKANO"),
          const SizedBox(height: 12),
          const Text(
            "Plataforma nacional de detección de vehículos robados",
            style: TextStyle(
              color: neon,
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "SKANO es un sistema tecnológico de apoyo a la seguridad ciudadana. "
            "Opera mediante procesos de validación manual, controles de identidad "
            "y participación responsable de la comunidad.\n\n"
            "A continuación se describen las etapas oficiales de funcionamiento del sistema:",
            style: TextStyle(
              color: Colors.white70,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: neon.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: neon.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: neon,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: neon.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP CARD =================
  Widget _stepCard({
    required String step,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neon.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: neon.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: neon.withOpacity(0.25)),
                ),
                child: Icon(icon, color: neon, size: 26),
              ),
              const SizedBox(width: 12),

              // Step + title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ETAPA $step",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LEGAL BOX =================
  Widget _legalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.25)),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orangeAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Importante:\n\n"
              "SKANO no reemplaza la denuncia policial ni ejecuta acciones de recuperación.\n\n"
              "La plataforma actúa exclusivamente como un sistema de alerta y apoyo "
              "a la seguridad ciudadana, basado en validaciones manuales y participación responsable.\n\n"
              "El uso indebido del sistema puede derivar en sanciones y bloqueo de cuenta.",
              style: TextStyle(
                color: Colors.white70,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
