import 'package:emailjs/emailjs.dart';

class EmailReportSuccess {
  static const String _serviceId = "service_dhlclsi";
  static const String _templateId = "template_report_success";
  static const String _publicKey = "t2p_1RM0ZdrPX2SFN";

  static Future<void> send({
    required String uid,
    required String email,
    required String plate,
    required double reward,
  }) async {
    if (uid.isEmpty || email.isEmpty || plate.isEmpty) {
      _log("⚠️ EmailReportSuccess NO enviado: datos incompletos");
      return;
    }

    try {
      final data = {
        "uid": uid,
        "email": email,
        "plate": plate.toUpperCase(),
        "reward": _formatReward(reward),
        "date": _formatDate(DateTime.now()),
      };

      await EmailJS.send(
        _serviceId,
        _templateId,
        data,
        Options(publicKey: _publicKey),
      );

      _log("📩 Email de reporte exitoso enviado correctamente");
    } catch (e) {
      _log("❌ ERROR enviando EmailReportSuccess → $e");
    }
  }

  static String _formatReward(double reward) {
    if (reward <= 0) return "Sin recompensa asociada";
    return "\$${reward.toStringAsFixed(0)} CLP";
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
