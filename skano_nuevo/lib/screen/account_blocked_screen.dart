import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// =============================================================
/// WRAPPER PARA RECIBIR ARGUMENTOS DESDE Navigator
/// =============================================================
class AccountBlockedRoute extends StatelessWidget {
  const AccountBlockedRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;

    return AccountBlockedScreen(
      reason: args?["reason"] ?? "unknown",
      blockedUntil: args?["blockedUntil"],
      adminComment: args?["adminComment"] ?? "",
    );
  }
}

/// =============================================================
/// PANTALLA REAL DE BLOQUEO
/// =============================================================
class AccountBlockedScreen extends StatelessWidget {
  final String reason;
  final DateTime? blockedUntil;
  final String? adminComment;

  const AccountBlockedScreen({
    super.key,
    required this.reason,
    this.blockedUntil,
    this.adminComment,
  });

  // ✅ FIX CLAVE: cubrir ambos casos de re-verificación
  bool get isReverification =>
      reason == "identity_change_pending" ||
      reason == "identity_reverification_pending";

  String getReasonText() {
    switch (reason) {
      case "selfie_initial_failed":
      case "selfie_failed":
        return "Tu cuenta fue bloqueada por múltiples fallas en el reconocimiento facial.";

      case "selfie_fast_failed":
        return "Fallaste varias veces en la verificación rápida.";

      case "fraud_detection":
        return "Detectamos actividad sospechosa en tu cuenta.";

      case "pin_failed_3_times":
        return "Fallaste el PIN demasiadas veces. Tu cuenta fue bloqueada temporalmente.";

      case "identity_change_pending":
      case "identity_reverification_pending":
        return "Has solicitado modificar datos verificados.\n\n"
            "Puedes editar tu información, pero no podrás reportar hasta que el equipo apruebe la re-verificación.";

      default:
        return "Tu cuenta está bloqueada temporalmente.";
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(26, 90, 26, 20),
        child: Column(
          children: [
            // ÍCONO
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isReverification ? Colors.orangeAccent : Colors.redAccent,
                    Colors.transparent,
                  ],
                  radius: 0.9,
                ),
              ),
              child: Icon(
                isReverification ? Icons.verified_user : Icons.block,
                size: 120,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isReverification ? "Re-verificación requerida" : "Cuenta bloqueada",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              getReasonText(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 20),

            if (blockedUntil != null && !isReverification)
              Text(
                "Disponible nuevamente:\n${DateFormat('dd/MM/yyyy HH:mm').format(blockedUntil!)}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange, fontSize: 15),
              ),

            if (adminComment != null && adminComment!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Comentario del equipo:\n${adminComment!}",
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (isReverification) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/my_account",
                      (_) => false,
                    );
                  } else {
                    final uri = Uri(
                      scheme: "mailto",
                      path: "skano.alerta@gmail.com",
                      query:
                          "subject=Revisión de bloqueo&body=Hola, necesito ayuda.",
                    );
                    await launchUrl(uri);
                  }
                },
                child: Text(
                  isReverification
                      ? "Ir a Mi Cuenta"
                      : "Contactar a soporte",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
