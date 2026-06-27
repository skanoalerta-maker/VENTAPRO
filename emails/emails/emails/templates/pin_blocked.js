module.exports = ({ fullName, minutes }) => ({
  subject: "🔐 PIN bloqueado por seguridad",
  html: `
    <div style="font-family:Arial;background:#0b0b0b;padding:24px">
      <div style="max-width:640px;margin:auto;background:#111;border-radius:16px;padding:24px;color:#ffffff">

        <div style="text-align:center;margin-bottom:20px">
          <img 
            src="https://skano.cl/assets/logo-skano.png"
            alt="SKANO"
            style="max-width:140px"
          />
        </div>

        <h2 style="color:#FFA000;text-align:center;margin-bottom:12px">
          PIN bloqueado temporalmente
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Detectamos varios intentos fallidos al ingresar tu PIN de seguridad.
          Para proteger tu cuenta, el PIN ha sido bloqueado temporalmente.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0">
          <p style="margin:0;color:#fff">
            ⏱ <strong>Duración del bloqueo:</strong> ${minutes} minutos
          </p>
        </div>

        <p style="color:#ddd">
          No necesitas realizar ninguna acción.
          Podrás volver a utilizar tu PIN automáticamente una vez finalizado el bloqueo.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO protege tu cuenta y tu información.
        </p>
      </div>
    </div>
  `,
});

