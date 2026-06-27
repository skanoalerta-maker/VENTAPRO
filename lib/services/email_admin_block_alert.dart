import 'email_base_template.dart';

class EmailAdminBlockAlert {
  static String build({
    required String uid,
    required String name,
    required String email,
    required String reason,
  }) {
    final title = "🚨 Usuario bloqueado automáticamente – Revisión requerida";

    final message = """
Se ha detectado una situación que activó los <strong>protocolos automáticos de seguridad</strong> 
en SKANO. La cuenta indicada a continuación fue <strong>bloqueada de forma temporal</strong>.<br><br>

📌 <strong>Información del usuario:</strong><br>
• <strong>UID:</strong> $uid<br>
• <strong>Nombre:</strong> $name<br>
• <strong>Email:</strong> $email<br>
• <strong>Motivo del bloqueo:</strong> $reason<br><br>

⏱️ <strong>Estado actual:</strong><br>
• Bloqueo <strong>temporal</strong> (ventana de seguridad aproximada: <strong>45 minutos</strong>)<br>
• El usuario <strong>ya fue notificado por correo</strong><br><br>

🔍 <strong>Acción requerida:</strong><br>
Revisar el caso en el <strong>panel de administración</strong> y determinar si corresponde:<br>
• Desbloqueo manual<br>
• Mantener el bloqueo<br>
• Escalar a bloqueo definitivo (solo si aplica)<br><br>

Este correo corresponde a una <strong>alerta operativa interna</strong>.
""";

    return EmailBaseTemplate.wrap(title, message);
  }
}
