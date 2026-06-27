const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// ================= SMTP =================
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ================= TEMPLATES =================
function approvedEmail(name) {
  return `
    <h2>✅ Cuenta aprobada en SKANO</h2>
    <p>Hola <strong>${name}</strong>,</p>
    <p>Tu identidad fue verificada exitosamente.</p>
    <p>Ya puedes usar todas las funciones de SKANO.</p>
    <br/>
    <strong>Equipo SKANO</strong>
  `;
}

function rejectedEmail(name, reason) {
  return `
    <h2>❌ Cuenta rechazada en SKANO</h2>
    <p>Hola <strong>${name}</strong>,</p>
    <p>Tu solicitud fue rechazada por el siguiente motivo:</p>
    <blockquote>${reason || "No especificado"}</blockquote>
    <br/>
    <strong>Equipo SKANO</strong>
  `;
}

// ================= FUNCTION =================
exports.onUserReviewed = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    console.log("🔍 Cambio detectado:", {
      before: before.verification_status,
      after: after.verification_status,
      email: after.email,
    });

    if (before.verification_status === after.verification_status) {
      console.log("⏭ Sin cambio de estado, se ignora");
      return;
    }

    if (!after.email) {
      console.error("❌ Usuario sin email");
      return;
    }

    // ================= APROBADO =================
    if (after.verification_status === "verified") {
      console.log("📨 Enviando correo de APROBACIÓN");

      await transporter.sendMail({
        from: `"SKANO" <${process.env.SMTP_USER}>`,
        to: after.email,
        subject: "✅ Tu cuenta fue aprobada en SKANO",
        html: approvedEmail(after.full_name || "Usuario"),
      });
    }

    // ================= RECHAZADO =================
    if (after.verification_status === "rejected") {
      console.log("📨 Enviando correo de RECHAZO");

      await transporter.sendMail({
        from: `"SKANO" <${process.env.SMTP_USER}>`,
        to: after.email,
        subject: "❌ Tu cuenta fue rechazada en SKANO",
        html: rejectedEmail(
          after.full_name || "Usuario",
          after.admin_comment
        ),
      });
    }
  }
);
