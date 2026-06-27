import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptScreen extends StatelessWidget {
  const TermsAcceptScreen({super.key});

  static const Color _bg = Color(0xFF050816);
  static const Color _card = Color(0xFF0B1020);
  static const Color _card2 = Color(0xFF101827);
  static const Color _neonBlue = Color(0xFF0A6CFF);
  static const Color _cyan = Color(0xFF38BDF8);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _warning = Color(0xFFFFB020);

  Future<void> acceptTerms(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        "email": user.email,
        "termsAccepted": true,
        "termsAcceptedAt": DateTime.now(),
        "verification_status": "active",
        "created_at": DateTime.now(),
        "updated_at": DateTime.now(),
      }, SetOptions(merge: true));
    } else {
      await userRef.update({
        "termsAccepted": true,
        "termsAcceptedAt": DateTime.now(),
        "updated_at": DateTime.now(),
      });
    }

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, "/start_gate");
  }

  Future<void> _openWebPolicies() async {
    final uri = Uri.parse("https://www.skano.cl/politicas.html");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          "Términos y Condiciones",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF07122B),
              Color(0xFF050816),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroHeader(),
                      const SizedBox(height: 18),

                      _warningBox(),
                      const SizedBox(height: 18),

                      _section(
                        icon: Icons.block_rounded,
                        color: _danger,
                        title: "No intervención ni promesas",
                        body:
                            "SKANO no garantiza la recuperación de vehículos, no asegura resultados ni verifica presencialmente los hechos reportados. Toda la información mostrada se basa en datos entregados por los usuarios.",
                      ),

                      _section(
                        icon: Icons.local_police_rounded,
                        color: _cyan,
                        title: "Autoridades y emergencias",
                        body:
                            "SKANO NO contacta Carabineros, PDI, seguridad municipal ni ningún organismo público o privado. Cualquier contacto con autoridades es una decisión personal del usuario, realizada desde su propio dispositivo y bajo su exclusiva responsabilidad.",
                      ),

                      _section(
                        icon: Icons.warning_amber_rounded,
                        color: _warning,
                        title: "Conducta del usuario",
                        body:
                            "El usuario se compromete a no enfrentar, perseguir, retener ni interactuar con terceros. No debe intentar recuperar vehículos ni exponerse a situaciones de riesgo. Cualquier acción realizada fuera de la aplicación es responsabilidad exclusiva del usuario.",
                      ),

                      _section(
                        icon: Icons.photo_camera_rounded,
                        color: _neonBlue,
                        title: "Reportes y contenido",
                        body:
                            "Los reportes, imágenes, ubicaciones y comentarios son contenido generado por usuarios. SKANO no valida en tiempo real su veracidad y no se hace responsable por errores, omisiones o información incorrecta proporcionada por terceros.",
                      ),

                      _section(
                        icon: Icons.verified_user_rounded,
                        color: Colors.greenAccent,
                        title: "Verificación y control antifraude",
                        body:
                            "SKANO utiliza verificación facial, controles de sesión y análisis de patrones para prevenir abusos. El incumplimiento de las normas puede derivar en bloqueo temporal o suspensión definitiva de la cuenta.",
                      ),

                      _section(
                        icon: Icons.location_on_rounded,
                        color: _cyan,
                        title: "Ubicación y privacidad",
                        body:
                            "La geolocalización se registra únicamente al momento de un reporte. SKANO no realiza seguimiento permanente ni comparte la ubicación del usuario con terceros.",
                      ),

                      _section(
                        icon: Icons.gavel_rounded,
                        color: _warning,
                        title: "Limitación de responsabilidad",
                        body:
                            "En ningún caso SKANO, sus fundadores o colaboradores serán responsables por daños físicos, materiales, morales, pérdidas económicas o consecuencias derivadas del uso de la plataforma, incluso si dichos daños se relacionan con reportes.",
                      ),

                      _section(
                        icon: Icons.assignment_turned_in_rounded,
                        color: Colors.greenAccent,
                        title: "Aceptación expresa",
                        body:
                            "Al continuar, el usuario declara haber leído, comprendido y aceptado íntegramente estos términos, liberando a SKANO de cualquier responsabilidad derivada de su uso.",
                      ),

                      Center(
                        child: TextButton.icon(
                          onPressed: _openWebPolicies,
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: _cyan,
                          ),
                          label: const Text(
                            "Ver versión legal completa en www.skano.cl",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _cyan,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              _bottomAcceptBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A6CFF),
            Color(0xFF071A3D),
            Color(0xFF050816),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Uso responsable y aceptación legal",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "SKANO es una plataforma tecnológica, informativa y colaborativa. No es una empresa de seguridad, no presta vigilancia, no recupera vehículos ni coordina acciones con autoridades.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Pill(text: "Uso voluntario"),
              _Pill(text: "Sin persecución"),
              _Pill(text: "Responsabilidad del usuario"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _danger.withOpacity(0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: _danger, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Importante: no persigas, no enfrentes y no intentes recuperar vehículos. Si existe riesgo, aléjate y contacta a la autoridad por tus propios medios.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontSize: 16.5,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAcceptBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Al aceptar, confirmas que entiendes las reglas de seguridad de SKANO.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _neonBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => acceptTerms(context),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                "Acepto los términos y continúo",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}