const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
require("dotenv").config();

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

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

// ================= EMAIL TEMPLATE =================
function buildEmailHtml() {
  return `
  <!DOCTYPE html>
  <html lang="es">
  <body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif;color:#0f172a;">

    <div style="width:100%;padding:30px 0;background:#f1f5f9;">

      <div style="
        max-width:680px;
        margin:0 auto;
        background:#ffffff;
        border-radius:20px;
        overflow:hidden;
        border:1px solid #e2e8f0;
        box-shadow:0 8px 30px rgba(15,23,42,0.08);
      ">

        <!-- HEADER -->
        <div style="
          background:linear-gradient(135deg,#020617,#0f172a);
          padding:34px 30px;
          color:#ffffff;
        ">
          <div style="
            font-size:30px;
            font-weight:900;
            letter-spacing:1px;
          ">
            SKANO 🚨
          </div>

          <div style="
            margin-top:10px;
            color:rgba(255,255,255,0.85);
            font-size:14px;
            line-height:1.5;
          ">
            Red colaborativa para reportar vehículos con encargo por robo
          </div>
        </div>

        <!-- CONTENT -->
        <div style="padding:32px;">

          <h1 style="
            margin:0 0 20px;
            font-size:28px;
            color:#0f172a;
          ">
            🚨 SKANO se ha actualizado
          </h1>

          <p style="
            font-size:15px;
            line-height:1.8;
            color:#334155;
          ">
            Hemos implementado mejoras importantes de seguridad,
            estabilidad y validación de reportes.
          </p>

          <div style="
            margin:24px 0;
            padding:18px;
            border-radius:14px;
            background:#eff6ff;
            border:1px solid #bfdbfe;
          ">
            <div style="margin-bottom:10px;">✅ Mejoras en reportes</div>
            <div style="margin-bottom:10px;">✅ Mayor seguridad</div>
            <div style="margin-bottom:10px;">✅ Correcciones de estabilidad</div>
            <div>✅ Optimización general de SKANO</div>
          </div>

          <p style="
            font-size:15px;
            line-height:1.8;
            color:#334155;
          ">
            Para continuar utilizando todas las funciones de SKANO,
            actualiza la aplicación desde Google Play.
          </p>

          <div style="margin-top:30px;margin-bottom:30px;text-align:center;">
            <a
              href="https://play.google.com/store/apps/details?id=cl.skano.app"
              target="_blank"
              style="
                display:inline-block;
                background:#0A6CFF;
                color:#ffffff;
                padding:16px 28px;
                border-radius:14px;
                text-decoration:none;
                font-weight:800;
                font-size:16px;
                box-shadow:0 6px 18px rgba(10,108,255,0.35);
              "
            >
              📲 ACTUALIZAR SKANO
            </a>
          </div>

          <div style="
            margin-top:20px;
            padding:18px;
            border-radius:14px;
            background:#020617;
            color:#ffffff;
            text-align:center;
            line-height:1.8;
          ">
            🚨 Recuerda: reporta seguro.<br>
            Los buenos somos más.
          </div>

        </div>

        <!-- FOOTER -->
        <div style="
          padding:22px 30px;
          background:#f8fafc;
          border-top:1px solid #e2e8f0;
          color:#64748b;
          font-size:12px;
          line-height:1.7;
        ">
          Equipo SKANO<br>

          <a
            href="https://www.skano.cl"
            style="
              color:#0A6CFF;
              text-decoration:none;
              font-weight:700;
            "
          >
            www.skano.cl
          </a>
        </div>

      </div>
    </div>
  </body>
  </html>
  `;
}

// ================= SEND EMAILS =================
async function sendEmails() {
  console.log("🚀 Enviando correos...");

  const usersSnap = await db.collection("users").get();

  let enviados = 0;
  let errores = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();

    const email = (data.email || "").trim().toLowerCase();

    if (!email) continue;

    try {
      await transporter.sendMail({
        from: `"SKANO 🚨" <${process.env.SMTP_USER}>`,
        to: email,
        subject: "🚨 SKANO se ha actualizado",
        html: buildEmailHtml(),
      });

      console.log("✅ Enviado:", email);
      enviados++;

    } catch (e) {
      console.error("❌ Error:", email, e);
      errores++;
    }
  }

  console.log("\n🔥 PROCESO TERMINADO");
  console.log("✅ Enviados:", enviados);
  console.log("❌ Errores:", errores);
}

// ================= START =================
sendEmails()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("❌ Error general:", e);
    process.exit(1);
  });