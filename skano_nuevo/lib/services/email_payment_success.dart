import 'email_base_template.dart';

class EmailPaymentSuccess {
  static String build({
    required String name,
    required String plan,
    required int amount,
  }) {
    final title = "🎉 Membresía SKANO activada";

    final message = """
Hola <strong>$name</strong>,<br><br>

Tu pago fue <strong>procesado correctamente</strong> y tu membresía 
<strong>$plan</strong> ya se encuentra <strong>activa</strong>.<br><br>

💳 <strong>Detalle del pago:</strong><br>
• Plan: <strong>$plan</strong><br>
• Monto pagado: <strong>\$${_formatAmount(amount)} CLP</strong><br><br>

Desde este momento puedes acceder a las funciones asociadas a tu membresía, 
incluyendo la <strong>protección y gestión de tus vehículos registrados</strong> 
dentro de SKANO.<br><br>

Gracias por confiar en nuestra plataforma y por ser parte de una comunidad que 
utiliza tecnología para mejorar la seguridad.<br><br>

Si tienes alguna duda o inconveniente, puedes escribirnos a:<br>
📨 <strong>skano.alerta@gmail.com</strong><br><br>

<strong>Equipo SKANO</strong> 💙
""";

    return EmailBaseTemplate.wrap(title, message);
  }

  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}
