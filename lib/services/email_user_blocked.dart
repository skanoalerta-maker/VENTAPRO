import 'email_base_template.dart';

class EmailUserBlocked {
  static String build({
    required String name,
    required String reason,
  }) {
    final title = "🔒 Bloqueo temporal de seguridad";

    final message = """
Hola <strong>$name</strong>,<br><br>

Detectamos una actividad que activó nuestros sistemas de seguridad, por lo que tu cuenta fue 
<strong>bloqueada de forma temporal y automática</strong>.<br><br>

<strong>Motivo detectado:</strong><br>
• $reason<br><br>

⏱️ <strong>Duración del bloqueo:</strong><br>
El bloqueo se mantendrá por aproximadamente <strong>45 minutos</strong>.  
Una vez finalizado este período, podrás volver a utilizar la aplicación con normalidad.<br><br>

Este proceso <strong>no es una sanción</strong> y se aplica únicamente para proteger tu cuenta y la
seguridad del sistema SKANO.<br><br>

Si no reconoces esta actividad o el bloqueo persiste por más tiempo del indicado, puedes
contactarnos en:<br>
📨 <strong>skano.alerta@gmail.com</strong><br><br>

Gracias por tu comprensión y por ayudar a mantener SKANO seguro.<br><br>

<strong>Equipo SKANO</strong>
""";

    return EmailBaseTemplate.wrap(title, message);
  }
}
