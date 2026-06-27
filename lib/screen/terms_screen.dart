import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================================
/// 📄 Archivo: terms_info_screen.dart
/// ✅ UI premium SKANO: fondo degradado, hero, cards, acordeones y botón glow
/// ✅ Registra aceptación real en Firestore: termsAccepted + version + timestamp
/// ✅ Mantiene seguridad: checkbox obligatorio + estado de carga + manejo de error
/// ============================================================================

class TermsInfoScreen extends StatefulWidget {
  const TermsInfoScreen({super.key});

  @override
  State<TermsInfoScreen> createState() => _TermsInfoScreenState();
}

class _TermsInfoScreenState extends State<TermsInfoScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color electricBlue = Color(0xFF38BDF8);
  static const Color bgDark = Color(0xFF05070D);
  static const Color bgCard = Color(0xFF0B1220);
  static const Color bgCardSoft = Color(0xFF101827);

  // Cambia esta versión cuando edites legalmente el contenido.
  static const String termsVersion = "v1.0";

  bool _understood = false;
  bool _saving = false;
  String? _saveError;

  final Set<int> _openedSections = {};
  static const int _totalExpandableSections = 8;

  double get _readProgress {
    if (_totalExpandableSections == 0) return 0;
    final value = _openedSections.length / _totalExpandableSections;
    return value.clamp(0.0, 1.0);
  }

  Future<void> _persistAcceptance() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      throw Exception("No hay usuario autenticado.");
    }

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "email": user?.email,
      "termsAccepted": true,
      "termsVersion": termsVersion,
      "termsAcceptedAt": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _acceptAndClose() async {
    if (_saving || !_understood) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _persistAcceptance();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text("✅ Términos aceptados correctamente."),
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = "Firebase: ${e.code} — ${e.message ?? 'Error desconocido'}";
      setState(() => _saveError = msg);
      _snack("No se pudo registrar la aceptación. Reintenta.", isError: true);
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
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          "Uso seguro SKANO",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071126),
              Color(0xFF05070D),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(),
                    const SizedBox(height: 14),
                    _progressCard(),
                    const SizedBox(height: 14),
                    _dangerNotice(),
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
                          const SizedBox(height: 12),
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
                      accentColor: Colors.redAccent,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A0B0B).withOpacity(0.62),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.38),
                          ),
                        ),
                        child: _bullets(const [
                          "Perseguir, interceptar o confrontar personas.",
                          "Intentar recuperar el vehículo por cuenta propia.",
                          "Publicar datos sensibles como RUT, dirección exacta o rostros de terceros.",
                          "Hacer reportes falsos, maliciosos o con evidencia adulterada.",
                        ]),
                      ),
                    ),

                    _accordion(
                      index: 0,
                      title: "1) Aceptación expresa e informada",
                      icon: Icons.check_circle_outline,
                      content: _paragraph(
                        "Al utilizar SKANO, declaras que comprendes la naturaleza del servicio "
                        "y aceptas estos términos de forma voluntaria e informada. "
                        "Si no estás de acuerdo, debes dejar de usar la aplicación.",
                      ),
                    ),

                    _accordion(
                      index: 1,
                      title: "2) Naturaleza del servicio",
                      icon: Icons.info_outline,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paragraph(
                            "SKANO es exclusivamente una plataforma tecnológica de información comunitaria.",
                          ),
                          const SizedBox(height: 10),
                          _bullets(const [
                            "SKANO no es policía.",
                            "SKANO no es empresa de seguridad privada.",
                            "SKANO no presta servicios de vigilancia.",
                            "SKANO no recupera vehículos ni persigue personas.",
                            "SKANO no coordina operativos en terreno.",
                          ]),
                        ],
                      ),
                    ),

                    _accordion(
                      index: 2,
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
                      index: 3,
                      title: "4) Reportes, evidencias e información",
                      icon: Icons.photo_camera_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paragraph(
                            "Los reportes, fotos, textos y ubicaciones son contenido generado por usuarios. "
                            "SKANO no garantiza veracidad, exactitud o actualidad de dicha información.",
                          ),
                          const SizedBox(height: 10),
                          _paragraph(
                            "La información en la app no constituye denuncia oficial ni antecedente pericial.",
                          ),
                        ],
                      ),
                    ),

                    _accordion(
                      index: 4,
                      title: "5) Permisos y privacidad",
                      icon: Icons.privacy_tip_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paragraph(
                            "La app puede solicitar permisos de cámara y ubicación. "
                            "Se utilizan para generar evidencia del reporte y apoyar la verificación.",
                          ),
                          const SizedBox(height: 10),
                          _bullets(const [
                            "La ubicación queda asociada al reporte enviado.",
                            "Las fotos se almacenan como evidencia y pueden revisarse por administración.",
                            "Los registros se entregan solo ante requerimiento legal válido.",
                          ]),
                        ],
                      ),
                    ),

                    _accordion(
                      index: 5,
                      title: "6) Falsos reportes y abuso",
                      icon: Icons.report_gmailerrorred_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paragraph(
                            "Para proteger a la comunidad, SKANO puede aplicar medidas ante abuso, fraude o reportes falsos.",
                          ),
                          const SizedBox(height: 10),
                          _bullets(const [
                            "Bloqueo temporal o permanente de la cuenta.",
                            "Revisión manual y solicitud de evidencia adicional.",
                            "Anulación de recompensas si se detecta fraude.",
                          ]),
                        ],
                      ),
                    ),

                    _accordion(
                      index: 6,
                      title: "7) Limitación de responsabilidad",
                      icon: Icons.shield_outlined,
                      content: _paragraph(
                        "SKANO y sus administradores no son responsables por daños físicos, materiales, "
                        "pérdidas económicas, consecuencias legales o acciones de terceros derivadas "
                        "de decisiones o conductas del usuario. El uso es bajo exclusiva responsabilidad del usuario.",
                      ),
                    ),

                    _accordion(
                      index: 7,
                      title: "8) Ley aplicable y jurisdicción",
                      icon: Icons.gavel_outlined,
                      content: _paragraph(
                        "Este acuerdo se rige por las leyes de la República de Chile. "
                        "Cualquier controversia será conocida por los tribunales ordinarios de justicia de Chile.",
                      ),
                    ),

                    _sectionCard(
                      title: "Soporte y contacto",
                      icon: Icons.support_agent_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _contactRow(Icons.email_outlined, "contacto@skano.cl"),
                          const SizedBox(height: 8),
                          _contactRow(Icons.language_outlined, "www.skano.cl"),
                          const SizedBox(height: 8),
                          _contactRow(Icons.local_police_outlined, "Emergencia: Carabineros 133"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    _footer(),

                    if (_saveError != null) ...[
                      const SizedBox(height: 12),
                      _errorBox(_saveError!),
                    ],
                  ],
                ),
              ),
            ),
            _bottomAcceptanceBar(safeBottom),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI Blocks
  // =========================

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A6CFF),
            Color(0xFF123C8C),
            Color(0xFF071126),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white.withOpacity(0.12),
              size: 110,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Uso seguro de SKANO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tu seguridad siempre está primero. Lee esta información antes de reportar un vehículo.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final percent = (_readProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: electricBlue, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  "Lectura de secciones importantes",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "$percent%",
                style: const TextStyle(
                  color: electricBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: _readProgress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(electricBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0B0B).withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Importante",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Nunca confrontes personas. Nunca persigas vehículos. SKANO es para reportar de forma segura, no para intervenir.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color accentColor = neonBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBubble(icon, accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _accordion({
    required int index,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _premiumDecoration(),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white60,
          iconColor: electricBlue,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (opened) {
            if (opened && !_openedSections.contains(index)) {
              setState(() => _openedSections.add(index));
            }
          },
          title: Row(
            children: [
              _iconBubble(icon, neonBlue, size: 34, iconSize: 19),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.8,
                    fontWeight: FontWeight.w850,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(color: Colors.white.withOpacity(0.08), height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _bottomAcceptanceBar(double safeBottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safeBottom),
      decoration: BoxDecoration(
        color: const Color(0xFF080B12).withOpacity(0.98),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _understood = !_understood),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _understood
                    ? neonBlue.withOpacity(0.12)
                    : Colors.white.withOpacity(0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _understood
                      ? neonBlue.withOpacity(0.45)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _understood,
                    activeColor: neonBlue,
                    checkColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.55)),
                    onChanged: (v) => setState(() => _understood = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "Entiendo y acepto que el uso es bajo mi exclusiva responsabilidad.",
                      style: TextStyle(color: Colors.white70, height: 1.3, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: _understood
                    ? const LinearGradient(
                        colors: [Color(0xFF0A6CFF), Color(0xFF38BDF8)],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade800, Colors.grey.shade700],
                      ),
                boxShadow: _understood
                    ? [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.38),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _understood && !_saving ? _acceptAndClose : null,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "ACEPTO Y CONTINUAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14.5,
        height: 1.48,
      ),
    );
  }

  Widget _bullets(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: electricBlue.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14.5,
                        height: 1.42,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: electricBlue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Column(
      children: const [
        Text(
          "SKANO © 2026",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Detecta • Reporta • Protege",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Versión de términos: v1.0",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0B0B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Text(
        error,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _iconBubble(
    IconData icon,
    Color color, {
    double size = 38,
    double iconSize = 21,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(size / 2.7),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  BoxDecoration _premiumDecoration() {
    return BoxDecoration(
      color: bgCardSoft.withOpacity(0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.24),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}