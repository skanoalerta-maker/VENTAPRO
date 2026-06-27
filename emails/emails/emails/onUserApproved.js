const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

if (!admin.apps.length) {
  admin.initializeApp();
}

// ================= SMTP =================
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp.zoho.com",
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ================= BASE TEMPLATE =================
function baseEmailTemplate({ title, subtitle, content }) {
  return `
  <!DOCTYPE html>
  <html lang="es">
  <head>
    <meta charset="UTF-8" />
    <title>${title}</title>
  </head>
  <body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif;color:#0f172a;">
    <div style="width:100%;padding:28px 0;background:#f1f5f9;">
      <div style="max-width:680px;margin:0 auto;background:#ffffff;border-radius:20px;overflow:hidden;border:1px solid #e2e8f0;box-shadow:0 8px 30px rgba(15,23,42,0.08);">

        <div style="background:linear-gradient(135deg,#020617,#0f172a);padding:34px 30px;color:#ffffff;">
          <div style="font-size:30px;font-weight:900;letter-spacing:0.7px;color:#ffffff;">
            SKANO 🚨
          </div>
          <div style="font-size:14px;margin-top:10px;color:rgba(255,255,255,0.88);line-height:1.5;font-weight:500;">
            Red colaborativa para reportar vehículos con encargo por robo
          </div>
        </div>

        <div style="padding:30px;">
          <h1 style="margin:0 0 10px;font-size:26px;color:#0f172a;font-weight:800;">
            ${title}
          </h1>

          <p style="margin:0 0 24px;color:#475569;font-size:15px;line-height:1.7;">
            ${subtitle || ""}
          </p>

          ${content}
        </div>

        <div style="padding:22px 30px;background:#f8fafc;border-top:1px solid #e2e8f0;color:#64748b;font-size:12px;line-height:1.7;">
          <strong>Importante:</strong>
          SKANO no reemplaza a Carabineros de Chile ni a las autoridades competentes.
          Usa la aplicación de forma segura, sin persecuciones ni confrontaciones.

          <br><br>

          Equipo SKANO<br>
          <a href="https://www.skano.cl" style="color:#0A6CFF;text-decoration:none;font-weight:700;">
            www.skano.cl
          </a>
        </div>

      </div>
    </div>
  </body>
  </html>
  `;
}

// ================= TEMPLATES =================
function approvedEmail(name) {
  return baseEmailTemplate({
    title: "✅ Tu cuenta fue aprobada en SKANO",
    subtitle: "Tu identidad fue verificada correctamente.",
    content: `
      <p style="font-size:15px;line-height:1.7;color:#334155;">
        Hola <strong>${name}</strong>,
      </p>

      <p style="font-size:15px;line-height:1.7;color:#334155;">
        Tu cuenta fue aprobada por el equipo SKANO. Desde ahora puedes utilizar las funciones habilitadas para usuarios verificados, incluyendo el reporte seguro de vehículos con encargo por robo.
      </p>

      <div style="margin:22px 0;padding:16px;border-radius:14px;background:#ecfdf5;border:1px solid #bbf7d0;color:#166534;">
        <strong>Estado:</strong> Cuenta verificada y aprobada.
      </div>

      <p style="font-size:14px;line-height:1.7;color:#475569;">
        Recuerda utilizar SKANO de forma responsable. Nunca persigas vehículos, no confrontes a terceros y mantén siempre tu seguridad como prioridad.
      </p>
    `,
  });
}

function rejectedEmail(name, reason) {
  return baseEmailTemplate({
    title: "❌ Tu cuenta no pudo ser aprobada",
    subtitle: "Tu solicitud requiere corrección antes de continuar.",
    content: `
      <p style="font-size:15px;line-height:1.7;color:#334155;">
        Hola <strong>${name}</strong>,
      </p>

      <p style="font-size:15px;line-height:1.7;color:#334155;">
        Revisamos tu solicitud, pero por ahora no pudimos aprobar tu cuenta.
      </p>

      <div style="margin:22px 0;padding:16px;border-radius:14px;background:#fef2f2;border:1px solid #fecaca;color:#991b1b;">
        <strong>Motivo:</strong><br>
        ${reason || "No especificado"}
      </div>

      <p style="font-size:14px;line-height:1.7;color:#475569;">
        Puedes corregir la información solicitada desde la sección <strong>Mi Cuenta</strong> y volver a enviar tus datos a revisión.
      </p>
    `,
  });
}

// ================= FUNCTION =================
exports.onUserReviewed = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    const beforeStatus = (before.verification_status || "").toString();
    const afterStatus = (after.verification_status || "").toString();

    console.log("🔍 Cambio detectado:", {
      before: beforeStatus,
      after: afterStatus,
      email: after.email,
    });

    if (beforeStatus === afterStatus) {
      console.log("⏭ Sin cambio de estado, se ignora");
      return;
    }

    if (!after.email) {
      console.error("❌ Usuario sin email");
      return;
    }

    const userName = after.full_name || after.name || "Usuario";

    // ================= APROBADO =================
    if (afterStatus === "approved" || afterStatus === "active") {
      console.log("📨 Enviando correo de APROBACIÓN");

      await transporter.sendMail({
        from: `"SKANO 🚨" <${process.env.SMTP_USER}>`,
        to: after.email,
        subject: "✅ Tu cuenta fue aprobada en SKANO",
        html: approvedEmail(userName),
      });

      return;
    }

    // ================= RECHAZADO =================
    if (afterStatus === "rejected") {
      console.log("📨 Enviando correo de RECHAZO");

      await transporter.sendMail({
        from: `"SKANO 🚨" <${process.env.SMTP_USER}>`,
        to: after.email,
        subject: "❌ Tu cuenta no pudo ser aprobada en SKANO",
        html: rejectedEmail(
          userName,
          after.adminComment || after.admin_comment || after.rejection_reason
        ),
      });

      return;
    }
  }
);