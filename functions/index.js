const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
setGlobalOptions({ region: "us-central1", memory: "256MiB", timeoutSeconds: 60 });

const db = admin.firestore();

// ===================== EMAIL CONFIG =====================
const MAIL_USER = "admin@skano.cl";
const MAIL_PASS = "V8mSnb2YbJNg";
const ADMIN_EMAIL = "skano.oficial@gmail.com";

const transporter = nodemailer.createTransport({
  host: "smtp.zoho.com",
  port: 587,
  secure: false,
  auth: {
    user: MAIL_USER,
    pass: MAIL_PASS,
  },
});

function formatLocation(location) {
  if (!location) return "No disponible";

  const lat = location.latitude ?? location._latitude;
  const lng = location.longitude ?? location._longitude;

  if (lat == null || lng == null) return "No disponible";

  return `${lat}, ${lng}`;
}

async function getUserEmail(uid) {
  if (!uid) return null;

  const snap = await db.collection("users").doc(uid).get();
  const data = snap.data() || {};

  return data.email || data.email_normalized || null;
}

async function sendMailSafe({ to, subject, text, html }) {
  if (!to) return;

  await transporter.sendMail({
    from: `"SKANO 🚨" <${MAIL_USER}>`,
    to,
    subject,
    text,
    html,
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
// ===================== CONFIG MERCADO PAGO =====================
const MP_ACCESS_TOKEN =
  process.env.MERCADOPAGO_ACCESS_TOKEN ||
  (process.env.FIREBASE_CONFIG ? undefined : undefined);

const ACCESS_TOKEN = MP_ACCESS_TOKEN;

if (!ACCESS_TOKEN) {
  console.warn("⚠️ No se encontró MERCADOPAGO_ACCESS_TOKEN / functions.config().mercadopago.access_token");
}

// ===================== HELPERS =====================
function getVehicleAmount({ companyMode = false, companyVehicleCount = 1 }) {
  if (!companyMode) return 16990;

  if (companyVehicleCount <= 5) return 16990;
  if (companyVehicleCount <= 10) return 14990;
  if (companyVehicleCount <= 20) return 12990;
  return 10990;
}

function buildExternalReference({ uid, vehicleId }) {
  return `SKANO|vehicle_activation|${uid}|${vehicleId}|${Date.now()}`;
}

async function mpFetch(url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${ACCESS_TOKEN}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  const text = await res.text();
  let data = {};

  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = { raw: text };
  }

  if (!res.ok) {
    throw new Error(`Mercado Pago error ${res.status}: ${JSON.stringify(data)}`);
  }

  return data;
}

// ===================== CREATE PREFERENCE =====================
exports.createVehiclePreference = onCall(async (request) => {
  if (!ACCESS_TOKEN) {
    throw new HttpsError("failed-precondition", "Mercado Pago no está configurado.");
  }

  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const { vehicleId } = request.data || {};
  if (!vehicleId || typeof vehicleId !== "string") {
    throw new HttpsError("invalid-argument", "vehicleId es obligatorio.");
  }

  const uid = auth.uid;

  const vehicleRef = db.collection("vehicles").doc(vehicleId);
  const vehicleSnap = await vehicleRef.get();

  if (!vehicleSnap.exists) {
    throw new HttpsError("not-found", "Vehículo no encontrado.");
  }

  const vehicle = vehicleSnap.data();

  if (vehicle.uid !== uid && vehicle.owner_uid !== uid) {
    throw new HttpsError("permission-denied", "Este vehículo no pertenece al usuario.");
  }

  if (vehicle.payment_status === "paid" || vehicle.activation_status === "active") {
    throw new HttpsError("already-exists", "Este vehículo ya fue activado.");
  }

  const plate = (vehicle.plate || "").toString().trim().toUpperCase();
  const companyMode = vehicle.plan_type === "company";
  const companyVehicleCount = Number(vehicle.company_vehicle_count || 1);

  const amount = getVehicleAmount({ companyMode, companyVehicleCount });
  const externalReference = buildExternalReference({ uid, vehicleId });

  const preferenceBody = {
    items: [
      {
        id: vehicleId,
        title: `Activación vehículo SKANO ${plate || vehicleId}`,
        description: "Activación de vehículo robado en SKANO",
        quantity: 1,
        currency_id: "CLP",
        unit_price: amount,
      },
    ],
    external_reference: externalReference,
    notification_url: "https://us-central1-skano-app-e734d.cloudfunctions.net/mercadoPagoWebhook",
    metadata: {
      uid,
      vehicleId,
      plate,
      payment_type: "vehicle_activation",
    },
    back_urls: {
      success: "https://skano.cl/payment-success",
      failure: "https://skano.cl/payment-failure",
      pending: "https://skano.cl/payment-pending",
    },
    auto_return: "approved",
  };

  const preference = await mpFetch(
    "https://api.mercadopago.com/checkout/preferences",
    {
      method: "POST",
      body: JSON.stringify(preferenceBody),
    }
  );

  const paymentRef = db.collection("vehicle_payments").doc();

  await paymentRef.set({
    uid,
    vehicleId,
    plate,
    amount,
    currency: "CLP",
    status: "pending",
    payment_type: "vehicle_activation",
    mp_preference_id: preference.id || null,
    mp_init_point: preference.init_point || null,
    mp_sandbox_init_point: preference.sandbox_init_point || null,
    external_reference: externalReference,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await vehicleRef.set(
    {
      payment_required: true,
      payment_status: "pending",
      activation_status: "inactive",
      vehicle_price: amount,
      last_payment_reference: externalReference,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    ok: true,
    initPoint: preference.init_point,
    sandboxInitPoint: preference.sandbox_init_point,
    preferenceId: preference.id,
    externalReference,
    amount,
  };
});

// ===================== WEBHOOK MERCADO PAGO =====================
exports.mercadoPagoWebhook = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST" && req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const body = req.body || {};
    const query = req.query || {};

    const topic = body.type || body.topic || query.type || query.topic;
    const resourceId =
      body?.data?.id ||
      query["data.id"] ||
      query.id ||
      body.id;

    console.log("Webhook recibido:", { topic, resourceId, body, query });

    if (topic !== "payment" || !resourceId) {
      res.status(200).send("ignored");
      return;
    }

    const payment = await mpFetch(`https://api.mercadopago.com/v1/payments/${resourceId}`, {
      method: "GET",
    });

    const externalReference = payment.external_reference;

    if (!externalReference) {
      console.warn("Pago sin external_reference:", payment.id);
      res.status(200).send("ok-no-external-reference");
      return;
    }

    const paymentsQuery = await db
      .collection("vehicle_payments")
      .where("external_reference", "==", externalReference)
      .limit(1)
      .get();

    if (paymentsQuery.empty) {
      console.warn("No se encontró vehicle_payment para:", externalReference);
      res.status(200).send("ok-no-payment-doc");
      return;
    }

    const paymentDoc = paymentsQuery.docs[0];
    const paymentData = paymentDoc.data();
    const vehicleId = paymentData.vehicleId;

    const newStatus = payment.status || "unknown";
    const approved = newStatus === "approved";

    await paymentDoc.ref.set(
      {
        status: newStatus,
        mp_payment_id: payment.id || null,
        mp_status: payment.status || null,
        mp_status_detail: payment.status_detail || null,
        payer_email: payment.payer?.email || null,
        paid_at: payment.date_approved || null,
        raw_payment: payment,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    if (approved && vehicleId) {
      await db.collection("vehicles").doc(vehicleId).set(
        {
          payment_status: "paid",
          activation_status: "active",
          active: true,
          paid_at: admin.firestore.FieldValue.serverTimestamp(),
          mp_payment_id: payment.id || null,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    res.status(200).send("ok");
  } catch (error) {
    console.error("❌ Webhook error:", error);
    res.status(500).send("error");
  }
});

// ===================== EMAIL: VEHÍCULO NO ENCONTRADO =====================
exports.onVehicleNotFound = onDocumentUpdated("reports/{reportId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const reportId = event.params.reportId;

  if (before.status === "vehicle_not_found" || after.status !== "vehicle_not_found") {
    return;
  }

  try {
    const plate = after.plate || "Sin patente";
    const locationText = formatLocation(after.location);

    const ownerEmail = await getUserEmail(after.owner_uid);
    const reporterEmail = await getUserEmail(after.reporter_uid);

    await sendMailSafe({
      to: ownerEmail,
      subject: "🚨 SKANO – Vehículo no encontrado en el lugar",
      text: `
Hola,

Tu vehículo fue reportado mediante SKANO, sin embargo, al momento del seguimiento, el vehículo ya no se encontraba en el lugar.

Patente: ${plate}
Ubicación del avistamiento: ${locationText}

Este evento queda registrado como evidencia dentro del sistema SKANO.

Recomendación:
Mantén activo tu vehículo en la plataforma para recibir nuevos reportes.

Equipo SKANO
www.skano.cl
      `,
    });

    await sendMailSafe({
      to: reporterEmail,
      subject: "📄 SKANO – Reporte cerrado como vehículo no encontrado",
      text: `
Hola,

Tu reporte fue registrado correctamente.

El vehículo reportado ya no se encontraba en el lugar al momento del seguimiento.

Patente: ${plate}
Ubicación registrada: ${locationText}

Gracias por colaborar con la comunidad SKANO.

Equipo SKANO
      `,
    });

    await sendMailSafe({
      to: ADMIN_EMAIL,
      subject: "📊 SKANO – Reporte cerrado sin recuperación",
      text: `
Nuevo evento registrado en SKANO.

Estado: VEHÍCULO NO ENCONTRADO
Report ID: ${reportId}
Patente: ${plate}
Reportante UID: ${after.reporter_uid || "No disponible"}
Dueño UID: ${after.owner_uid || "No disponible"}
Ubicación: ${locationText}

El vehículo queda disponible para futuros reportes si sigue activo como robado.
      `,
    });

    await event.data.after.ref.set(
      {
        vehicle_not_found_email_sent: true,
        vehicle_not_found_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        vehicle_not_found_email_pending: false,
      },
      { merge: true }
    );

    console.log("✅ Correos vehicle_not_found enviados:", reportId);
  } catch (error) {
    console.error("❌ Error enviando correos vehicle_not_found:", error);

    await event.data.after.ref.set(
      {
        vehicle_not_found_email_error: String(error?.message || error),
        vehicle_not_found_email_pending: true,
      },
      { merge: true }
    );
  }
});

// ===================== EMAIL: RECUPERACIÓN COMPLETADA =====================
exports.onRecoveryCompleted = onDocumentUpdated("reports/{reportId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const reportId = event.params.reportId;

  if (before.status === "recovery_completed" || after.status !== "recovery_completed") {
    return;
  }

  try {
    const plate = after.plate || "Sin patente";
    const locationText = formatLocation(after.location);

    const ownerEmail = await getUserEmail(after.owner_uid);
    const reporterEmail = await getUserEmail(after.reporter_uid);

    const policeStation = after.police_station || "No informado";
    const policeCaseNumber = after.police_case_number || "No informado";
    const destination = after.police_transfer_destination || "No informado";

    await sendMailSafe({
      to: ownerEmail,
      subject: "🚓 SKANO – Reporte final de recuperación",
      text: `
Hola,

Tu vehículo registra un procedimiento completado en SKANO.

Patente: ${plate}
Ubicación del reporte: ${locationText}

Datos del procedimiento:
Comisaría / unidad: ${policeStation}
N° parte / denuncia: ${policeCaseNumber}
Destino del vehículo: ${destination}

Evidencia registrada:
- Foto del vehículo enviada por el reportante
- Foto del procedimiento con Carabineros
- Ubicación del avistamiento

Importante:
SKANO no reemplaza a las autoridades. Toda recuperación debe ser gestionada por Carabineros de Chile.

Equipo SKANO
www.skano.cl
      `,
    });

    await sendMailSafe({
      to: reporterEmail,
      subject: "✅ SKANO – Reporte final completado",
      text: `
Hola,

Tu reporte fue completado correctamente.

Patente: ${plate}
Estado: Recuperación completada
Recompensa: pendiente de revisión/pago

Gracias por ayudar a la comunidad SKANO.

Equipo SKANO
      `,
    });

    await sendMailSafe({
      to: ADMIN_EMAIL,
      subject: "📊 SKANO – Reporte final completado",
      text: `
Reporte final completado en SKANO.

Report ID: ${reportId}
Patente: ${plate}
Reportante UID: ${after.reporter_uid || "No disponible"}
Dueño UID: ${after.owner_uid || "No disponible"}

Ubicación: ${locationText}
Comisaría / unidad: ${policeStation}
N° parte / denuncia: ${policeCaseNumber}
Destino del vehículo: ${destination}

Reward status: ${after.reward_status || "No disponible"}
      `,
    });

    await event.data.after.ref.set(
      {
        owner_recovery_email_sent: true,
        owner_recovery_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        owner_recovery_email_pending: false,

        reporter_recovery_email_sent: true,
        reporter_recovery_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),

        admin_recovery_email_sent: true,
        admin_recovery_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log("✅ Correos recovery_completed enviados:", reportId);
  } catch (error) {
    console.error("❌ Error enviando correos recovery_completed:", error);

    await event.data.after.ref.set(
      {
        recovery_email_error: String(error?.message || error),
        owner_recovery_email_pending: true,
      },
      { merge: true }
    );
  }
});
// ===================== EMAIL: REPORTE INICIAL =====================
exports.onInitialReportCreated = onDocumentCreated("reports/{reportId}", async (event) => {
  const report = event.data.data();
  const reportId = event.params.reportId;

  // 🔒 Solo si es reporte real
  if (!report || report.status !== "active_report") return;

  // 🔒 Evitar duplicados
  if (report.initial_report_email_sent === true) return;

  try {
    const plate = report.plate || "Sin patente";
    const locationText = formatLocation(report.location);

    const ownerEmail = await getUserEmail(report.owner_uid);
    const reporterEmail = await getUserEmail(report.reporter_uid);

const gpsUrl = `https://www.google.com/maps?q=${locationText}`;

const ownerVehiclePhoto =
  report.vehicle_photo_url ||
  report.vehiclePhotoUrl ||
  report.photoUrl ||
  "";

const reporterPhoto =
  report.reporter_photo_url ||
  "";

const vehiclePhoto =
  reporterPhoto ||
  ownerVehiclePhoto ||
  "";
// 📧 DUEÑO
await sendMailSafe({
  to: ownerEmail,
  subject: "🚨 SKANO – Posible avistamiento detectado",
  html: `
  <div style="margin:0;padding:0;background:#050816;font-family:Arial,Helvetica,sans-serif;color:#ffffff;">
    <div style="max-width:680px;margin:0 auto;background:#07091F;border-radius:18px;overflow:hidden;border:1px solid #123A7A;">

      <div style="background:linear-gradient(135deg,#020617,#0A6CFF);padding:24px 26px;">
        <div style="font-size:13px;letter-spacing:1.5px;color:#BFD7FF;font-weight:bold;">SKANO ALERTA</div>
        <h1 style="margin:8px 0 0 0;font-size:26px;line-height:1.15;color:#ffffff;">
          🚨 Posible avistamiento detectado
        </h1>
        <p style="margin:10px 0 0 0;color:#D8E6FF;font-size:15px;">
          Un miembro de la comunidad SKANO reportó un vehículo registrado en nuestra plataforma.
        </p>
      </div>

      <div style="padding:24px 26px;">

        <div style="background:#0B1224;border:1px solid #1B3E78;border-radius:16px;padding:16px;margin-bottom:18px;">
          <p style="margin:0;color:#8FB6FF;font-size:12px;font-weight:bold;letter-spacing:1px;">PATENTE REPORTADA</p>
          <p style="margin:6px 0 0 0;font-size:28px;font-weight:bold;color:#ffffff;">${plate}</p>
          <p style="margin:10px 0 0 0;color:#D1D5DB;font-size:14px;">
            Ubicación registrada: <strong>${locationText}</strong>
          </p>
        </div>

        <div style="margin-bottom:18px;">
          <p style="margin:0 0 10px 0;color:#ffffff;font-size:17px;font-weight:bold;">
            Estado del procedimiento
          </p>

          <div style="background:#08111F;border-radius:14px;padding:14px;border:1px solid #1F2A44;">
            <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Reporte recibido por SKANO</p>
            <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Evidencia fotográfica registrada</p>
            <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Ubicación GPS asociada</p>
            <p style="margin:0;color:#FACC15;">⏳ Procedimiento en revisión / ejecución</p>
          </div>
        </div>

        <div style="margin-bottom:18px;">
          <p style="margin:0 0 12px 0;color:#ffffff;font-size:17px;font-weight:bold;">
            Evidencia del reporte
          </p>

          <div style="display:block;margin-bottom:16px;">
            <p style="margin:0 0 8px 0;color:#93C5FD;font-size:14px;font-weight:bold;">
              📸 Foto registrada del vehículo
            </p>
            ${
              ownerVehiclePhoto
                ? `<img src="${ownerVehiclePhoto}" style="width:100%;max-width:620px;border-radius:14px;border:1px solid #1F3B6D;display:block;">`
                : `<div style="padding:18px;border-radius:14px;background:#111827;color:#9CA3AF;">No hay foto registrada del propietario disponible.</div>`
            }
          </div>

          <div style="display:block;">
            <p style="margin:0 0 8px 0;color:#93C5FD;font-size:14px;font-weight:bold;">
              📸 Foto enviada por el colaborador
            </p>
            ${
              reporterPhoto
                ? `<img src="${reporterPhoto}" style="width:100%;max-width:620px;border-radius:14px;border:1px solid #1F3B6D;display:block;">`
                : `<div style="padding:18px;border-radius:14px;background:#111827;color:#9CA3AF;">No hay foto del colaborador disponible.</div>`
            }
          </div>
        </div>

        <div style="text-align:center;margin:26px 0;">
          <a href="${gpsUrl}"
             style="display:inline-block;background:#0A6CFF;color:#ffffff;padding:16px 28px;border-radius:14px;text-decoration:none;font-weight:bold;font-size:16px;">
             📍 VER UBICACIÓN DEL REPORTE
          </a>
        </div>

        <div style="background:#111827;border:1px solid #374151;border-radius:16px;padding:16px;margin-top:18px;">
          <p style="margin:0;color:#E5E7EB;font-size:14px;line-height:1.5;">
            Nuestro equipo mantendrá el seguimiento del reporte y te informará si se recibe nueva evidencia,
            actualización del procedimiento o confirmación por autoridad competente.
          </p>
        </div>

        <p style="margin:22px 0 0 0;color:#9CA3AF;font-size:12px;line-height:1.5;">
          SKANO no reemplaza a Carabineros ni a las instituciones oficiales. No intentes recuperar el vehículo por cuenta propia.
        </p>

      </div>

      <div style="background:#020617;padding:18px 26px;text-align:center;border-top:1px solid #123A7A;">
        <p style="margin:0;color:#ffffff;font-weight:bold;font-size:15px;">SKANO</p>
        <p style="margin:4px 0 0 0;color:#8FB6FF;font-size:12px;">Detecta • Reporta • Protege</p>
      </div>

    </div>
  </div>
  `,
});

// 📧 REPORTANTE
await sendMailSafe({
  to: reporterEmail,
  subject: "✅ SKANO – Reporte recibido correctamente",
  html: `
  <div style="margin:0;padding:0;background:#050816;font-family:Arial,Helvetica,sans-serif;color:#ffffff;">
    <div style="max-width:680px;margin:0 auto;background:#07091F;border-radius:18px;overflow:hidden;border:1px solid #123A7A;">

      <div style="background:linear-gradient(135deg,#020617,#0A6CFF);padding:24px 26px;">
        <div style="font-size:13px;letter-spacing:1.5px;color:#BFD7FF;font-weight:bold;">SKANO COMUNIDAD</div>
        <h1 style="margin:8px 0 0 0;font-size:26px;color:#ffffff;">
          ✅ Reporte recibido correctamente
        </h1>
        <p style="margin:10px 0 0 0;color:#D8E6FF;">
          Gracias por colaborar con la comunidad SKANO.
        </p>
      </div>

      <div style="padding:24px 26px;">
        <p style="margin:0;color:#8FB6FF;font-size:12px;font-weight:bold;">PATENTE REPORTADA</p>
        <p style="margin:6px 0 0 0;font-size:28px;font-weight:bold;color:#ffffff;">${plate}</p>
        <p style="margin:10px 0 0 0;color:#D1D5DB;font-size:14px;">
          Ubicación registrada: <strong>${locationText}</strong>
        </p>

        <div style="margin:18px 0;background:#08111F;border-radius:14px;padding:14px;border:1px solid #1F2A44;">
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Reporte recibido</p>
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Evidencia almacenada</p>
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Ubicación GPS registrada</p>
          <p style="margin:0;color:#FACC15;">⏳ En revisión por SKANO</p>
        </div>

        ${
          vehiclePhoto
            ? `<img src="${vehiclePhoto}" style="width:100%;max-width:620px;border-radius:14px;border:1px solid #1F3B6D;">`
            : ``
        }

        <div style="text-align:center;margin:26px 0;">
          <a href="${gpsUrl}"
             style="display:inline-block;background:#0A6CFF;color:#ffffff;padding:16px 28px;border-radius:14px;text-decoration:none;font-weight:bold;font-size:16px;">
             📍 VER UBICACIÓN DEL REPORTE
          </a>
        </div>

        <div style="background:#111827;border:1px solid #374151;border-radius:16px;padding:16px;">
          <p style="margin:0;color:#E5E7EB;font-size:14px;line-height:1.5;">
            Tu colaboración ayuda a la detección de vehículos con encargo por robo.
            Si agregas más información posteriormente, será revisada por el equipo SKANO antes de ser compartida con el propietario.
          </p>
        </div>
      </div>

      <div style="background:#020617;padding:18px 26px;text-align:center;border-top:1px solid #123A7A;">
        <p style="margin:0;color:#ffffff;font-weight:bold;font-size:15px;">SKANO</p>
        <p style="margin:4px 0 0 0;color:#8FB6FF;font-size:12px;">Detecta • Reporta • Protege</p>
      </div>

    </div>
  </div>
  `,
});

// 📧 ADMIN
await sendMailSafe({
  to: ADMIN_EMAIL,
  subject: `🚨 SKANO ADMIN – Nuevo reporte (${plate})`,
  html: `
  <div style="margin:0;padding:0;background:#050816;font-family:Arial,Helvetica,sans-serif;color:#ffffff;">
    <div style="max-width:760px;margin:0 auto;background:#07091F;border-radius:18px;overflow:hidden;border:1px solid #123A7A;">

      <div style="background:linear-gradient(135deg,#020617,#0A6CFF);padding:24px 26px;">
        <div style="font-size:13px;letter-spacing:1.5px;color:#BFD7FF;font-weight:bold;">
          SKANO ADMIN
        </div>

        <h1 style="margin:8px 0 0 0;font-size:26px;color:#ffffff;">
          🚨 Nuevo reporte recibido
        </h1>

        <p style="margin:10px 0 0 0;color:#D8E6FF;">
          Un usuario de la comunidad ha enviado un nuevo reporte.
        </p>
      </div>

      <div style="padding:24px;">

        <div style="background:#0B1224;border:1px solid #1B3E78;border-radius:16px;padding:18px;margin-bottom:20px;">
          <table style="width:100%;color:white;">
            <tr>
              <td style="padding:6px 0;"><strong>ID Reporte:</strong></td>
              <td>${reportId}</td>
            </tr>

            <tr>
              <td style="padding:6px 0;"><strong>Patente:</strong></td>
              <td>${plate}</td>
            </tr>

            <tr>
              <td style="padding:6px 0;"><strong>Ubicación:</strong></td>
              <td>${locationText}</td>
            </tr>

            <tr>
              <td style="padding:6px 0;"><strong>Fecha:</strong></td>
              <td>${new Date().toLocaleString("es-CL")}</td>
            </tr>
          </table>
        </div>

        <div style="background:#08111F;border-radius:14px;padding:14px;border:1px solid #1F2A44;margin-bottom:20px;">
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Reporte almacenado</p>
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Evidencia recibida</p>
          <p style="margin:0 0 8px 0;color:#CFFAFE;">✅ Ubicación GPS registrada</p>
          <p style="margin:0;color:#FACC15;">⏳ Pendiente revisión administrativa</p>
        </div>

        <h3 style="color:white;margin-bottom:10px;">
          📸 Evidencia recibida
        </h3>

        ${
          vehiclePhoto
            ? `
            <img
              src="${vehiclePhoto}"
              style="
                width:100%;
                max-width:650px;
                border-radius:14px;
                border:1px solid #1F3B6D;
                display:block;
              ">
          `
            : `
            <div style="
              padding:18px;
              border-radius:14px;
              background:#111827;
              color:#9CA3AF;
            ">
              No se recibió imagen.
            </div>
          `
        }

        <div style="text-align:center;margin:26px 0;">
          <a href="${gpsUrl}"
             style="
               display:inline-block;
               background:#0A6CFF;
               color:white;
               padding:16px 28px;
               border-radius:14px;
               text-decoration:none;
               font-weight:bold;
               font-size:16px;
             ">
             📍 VER UBICACIÓN GPS
          </a>
        </div>

        <div style="
          background:#111827;
          border:1px solid #374151;
          border-radius:16px;
          padding:16px;
        ">
          <p style="margin:0;color:#E5E7EB;font-size:14px;line-height:1.5;">
            Acciones sugeridas:
          </p>

          <ul style="color:#D1D5DB;line-height:1.8;">
            <li>Revisar fotografía.</li>
            <li>Verificar ubicación.</li>
            <li>Validar reporte.</li>
            <li>Contactar propietario si corresponde.</li>
            <li>Solicitar evidencia adicional si es necesario.</li>
          </ul>
        </div>

      </div>

      <div style="
        background:#020617;
        padding:18px;
        text-align:center;
        border-top:1px solid #123A7A;
      ">
        <p style="margin:0;color:white;font-weight:bold;">
          SKANO ADMIN
        </p>

        <p style="margin:4px 0 0 0;color:#8FB6FF;font-size:12px;">
          Detecta • Reporta • Protege
        </p>
      </div>

    </div>
  </div>
  `,
});

    // 🔄 Marcar como enviado
    await event.data.ref.set({
      initial_report_email_sent: true,
      initial_report_email_pending: false,
      initial_report_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log("✅ Correos iniciales enviados:", reportId);

  } catch (error) {
    console.error("❌ Error correo inicial:", error);

    await event.data.ref.set({
      initial_report_email_error: String(error?.message || error),
      initial_report_email_pending: true,
    }, { merge: true });
  }
});
// ===================== TEMP: IMPORTAR USUARIOS INCOMPLETOS =====================
exports.importIncompleteUsers = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const adminSnap = await db.collection("users").doc(auth.uid).get();
  const adminData = adminSnap.data() || {};

  if (adminData.role !== "admin") {
    throw new HttpsError("permission-denied", "Solo admin puede ejecutar esta función.");
  }

  let created = 0;
  let skippedApproved = 0;
  let skippedAlreadyExists = 0;
  let checked = 0;

  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);

    for (const user of result.users) {
      checked++;

      const uid = user.uid;
      const email = user.email || "";

      if (!email) continue;

      const userRef = db.collection("users").doc(uid);
      const userSnap = await userRef.get();

      let isApproved = false;

      if (userSnap.exists) {
        const data = userSnap.data() || {};
        isApproved = data.verification_status === "approved";
      }

      if (isApproved) {
        skippedApproved++;
        continue;
      }

      const incompleteRef = db.collection("incomplete_users").doc(uid);
      const incompleteSnap = await incompleteRef.get();

      if (incompleteSnap.exists) {
        skippedAlreadyExists++;
        continue;
      }

      await incompleteRef.set({
        uid,
        email,
        displayName: user.displayName || "",
        phoneNumber: user.phoneNumber || "",
        createdAt: user.metadata?.creationTime || null,
        lastSignInTime: user.metadata?.lastSignInTime || null,
        source: userSnap.exists ? "users_not_approved" : "auth_without_user_profile",
        reason: userSnap.exists ? "verification_not_approved" : "auth_user_without_profile",
        email_sent: false,
        imported_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      created++;
    }

    nextPageToken = result.pageToken;
  } while (nextPageToken);

  return {
    ok: true,
    checked,
    created,
    skippedApproved,
    skippedAlreadyExists,
  };
});
// ===================== TEMP: IMPORTAR EMAIL INDEX DESDE AUTH =====================
exports.importEmailIndexFromAuth = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const adminSnap = await db.collection("users").doc(auth.uid).get();
  const adminData = adminSnap.data() || {};

  if (adminData.role !== "admin") {
    throw new HttpsError("permission-denied", "Solo admin puede ejecutar esta función.");
  }

  let checked = 0;
  let createdOrUpdated = 0;
  let skippedWithoutEmail = 0;

  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);

    for (const user of result.users) {
      checked++;

      if (!user.email) {
        skippedWithoutEmail++;
        continue;
      }

      const email = user.email.trim().toLowerCase();

      await db.collection("email_index").doc(email).set({
        uid: user.uid,
        email,
        displayName: user.displayName || "",
        phoneNumber: user.phoneNumber || "",
        createdAt: user.metadata?.creationTime || null,
        lastSignInTime: user.metadata?.lastSignInTime || null,
        source: "firebase_auth",
        active: true,
        marketing_email_sent: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      createdOrUpdated++;
    }

    nextPageToken = result.pageToken;
  } while (nextPageToken);

  return {
    ok: true,
    checked,
    createdOrUpdated,
    skippedWithoutEmail,
  };
});
// ===================== AUDIT AUTH VS USERS =====================
exports.auditAuthVsUsers = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debes iniciar sesión."
    );
  }

  const adminSnap = await db.collection("users").doc(auth.uid).get();
  const adminData = adminSnap.data() || {};

  if (adminData.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Solo admin puede ejecutar esta función."
    );
  }

  let authCount = 0;
  let usersFound = 0;
  let missingUsers = 0;

  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(
      1000,
      nextPageToken
    );

    for (const user of result.users) {
      authCount++;

      const uid = user.uid;

      const userSnap = await db
        .collection("users")
        .doc(uid)
        .get();

      if (userSnap.exists) {
        usersFound++;
        continue;
      }

      missingUsers++;

      await db
        .collection("missing_users")
        .doc(uid)
        .set(
          {
            uid,
            email: user.email || "",
            displayName: user.displayName || "",
            phoneNumber: user.phoneNumber || "",
            creationTime:
              user.metadata?.creationTime || null,
            lastSignInTime:
              user.metadata?.lastSignInTime || null,
            reason: "auth_without_user_profile",
            detectedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    }

    nextPageToken = result.pageToken;
  } while (nextPageToken);

  return {
    ok: true,
    authCount,
    usersFound,
    missingUsers,
  };
});
// ===================== EMAIL: VEHÍCULOS ROBADOS ACTIVOS =====================

function buildRecoveryCheckEmail(plate) {
  return `
Hola,

Te escribimos desde SKANO porque tu vehículo aún figura como ROBADO ACTIVO dentro de nuestra plataforma.

Patente: ${plate}

Queremos confirmar si el vehículo ya fue recuperado por Carabineros, por otra institución o por gestión propia.

Si tu vehículo ya fue recuperado, por favor ingresa a SKANO y actualiza el estado del caso o contáctanos.

Esto nos ayuda a mantener la información actualizada y evitar reportes innecesarios.

Si el vehículo continúa robado, no debes realizar ninguna acción.

Equipo SKANO
Reporta seguro, los buenos somos más.
www.skano.cl
`;
}

exports.sendActiveStolenVehicleCheckEmails = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debes iniciar sesión."
    );
  }

  const adminSnap = await db.collection("users").doc(auth.uid).get();
  const adminData = adminSnap.data() || {};

  if (adminData.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Solo admin puede ejecutar esta función."
    );
  }

  const limit = Number(request.data?.limit || 40);

  const snapshot = await db
    .collection("stolen_vehicles")
    .where("status", "==", "stolen")
    .where("active", "==", true)
    .limit(limit)
    .get();

  let checked = 0;
  let sent = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    checked++;

    try {
      const data = doc.data();

      const ownerEmail =
          (data.ownerEmail || "").toString().trim().toLowerCase();

      if (!ownerEmail) {
        failed++;
        continue;
      }

      const plate =
          (data.plate || "SIN PATENTE").toString().toUpperCase();

await sendMailSafe({
  to: ownerEmail,
  subject: "¿Tu vehículo ya fue recuperado?",
  text: buildRecoveryCheckEmail(plate),
});

await sleep(12000);
      await doc.ref.set({
        recovery_check_email_sent_at:
            admin.firestore.FieldValue.serverTimestamp(),
        recovery_check_email_count:
            admin.firestore.FieldValue.increment(1),
      }, { merge: true });

      sent++;
    } catch (error) {
      failed++;
      console.error(error);
    }
  }

  return {
    ok: true,
    checked,
    sent,
    failed,
  };
});
// ===================== EMAIL: USUARIOS INCOMPLETOS =====================
function buildIncompleteUserEmail() {
  return `
Hola,

Vimos que tu cuenta de SKANO aún no ha completado el proceso de verificación.

Para poder acceder correctamente a las funciones de la aplicación y participar de forma segura en la comunidad, necesitamos que finalices tu verificación.

Ingresa a la app SKANO y completa los pasos pendientes de validación.

Importante: si ya completaste tu verificación recientemente, puedes ignorar este mensaje.

Gracias por formar parte de SKANO.

Equipo SKANO
Reporta seguro, los buenos somos más.
  `;
}

exports.sendIncompleteUsersEmails = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const adminSnap = await db.collection("users").doc(auth.uid).get();
  const adminData = adminSnap.data() || {};

  if (adminData.role !== "admin") {
    throw new HttpsError("permission-denied", "Solo admin puede ejecutar esta función.");
  }

  const dryRun = request.data?.dryRun !== false;
  const limit = Math.min(Number(request.data?.limit || 30), 30);
  const snapshot = await db
    .collection("incomplete_users")
    .where("email_sent", "==", false)
    .limit(limit)
    .get();

  let checked = 0;
  let sent = 0;
  let failed = 0;
  const emails = [];

  for (const doc of snapshot.docs) {
    checked++;

    const data = doc.data() || {};
    const email = (data.email || "").toString().trim().toLowerCase();

    if (!email) {
      failed++;
      await doc.ref.set({
        email_error: "missing_email",
        email_error_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      continue;
    }

    emails.push(email);

    if (dryRun) continue;

    try {
await sendMailSafe({
  to: email,
  subject: "Completa tu verificación en SKANO",
  text: buildIncompleteUserEmail(),
});

await sleep(12000);

      await doc.ref.set({
        email_sent: true,
        email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        email_error: null,
      }, { merge: true });

      sent++;
    } catch (error) {
      failed++;
      await doc.ref.set({
        email_error: String(error?.message || error),
        email_error_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }

  return {
    ok: true,
    dryRun,
    checked,
    sent,
    failed,
    emails,
  };
});
// ===================== EMAIL: VEHÍCULO EXTERNO AGREGADO =====================

exports.onExternalVehicleCreated = onDocumentCreated(
  "external_stolen_vehicles/{plate}",
  async (event) => {
    try {
      const vehicle = event.data.data();

      const email = vehicle.owner_email;

      if (!email) return;

      await sendMailSafe({
        to: email,
        subject: "🚨 Tu vehículo fue incorporado a SKANO",
        text: `
Hola ${vehicle.owner_name || ""},

Tu vehículo fue incorporado correctamente a la plataforma SKANO.

Patente: ${vehicle.plate || ""}
Marca: ${vehicle.brand || ""}
Modelo: ${vehicle.model || ""}

Mientras el encargo por robo continúe vigente, el vehículo permanecerá activo dentro de SKANO para que la comunidad pueda ayudar a localizarlo.

Gracias por confiar en nosotros.

Equipo SKANO
www.skano.cl
        `,
      });

      await event.data.ref.set({
        owner_email_sent: true,
        owner_email_sent_at:
          admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(
        "✅ Correo vehículo externo enviado:",
        vehicle.plate
      );

    } catch (error) {
      console.error(
        "❌ Error correo vehículo externo:",
        error
      );
    }
  }
);