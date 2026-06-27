import 'email_base_template.dart';

class EmailPaymentFailed {
  static String build({
    required String name,
    required String plan,
  }) {
    final title = "⚠️ No se pudo completar tu pago en SKANO";

    final message = """
Hola <strong>$name</strong>,<br><br>

Intentamos procesar el pago correspondiente a la membresía <strong>$plan</strong>, 
pero <strong>la transacción no se pudo completar</strong>.<br><br>

<strong>Importante:</strong>  
No se ha realizado ningún cobro a tu medio de pago.<br><br>

Las causas más comunes pueden ser:<br>
• Tarjeta sin fondos disponibles<br>
• Tarjeta expirada o bloqueada<br>
• Rechazo por parte del banco emisor<br>
• Error temporal del sistema de pagos<br><br>

Puedes intentar nuevamente o actualizar tu método de pago desde la aplicación 
cuando lo estimes conveniente.<br><br>

Si necesitas ayuda o el problema persiste, escríbenos a:<br>
📨 <strong>skano.alerta@gmail.com</strong><br><br>

Gracias por tu comprensión.<br><br>

<strong>Equipo SKANO</strong>
""";

    return EmailBaseTemplate.wrap(title, message);
  }
}
