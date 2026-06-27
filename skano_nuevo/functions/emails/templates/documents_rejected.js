module.exports = ({ fullName, reason }) => ({
  subject: "❌ Tus documentos no pudieron ser aprobados",
  html: `
    <div style="font-family:Arial;background:#0b0b0b;padding:24px">
      <div style="max-width:640px;margin:auto;background:#111;border-radius:16px;padding:24px;color:#ffffff">

        <!-- LOGO -->
        <div style="text-align:center;margin-bottom:20px">
          <img 
            src="https://skano.cl/assets/logo-skano.png"
            alt="SKANO"
            style="max-width:140px"
          />
        </div>

        <h2 style="color:#FF5252;text-align:center;margin-bottom:12px">
          Documentos no aprobados
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Tras la revisión de la información enviada, no fue posible aprobar
          tus documentos en esta ocasión.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0">
          <p style="margin:0;color:#fff">
            <strong>Motivo:</strong> ${reason}
          </p>
        </div>

        <p style="color:#ddd">
          Esto no implica un rechazo definitivo.  
          Puedes corregir la información solicitada y reenviar tus documentos
          directamente desde la aplicación.
        </p>

        <p style="color:#ddd">
          Nuestro objetivo es mantener una plataforma segura y confiable
          para todos los usuarios.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Verificación responsable para proteger a la comunidad
        </p>
      </div>
    </div>
  `,
});
