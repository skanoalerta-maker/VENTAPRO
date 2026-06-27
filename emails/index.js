const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

const db = admin.firestore();

const SMTP_PASS = defineSecret("SMTP_PASS");

function buildVerificationEmail() {
  return `
    <div style="font-family: Arial, sans-serif; background:#f4f6fb; padding:24px;">
      <div style="max-width:600px; margin:auto; background:#ffffff; border-radius:12px; padding:28px; border:1px solid #e6e8ef;">
        <h2 style="color:#0A6CFF; margin-top:0;">Completa tu verificación en SKANO</h2>

        <p>Hola,</p>

        <p>Vimos que tu cuenta de <strong>SKANO</strong> aún no ha completado el proceso de verificación.</p>

        <p>Para poder acceder correctamente a las funciones de la aplicación y participar de forma segura en la comunidad, necesitamos que finalices tu verificación.</p>

        <p>Ingresa a la app SKANO y completa los pasos pendientes de validación.</p>

        <p style="background:#eef4ff; padding:14px; border-radius:8px;">
          <strong>Importante:</strong> si ya completaste tu verificación recientemente, puedes ignorar este mensaje.
        </p>

        <p>Gracias por formar parte de SKANO.</p>

        <p>
          <strong>Equipo SKANO</strong><br>
          <span style="color:#555;">Reporta seguro, los buenos somos más.</span>
        </p>
      </div>
    </div>
  `;
}

exports.sendIncompleteUsersEmails = onRequest(
  { secrets: [SMTP_PASS] },
  async (req, res) => {
    try {
      const transporter = nodemailer.createTransport({
        host: "smtp.zoho.com",
        port: 587,
        secure: false,
        auth: {
          user: "admin@skano.cl",
          pass: SMTP_PASS.value(),
        },
      });

      const mode = req.query.mode || "test";

      if (mode === "test") {
        await transporter.sendMail({
          from: '"SKANO" <admin@skano.cl>',
          to: "hernancorrealara@gmail.com",
          subject: "Prueba correo SKANO - Verificación pendiente",
          html: buildVerificationEmail(),
        });

        return res.status(200).json({
          ok: true,
          mode: "test",
          message: "Correo de prueba enviado.",
        });
      }

      if (mode !== "send") {
        return res.status(400).json({
          ok: false,
          error: "Modo inválido. Usa ?mode=test o ?mode=send",
        });
      }

      const snapshot = await db
        .collection("incomplete_users")
        .where("email_sent", "==", false)
        .limit(50)
        .get();

      if (snapshot.empty) {
        return res.status(200).json({
          ok: true,
          sent: 0,
          message: "No hay usuarios pendientes con email_sent == false.",
        });
      }

      let sent = 0;
      let failed = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const email = data.email;

        if (!email) {
          failed++;
          await doc.ref.update({
            email_error: "missing_email",
            email_error_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          continue;
        }

        try {
          await transporter.sendMail({
            from: '"SKANO" <admin@skano.cl>',
            to: email,
            subject: "Completa tu verificación en SKANO",
            html: buildVerificationEmail(),
          });

          await doc.ref.update({
            email_sent: true,
            email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
            email_error: null,
          });

          sent++;
        } catch (error) {
          failed++;
          await doc.ref.update({
            email_error: error.message,
            email_error_at: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      return res.status(200).json({
        ok: true,
        sent,
        failed,
        checked: snapshot.size,
      });
    } catch (error) {
      console.error(error);
      return res.status(500).json({
        ok: false,
        error: error.message,
      });
    }
  }
);