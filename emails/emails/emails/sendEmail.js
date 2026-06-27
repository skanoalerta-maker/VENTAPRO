const nodemailer = require("nodemailer");

// ================================
// VALIDACIÓN / CONFIG SMTP
// ================================
function getSmtpConfig() {
  const requiredEnvVars = ["SMTP_HOST", "SMTP_USER", "SMTP_PASS"];

  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new Error(`Falta la variable de entorno requerida: ${envVar}`);
    }
  }

  return {
    SMTP_HOST: process.env.SMTP_HOST,
    SMTP_PORT: Number(process.env.SMTP_PORT || 587),
    SMTP_USER: process.env.SMTP_USER,
    SMTP_PASS: process.env.SMTP_PASS,
    SMTP_FROM_NAME: process.env.SMTP_FROM_NAME || "SKANO",
  };
}

function createTransporter() {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = getSmtpConfig();

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_PORT === 465,
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS,
    },
    tls: {
      rejectUnauthorized: true,
      minVersion: "TLSv1.2",
    },
  });
}

// ================================
// HELPERS
// ================================
function normalizeRecipients(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => String(item).trim())
      .filter(Boolean)
      .join(", ");
  }

  return String(value || "").trim();
}

function stripHtml(html) {
  return String(html || "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<\/(p|div|h1|h2|h3|li|tr)>/gi, "\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

// ================================
// FUNCIÓN DE ENVÍO
// ================================
async function sendEmail({
  to,
  subject,
  html,
  text,
  cc,
  bcc,
  attachments = [],
}) {
  const normalizedTo = normalizeRecipients(to);
  const normalizedCc = normalizeRecipients(cc);
  const normalizedBcc = normalizeRecipients(bcc);
  const normalizedSubject = String(subject || "").trim();
  const normalizedHtml = String(html || "").trim();

  if (!normalizedTo || !normalizedSubject || !normalizedHtml) {
    throw new Error("Parámetros incompletos para enviar correo");
  }

  const { SMTP_USER, SMTP_FROM_NAME } = getSmtpConfig();
  const transporter = createTransporter();

  const mailOptions = {
    from: `"${SMTP_FROM_NAME}" <${SMTP_USER}>`,
    replyTo: SMTP_USER,
    to: normalizedTo,
    subject: normalizedSubject,
    html: normalizedHtml,
    text: String(text || "").trim() || stripHtml(normalizedHtml),
    headers: {
      "X-Mailer": "SKANO Mail Service",
      "X-Auto-Response-Suppress": "OOF, AutoReply",
    },
    attachments,
  };

  if (normalizedCc) {
    mailOptions.cc = normalizedCc;
  }

  if (normalizedBcc) {
    mailOptions.bcc = normalizedBcc;
  }

  try {
    const info = await transporter.sendMail(mailOptions);

    console.log("Correo enviado correctamente:", {
      messageId: info.messageId,
      to: normalizedTo,
      subject: normalizedSubject,
      accepted: info.accepted,
      rejected: info.rejected,
    });

    return info;
  } catch (error) {
    console.error("Error al enviar correo:", {
      message: error.message,
      code: error.code,
      response: error.response,
      command: error.command,
      to: normalizedTo,
      subject: normalizedSubject,
    });

    throw new Error(`No se pudo enviar el correo: ${error.message}`);
  }
}

module.exports = {
  sendEmail,
};