import 'package:emailjs/emailjs.dart';

class EmailVerificationCompleted {
  static const String _serviceId = "service_dhlclsi";
  static const String _templateId = "template_verification_completed";
  static const String _publicKey = "t2p_1RM0ZdrPX2SFN";

  static Future<void> send({
    required String uid,
    required String email,
    required String name,
  }) async {
    if (uid.isEmpty || email.isEmpty || name.isEmpty) {
      _log("⚠️ EmailVerificationCompleted NO enviado: datos incompletos");
      return;
    }

    try {
      final data = {
        "uid": uid,
        "email": email,
        "name": name,
        "date": DateTime.now().toString(),
      };

      await EmailJS.send(
        _serviceId,
        _templateId,
        data,
        Options(publicKey: _publicKey),
      );

      _log("📩 Email de verificación completada enviado correctamente");
    } catch (e) {
      _log("❌ ERROR enviando EmailVerificationCompleted → $e");
    }
  }

  static void _log(String message) {
    // ignore: avoid_print
    print(message);
  }
}
