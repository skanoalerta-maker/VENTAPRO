import 'package:emailjs/emailjs.dart';

class EmailBlockAlert {
  static const String _serviceId = "service_dhlclsi";
  static const String _templateId = "template_block_alert";
  static const String _publicKey = "t2p_1RM0ZdrPX2SFN";

  static Future<void> send({
    required String uid,
    required String email,
    required String name,
    required String reason,
    required DateTime date,
  }) async {
    if (uid.isEmpty || email.isEmpty || name.isEmpty || reason.isEmpty) {
      _log("⚠️ EmailBlockAlert NO enviado: datos incompletos");
      return;
    }

    try {
      final data = {
        "uid": uid,
        "email": email,
        "name": name,
        "reason": reason,
        "date": _formatDate(date),
      };

      await EmailJS.send(
        _serviceId,
        _templateId,
        data,
        Options(publicKey: _publicKey),
      );

      _log("📩 ALERTA ADMIN: Usuario bloqueado – email enviado");
    } catch (e) {
      _log("❌ ERROR enviando EmailBlockAlert → $e");
    }
  }

  static String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  static void _log(String message) {
    // ignore: avoid_print
    print(message);
  }
}
