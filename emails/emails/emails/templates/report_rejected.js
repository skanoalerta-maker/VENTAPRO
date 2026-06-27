module.exports = ({ plate, reason }) => ({
  subject: "❌ Tu reporte no pudo ser validado",
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
          Reporte no validado
        </h2>

        <p style="color:#ddd">
          El reporte asociado al siguiente vehículo no pudo ser validado:
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
          Esto no implica una falta por tu parte.  
          Algunos reportes no cumplen los criterios mínimos de validación
          o no coinciden con registros activos de vehículos robados.
        </p>

        <p style="color:#ddd">
          Te invitamos a seguir colaborando con la comunidad de forma responsable.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Validación automática para prevenir reportes incorrectos
        </p>
      </div>
    </div>
  `,
});
