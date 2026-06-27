module.exports = ({ fullName, plate, reason }) => ({
  subject: "❌ Tu vehículo no pudo ser aprobado",
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
          Vehículo no aprobado
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          El vehículo registrado no pudo ser aprobado tras la revisión de la información enviada.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          <strong>Motivo:</strong> ${reason}
        </p>

        <p style="color:#ddd;margin-top:12px">
          Esto no implica un rechazo definitivo.  
          Puedes corregir la información o los documentos solicitados
          y volver a enviar el vehículo para revisión.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Validación responsable para proteger a la comunidad
        </p>
      </div>
    </div>
  `,
});
