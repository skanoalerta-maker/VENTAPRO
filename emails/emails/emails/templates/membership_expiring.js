module.exports = ({ fullName, days }) => ({
  subject: "⏰ Tu membresía SKANO está por vencer",
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

        <h2 style="color:#FFB300;text-align:center;margin-bottom:12px">
          Tu membresía está por vencer
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Queremos recordarte que tu membresía en SKANO vencerá en
          <strong> ${days} días</strong>.
        </p>

        <p style="color:#ddd">
          Para mantener la protección activa de tu vehículo y la recepción
          de alertas, te recomendamos renovar tu membresía antes de la fecha
          de vencimiento.
        </p>

        <p style="color:#ddd">
          Puedes renovar tu plan fácilmente desde la aplicación en cualquier momento.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Protección vehicular con apoyo comunitario
        </p>
      </div>
    </div>
  `,
});
