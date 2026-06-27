module.exports = ({ fullName }) => ({
  subject: "⏳ Tu membresía SKANO ha vencido",
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
          Membresía vencida
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Tu membresía en SKANO ha finalizado y actualmente se encuentra vencida.
        </p>

        <p style="color:#ddd">
          Mientras la membresía esté inactiva, tu vehículo no contará con
          protección activa ni recepción de alertas.
        </p>

        <p style="color:#ddd">
          Puedes renovar tu membresía en cualquier momento desde la aplicación
          para volver a contar con protección completa.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Protección vehicular con apoyo comunitario
        </p>
      </div>
    </div>
  `,
});
