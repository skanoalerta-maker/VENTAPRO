module.exports = ({ fullName, minutes }) => ({
  subject: "🚨 Cuenta bloqueada temporalmente por seguridad",
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

        <h2 style="color:#FF5252;margin-bottom:12px;text-align:center">
          Cuenta bloqueada temporalmente
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Detectamos varios intentos fallidos de verificación en tu cuenta.
          Por tu seguridad, hemos aplicado un bloqueo temporal.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0">
          <p style="margin:0;color:#fff">
            ⏱ <strong>Duración del bloqueo:</strong> ${minutes} minutos
          </p>
        </div>

        <p style="color:#ddd">
          No necesitas realizar ninguna acción.
          El acceso se restablecerá automáticamente una vez finalizado el tiempo de bloqueo.
        </p>

        <p style="color:#ddd">
          Si no reconoces esta actividad, te recomendamos cambiar tu contraseña al recuperar el acceso.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO protege tu cuenta y tu identidad.
        </p>
      </div>
    </div>
  `,
});
