import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================================
/// 📄 Archivo: terms_info_screen.dart
/// ✅ UI más “premium” (cards + acordeones + jerarquía)
/// ✅ Blindaje real: registra aceptación (version + timestamp) en Firestore
/// ✅ Incluye: permisos/privacidad, abuso/falsos reportes, contacto/soporte
/// ============================================================================

class TermsInfoScreen extends StatefulWidget {
  const TermsInfoScreen({super.key});

  @override
  State<TermsInfoScreen> createState() => _TermsInfoScreenState();
}

class _TermsInfoScreenState extends State<TermsInfoScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bg = Colors.black;
  static const Color card = Color(0xFF0B1220);

  // Cambia versión cuando edites el texto (sirve para auditoría)
  static const String termsVersion = "v1.0";

  bool _understood = false;
  bool _saving = false;
  String? _saveError;

  Future<void> _persistAcceptance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "termsAccepted": true,
      "termsVersion": termsVersion,
      "termsAcceptedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _acceptAndClose() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _persistAcceptance();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = e.toString());
      _snack("No se pudo registrar la aceptación. Reintenta.", isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1F2937),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Términos, Riesgos y Uso Seguro"),
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(),
                  const SizedBox(height: 14),

                  _sectionCard(
                    title: "Resumen esencial",
                    icon: Icons.gpp_good_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paragraph(
                          "SKANO es una plataforma tecnológica de información comunitaria. "
                          "No reemplaza a autoridades, no opera en terreno y no coordina operativos.",
                        ),
                        const SizedBox(height: 10),
                        _bullets(const [
                          "No confrontes ni persigas a terceros.",
                          "Si existe riesgo, aléjate y prioriza tu seguridad.",
                          "En caso de emergencia, llama tú mismo a Carabineros (133).",
                          "Los reportes y evidencias pueden revisarse manualmente.",
                        ]),
                      ],
                    ),
                  ),

                  _sectionCard(
                    title: "Conducta prohibida",
                    icon: Icons.block_outlined,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0B0B).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                      ),
                      child: _bullets(const [
                        "Perseguir, interceptar o confrontar personas.",
                        "Intentar recuperar el vehículo por cuenta propia.",
                        "Publicar datos sensibles (RUT, dirección exacta, rostros de terceros).",
                        "Hacer reportes falsos, maliciosos o con evidencia adulterada.",
                      ]),
                    ),
                  ),

                  _accordion(
                    title: "1) Aceptación expresa e informada",
                    icon: Icons.check_circle_outline,
                    content: _paragraph(
                      "Al utilizar SKANO, declaras que comprendes la naturaleza del servicio "
                      "y aceptas estos términos de forma voluntaria e informada. "
                      "Si no estás de acuerdo, debes dejar de usar la aplicación.",
                    ),
                  ),

                  _accordion(
                    title: "2) Naturaleza del servicio (cláusula esencial)",
                    icon: Icons.info_outline,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paragraph(
                          "SKANO es EXCLUSIVAMENTE una plataforma tecnológica de información comunitaria.",
                        ),
                        const SizedBox(height: 8),
                        _bullets(const [
                          "SKANO NO es policía.",
                          "SKANO NO es empresa de seguridad privada.",
                          "SKANO NO presta servicios de vigilancia.",
                          "SKANO NO recupera vehículos ni persigue personas.",
                          "SKANO NO coordina operativos en terreno.",
                        ]),
                      ],
                    ),
                  ),

                  _accordion(
                    title: "3) Autoridades y emergencias",
                    icon: Icons.local_police_outlined,
                    content: _paragraph(
                      "SKANO no contacta autoridades ni servicios de emergencia. "
                      "Cualquier denuncia o llamada se realiza por decisión del usuario, "
                      "desde su propio dispositivo y bajo su responsabilidad. "
                      "Ante riesgo inmediato, llama a Carabineros (133).",
                    ),
                  ),

                  _accordion(
                    title: "4) Reportes, evidencias e información de usuarios",
                    icon: Icons.photo_camera_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paragraph(
                          "Los reportes (texto, fotos, ubicaciones) son contenido generado por usuarios. "
                          "SKANO no garantiza veracidad, exactitud o actualidad de dicha información.",
                        ),
                        const SizedBox(height: 8),
                        _paragraph(
                          "La información en la app no constituye denuncia oficial ni antecedente pericial.",
                        ),
                      ],
                    ),
                  ),

                  _accordion(
                    title: "Permisos (cámara/ubicación) y privacidad",
                    icon: Icons.privacy_tip_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paragraph(
                          "La app puede solicitar permisos de cámara y ubicación. "
                          "Se utilizan para generar evidencia del reporte y apoyar la verificación.",
                        ),
                        const SizedBox(height: 8),
                        _bullets(const [
                          "La ubicación queda asociada al reporte enviado.",
                          "Las fotos se almacenan como evidencia y pueden revisarse por administración.",
                          "Los registros se entregan solo ante requerimiento legal válido.",
                        ]),
                      ],
                    ),
                  ),

                  _accordion(
                    title: "Falsos reportes y abuso",
                    icon: Icons.report_gmailerrorred_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _paragraph(
                          "Para proteger a la comunidad, SKANO puede aplicar medidas ante abuso "
                          "o reportes falsos.",
                        ),
                        const SizedBox(height: 8),
                        _bullets(const [
                          "Bloqueo temporal o permanente de la cuenta.",
                          "Revisión manual y solicitud de evidencia adicional.",
                          "Anulación de recompensas si se detecta fraude.",
                        ]),
                      ],
                    ),
                  ),

                  _accordion(
                    title: "Limitación de responsabilidad",
                    icon: Icons.shield_outlined,
                    content: _paragraph(
                      "SKANO y sus administradores no son responsables por daños físicos, materiales, "
                      "pérdidas económicas, consecuencias legales o acciones de terceros derivadas "
                      "de decisiones o conductas del usuario. El uso es bajo exclusiva responsabilidad del usuario.",
                    ),
                  ),

                  _accordion(
                    title: "Ley aplicable y jurisdicción",
                    icon: Icons.gavel_outlined,
                    content: _paragraph(
                      "Este acuerdo se rige por las leyes de la República de Chile. "
                      "Cualquier controversia será conocida por los tribunales ordinarios de justicia de Chile.",
                    ),
                  ),

                  _sectionCard(
                    title: "Soporte y contacto",
                    icon: Icons.support_agent_outlined,
                    child: _paragraph(
                      "Soporte oficial: contacto@skano.cl\n"
                      "Sitio: www.skano.cl\n"
                      "Ante riesgo inmediato: Carabineros (133).",
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      "Documento: $termsVersion",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),

                  if (_saveError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0B0B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                      ),
                      child: Text(
                        _saveError!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.25),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // =========================
          // Bottom acceptance bar
          // =========================
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + safeBottom),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F14),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _understood,
                      activeColor: neonBlue,
                      checkColor: Colors.black,
                      onChanged: (v) => setState(() => _understood = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        "Entiendo y acepto que el uso es bajo mi exclusiva responsabilidad.",
                        style: TextStyle(color: Colors.white70, height: 1.25),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _understood ? neonBlue : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _understood && !_saving ? _acceptAndClose : null,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                          )
                        : const Text(
                            "ACEPTO Y CONTINUAR",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
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

  // =========================
  // UI Blocks
  // =========================

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A6CFF), Color(0xFF7C4DFF)],
        ),
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
        children: const [
          Text(
            "SKANO — Términos y uso seguro",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Lee esto antes de reportar. Tu seguridad está primero.",
            style: TextStyle(color: Colors.white70, height: 1.25),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: neonBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _accordion({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white60,
          iconColor: Colors.white60,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Icon(icon, color: neonBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          children: [content],
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.45),
    );
  }

  Widget _bullets(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("•  ", style: TextStyle(color: Colors.white70, height: 1.45)),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
