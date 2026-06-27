import 'package:flutter/material.dart';

class MembershipTermsScreen extends StatelessWidget {
  const MembershipTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Términos de Venta y Membresía"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SKANO — Términos de Venta y Membresía",
              style: TextStyle(
                color: neonBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Versión: 1.0 — Vigencia: 2026-02-17",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 20),

            _sectionTitle("1. Objeto del servicio"),
            _sectionText(
              "SKANO ofrece planes de membresía que permiten a los usuarios registrar vehículos, "
              "activar funcionalidades de visibilidad y alertas, recibir notificaciones comunitarias, "
              "y acceder a herramientas tecnológicas vinculadas a reportes asociados a vehículos con encargo.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("2. Naturaleza del servicio (plataforma tecnológica)"),
            _sectionText(
              "SKANO es una plataforma tecnológica de apoyo comunitario. "
              "SKANO NO es una aseguradora, NO es una empresa de seguridad privada, "
              "NO es una entidad policial ni presta servicios de vigilancia o custodia. "
              "El uso de SKANO no garantiza la recuperación de un vehículo ni la prevención total de delitos.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("3. Requisitos de uso y elegibilidad"),
            _sectionText(
              "Para contratar o mantener una membresía activa, SKANO puede exigir verificación de identidad, "
              "documentos del vehículo y validaciones administrativas. "
              "El usuario declara que la información entregada es veraz, vigente y corresponde a su persona y/o vehículo.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("4. Planes y precios"),
            _sectionText(
              "Los planes, características y precios se informan dentro de la aplicación y pueden variar "
              "según tipo de usuario (persona natural, empresa u otras categorías). "
              "Todos los valores se expresan en pesos chilenos (CLP) salvo indicación distinta en la app.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("5. Proceso de pago (plataforma externa)"),
            _sectionText(
              "Los pagos se realizan mediante plataformas externas habilitadas por SKANO (por ejemplo, proveedores de pago). "
              "SKANO no almacena datos de tarjetas ni credenciales bancarias asociadas al pago. "
              "Cualquier validación, confirmación o reversa del pago depende del proveedor de pago y su normativa.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("6. Activación de la membresía"),
            _sectionText(
              "El pago de una membresía NO implica activación inmediata. "
              "La activación queda sujeta a verificación de identidad, revisión de documentos, "
              "validación administrativa y confirmación del pago mediante los mecanismos técnicos correspondientes "
              "(por ejemplo, webhook/confirmación del proveedor). "
              "Hasta completar lo anterior, el vehículo puede quedar en estado no activo o con funciones limitadas.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("7. Vigencia, renovación y expiración"),
            _sectionText(
              "La membresía tiene la duración indicada al momento de la contratación. "
              "Finalizado el período, el servicio se desactiva automáticamente si no se renueva. "
              "SKANO puede notificar recordatorios, pero el usuario es responsable de revisar la vigencia de su membresía.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("8. Cancelaciones"),
            _sectionText(
              "El usuario puede solicitar la cancelación de su membresía en cualquier momento. "
              "La cancelación detiene renovaciones futuras y/o el acceso a beneficios, según corresponda. "
              "La cancelación no genera reembolso por períodos ya iniciados, salvo obligación legal aplicable.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("9. Reembolsos"),
            _sectionText(
              "Como regla general, SKANO no realiza reembolsos por períodos ya iniciados. "
              "Podrán existir excepciones por errores verificables o situaciones obligadas por normativa vigente "
              "(por ejemplo, cuando corresponda según ley del consumidor u otras disposiciones aplicables).",
            ),

            const SizedBox(height: 20),

            _sectionTitle("10. Uso responsable, comunidad y reportes"),
            _sectionText(
              "El usuario se obliga a utilizar SKANO de forma responsable, sin abuso, sin suplantación de identidad, "
              "sin entrega de antecedentes falsos y sin intentar manipular el sistema de reportes o recompensas. "
              "Cualquier uso malicioso, fraudulento o que afecte la seguridad de terceros puede derivar en suspensión.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("11. Suspensión, bloqueo o término de la membresía"),
            _sectionText(
              "SKANO podrá suspender, bloquear o cancelar una membresía (incluso pagada) en caso de: "
              "fraude, uso indebido, intentos de evasión de controles, suplantación de identidad, "
              "entrega de información falsa, reportes abusivos o incumplimiento de estos términos. "
              "Los bloqueos por seguridad pueden ser temporales o requerir revisión manual.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("12. Limitación de responsabilidad"),
            _sectionText(
              "SKANO no responde por: (a) fallas de internet, GPS, telefonía o dispositivos del usuario; "
              "(b) caídas o demoras de servicios de terceros (incluyendo proveedores de pago); "
              "(c) acciones u omisiones de terceros o autoridades; (d) decisiones operativas del usuario. "
              "SKANO entrega información y alertas como apoyo tecnológico, sin garantizar resultados.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("13. Responsabilidad por datos entregados por el usuario"),
            _sectionText(
              "El usuario es el único responsable por la exactitud de los datos que registra en SKANO "
              "(por ejemplo: datos del vehículo, identidad, y cualquier dato asociado a su cuenta). "
              "Si el usuario ingresa información errónea o incompleta, SKANO no será responsable por consecuencias "
              "derivadas de dicha información.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("14. Relación con autoridades"),
            _sectionText(
              "La membresía no reemplaza seguros, denuncias ni acciones ante Carabineros u otras autoridades. "
              "Ante una situación de riesgo, el usuario debe contactar a las autoridades competentes "
              "y priorizar su seguridad personal.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("15. Modificaciones de términos"),
            _sectionText(
              "SKANO puede actualizar estos términos para mejorar el servicio, reforzar seguridad o cumplir normativa. "
              "Las modificaciones se informarán mediante la app o canales oficiales. "
              "El uso continuo del servicio luego de la actualización implica aceptación de la versión vigente.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("16. Soporte y contacto"),
            _sectionText(
              "Para consultas o soporte, el usuario debe utilizar los canales oficiales informados dentro de la aplicación "
              "o en el sitio web oficial de SKANO. "
              "SKANO podrá solicitar antecedentes para validar identidad antes de realizar cambios sensibles.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("17. Aceptación"),
            _sectionText(
              "Al contratar y pagar una membresía, el usuario declara haber leído, comprendido y aceptado íntegramente "
              "estos Términos de Venta y Membresía.",
            ),

            const SizedBox(height: 20),

            _sectionTitle("18. Legislación aplicable"),
            _sectionText(
              "Estos términos se rigen por las leyes de la República de Chile. "
              "Cualquier controversia se someterá a los tribunales competentes, salvo normas especiales aplicables.",
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2026 SKANO — Todos los derechos reservados",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }
}
