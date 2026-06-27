module.exports = ({ plate }) => ({
  subject: "👀 Avistamiento reportado de tu vehículo",
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

        <h2 style="color:#FF9800;text-align:center;margin-bottom:12px">
          Nuevo avistamiento reportado
        </h2>

        <p style="color:#ddd">
          Se ha recibido un reporte de avistamiento asociado a tu vehículo:
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          Nuestro sistema se encuentra validando la información recibida
          para evitar reportes falsos o malintencionados.
        </p>

        <p style="color:#ddd">
          En caso de que el avistamiento sea confirmado y derivado a la autoridad correspondiente,
          te notificaremos oportunamente.
        </p>

        <p style="color:#ddd;font-weight:bold">
          📌 Te notificaremos cuando la autoridad competente lo tenga en su poder.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Reportes ciudadanos con validación de seguridad
        </p>
      </div>
    </div>
  `,
});
