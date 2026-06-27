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
const MAIL_PASS = "VXN19gWNqiAT";
const ADMIN_EMAIL = "admin@skano.cl";

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

async function sendMailSafe({ to, subject, text }) {
  if (!to) return;

  await transporter.sendMail({
    from: `"SKANO 🚨" <${MAIL_USER}>`,
    to,
    subject,
    text,
  });
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

    // 📧 DUEÑO
    await sendMailSafe({
      to: ownerEmail,
      subject: "🚨 SKANO – Tu vehículo fue visto",
      text: `
Tu vehículo fue detectado por la comunidad SKANO.

Patente: ${plate}
Ubicación: ${locationText}

Este es un aviso inicial del reporte.

Equipo SKANO
      `,
    });

    // 📧 REPORTANTE
    await sendMailSafe({
      to: reporterEmail,
      subject: "📄 SKANO – Reporte recibido",
      text: `
Tu reporte fue registrado correctamente.

Patente: ${plate}
Ubicación: ${locationText}

Gracias por colaborar 🚨
      `,
    });

    // 📧 ADMIN
    await sendMailSafe({
      to: ADMIN_EMAIL,
      subject: "📍 Nuevo reporte SKANO",
      text: `
ID: ${reportId}
Patente: ${plate}
Ubicación: ${locationText}
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