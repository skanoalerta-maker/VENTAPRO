const nodemailer = require("nodemailer");

// ================================
// CONFIGURACIÓN SMTP (Zoho)
// ================================
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ================================
// FUNCIÓN DE ENVÍO
// ================================
async function sendEmail({ to, subject, html }) {
  if (!to || !subject || !html) {
    throw new Error("Parámetros incompletos para enviar correo");
  }

  return transporter.sendMail({
    from: `"SKANO" <${process.env.SMTP_USER}>`,
    to,
    subject,
    html,
  });
}

// ✅ EXPORT CORRECTO
module.exports = {
  sendEmail,
};
