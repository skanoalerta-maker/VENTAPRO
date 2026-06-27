const nodemailer = require("nodemailer");
const { defineString } = require("firebase-functions/params");

/**
 * ===============================
 * SECRETS SMTP (GEN 2)
 * ===============================
 */
const SMTP_HOST = defineString("SMTP_HOST");
const SMTP_PORT = defineString("SMTP_PORT");
const SMTP_USER = defineString("SMTP_USER");
const SMTP_PASS = defineString("SMTP_PASS");

/**
 * ===============================
 * ENVÍO DE EMAIL
 * ===============================
 */
async function sendEmail({ to, subject, html }) {
  const transporter = nodemailer.createTransport({
    host: SMTP_HOST.value(),
    port: Number(SMTP_PORT.value()),
    secure: false, // STARTTLS para 587
    auth: {
      user: SMTP_USER.value(),
      pass: SMTP_PASS.value(),
    },
  });

  await transporter.sendMail({
    from: `"SKANO 🚨" <${SMTP_USER.value()}>`,
    to,
    subject,
    html,
  });
}

module.exports = { sendEmail };
