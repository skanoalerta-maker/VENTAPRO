module.exports = ({ fullName }) => ({
  subject: "👋 Bienvenido a SKANO",
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

        <h2 style="margin:0 0 12px;color:#0A6CFF;text-align:center">
          Bienvenido a SKANO
        </h2>

        <p style="color:#ddd;margin:0 0 12px">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd;margin:0 0 12px">
          Tu cuenta fue creada con éxito.
        </p>

        <p style="color:#ddd;margin:0 0 12px">
          Desde ahora puedes:
        </p>

        <ul style="color:#ddd;margin:0 0 16px;padding-left:18px">
          <li>Registrar vehículos</li>
          <li>Reportar vehículos robados de forma segura</li>
          <li>Ayudar a la comunidad y obtener recompensas</li>
        </ul>

        <p style="color:#ddd;margin:0 0 12px">
          Te avisaremos por correo cada vez que ocurra algo importante con tu cuenta.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Seguridad ciudadana + tecnología
        </p>
      </div>
    </div>
  `,
});
