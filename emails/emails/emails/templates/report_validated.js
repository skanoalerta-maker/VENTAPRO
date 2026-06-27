module.exports = ({ plate }) => ({
  subject: "✅ Tu reporte fue validado",
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

        <h2 style="color:#4CAF50;text-align:center;margin-bottom:12px">
          Reporte validado correctamente
        </h2>

        <p style="color:#ddd">
          Tu reporte asociado al siguiente vehículo fue validado por nuestros sistemas:
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          Gracias por actuar de forma responsable y ayudar a la comunidad a recuperar vehículos robados.
        </p>

        <p style="color:#ddd">
          Si este reporte cumple las condiciones del programa de recompensas,
          tu beneficio será acreditado automáticamente.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Reportes ciudadanos con validación de seguridad
        </p>
      </div>
    </div>
  `,
});
