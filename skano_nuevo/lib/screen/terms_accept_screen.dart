import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAcceptScreen extends StatelessWidget {
  const TermsAcceptScreen({super.key});

  Future<void> acceptTerms(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;
    final email = currentUser.email ?? "";
    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        "uid": uid,
        "email": email,
        "role": "user",

        // ESTADO CORRECTO INICIAL
        "verification_status": "draft",
        "reviewPending": false,
        "documentStatus": "draft",
        "documentsCompleted": false,

        // TÉRMINOS
        "termsAccepted": true,
        "termsAcceptedAt": FieldValue.serverTimestamp(),

        // SEGURIDAD
        "blocked": false,
        "blocked_by_admin": false,
        "blocked_reason": "",
        "blocked_until": null,

        // SISTEMA
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await userRef.update({
        "termsAccepted": true,
        "termsAcceptedAt": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
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

  Widget _section(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Uso responsable y aceptación legal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "SKANO es una plataforma tecnológica de carácter informativo y colaborativo. "
                      "No es una empresa de seguridad, no presta servicios de vigilancia, "
                      "no recupera vehículos ni coordina acciones con autoridades. "
                      "El uso de la aplicación es voluntario y bajo exclusiva responsabilidad del usuario.",
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      "🛑 No intervención ni promesas",
                      "SKANO no garantiza la recuperación de vehículos, "
                      "no asegura resultados ni verifica presencialmente los hechos reportados. "
                      "Toda la información mostrada se basa en datos entregados por los usuarios.",
                    ),
                    _section(
                      "🚓 Autoridades y emergencias",
                      "SKANO NO contacta Carabineros, PDI, seguridad municipal ni ningún organismo público o privado. "
                      "Cualquier contacto con autoridades es una decisión personal del usuario, "
                      "realizada desde su propio dispositivo y bajo su exclusiva responsabilidad.",
                    ),
                    _section(
                      "⚠️ Conducta del usuario",
                      "El usuario se compromete a no enfrentar, perseguir, retener ni interactuar con terceros. "
                      "No debe intentar recuperar vehículos ni exponerse a situaciones de riesgo. "
                      "Cualquier acción realizada fuera de la aplicación es responsabilidad exclusiva del usuario.",
                    ),
                    _section(
                      "📸 Reportes y contenido",
                      "Los reportes, imágenes, ubicaciones y comentarios son contenido generado por usuarios. "
                      "SKANO no valida en tiempo real su veracidad y no se hace responsable por errores, "
                      "omisiones o información incorrecta proporcionada por terceros.",
                    ),
                    _section(
                      "🔐 Verificación y control antifraude",
                      "SKANO utiliza verificación facial, controles de sesión y análisis de patrones "
                      "para prevenir abusos. El incumplimiento de las normas puede derivar en "
                      "bloqueo temporal o suspensión definitiva de la cuenta.",
                    ),
                    _section(
                      "📍 Ubicación y privacidad",
                      "La geolocalización se registra únicamente al momento de un reporte. "
                      "SKANO no realiza seguimiento permanente ni comparte la ubicación del usuario con terceros.",
                    ),
                    _section(
                      "⚖️ Limitación de responsabilidad",
                      "En ningún caso SKANO, sus fundadores o colaboradores serán responsables "
                      "por daños físicos, materiales, morales, pérdidas económicas o consecuencias "
                      "derivadas del uso de la plataforma, incluso si dichos daños se relacionan con reportes.",
                    ),
                    _section(
                      "🧾 Aceptación expresa",
                      "Al continuar, el usuario declara haber leído, comprendido y aceptado "
                      "íntegramente estos términos, liberando a SKANO de cualquier responsabilidad "
                      "derivada de su uso.",
                    ),
                    TextButton(
                      onPressed: _openWebPolicies,
                      child: const Text(
                        "Ver versión legal completa en www.skano.cl",
                        style: TextStyle(color: neonBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => acceptTerms(context),
                child: const Text(
                  "Acepto los términos y continúo",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}