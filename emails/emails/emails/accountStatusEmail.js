const sendEmail = require("./sendEmail");

module.exports = async ({ to, status, reason }) => {
  let subject = "";
  let html = "";

  if (status === "blocked") {
    subject = "⚠️ Tu cuenta SKANO está bloqueada temporalmente";
    html = `
      <h2>Cuenta bloqueada</h2>
      <p>Tu cuenta en <b>SKANO</b> ha sido bloqueada por el siguiente motivo:</p>
      <p><b>${reason}</b></p>
      <p>
        Mientras dure este bloqueo no podrás reportar vehículos ni realizar acciones sensibles.
      </p>
      <p>
        Si necesitas ayuda, nuestro equipo revisará tu caso.
      </p>
      <br/>
      <small>Equipo SKANO</small>
    `;
  }

  if (status === "unblocked") {
    subject = "✅ Tu cuenta SKANO fue desbloqueada";
    html = `
      <h2>Cuenta desbloqueada</h2>
      <p>Tu cuenta ha sido revisada y desbloqueada.</p>
      <p>Ya puedes volver a usar SKANO con normalidad.</p>
      <br/>
      <small>Equipo SKANO</small>
    `;
  }

  await sendEmail({ to, subject, html });
};
