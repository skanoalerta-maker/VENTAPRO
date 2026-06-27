const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

const admin = require("firebase-admin");
const { sendEmail } = require("../services/email_service");

// ✅ Template (si no lo tienes, te lo hago en el paso 2/3)
const vehicleMarkedStolen = require("../emails/templates/vehicle_marked_stolen");

if (!admin.apps.length) admin.initializeApp();

/* =====================================================
   HELPERS
   ===================================================== */
function getOwnerUid(doc) {
  return doc?.owner_uid || doc?.ownerUid || null;
}

async function getUserByUid(uid) {
  if (!uid) return null;
  const snap = await admin.firestore().collection("users").doc(uid).get();
  if (!snap.exists) return null;
  return snap.data();
}

function safeEmail(user) {
  const email = user?.email;
  if (!email || typeof email !== "string" || !email.includes("@")) return null;
  return email;
}

function normalizePlate(raw) {
  return (raw || "").toString().toUpperCase().replace(/[^A-Z0-9]/g, "");
}

/* =====================================================
   1) STOLEN VEHICLE CREATED  (stolen_vehicles/{id})
   ===================================================== */
exports.onStolenVehicleCreated = onDocumentCreated(
  "stolen_vehicles/{stolenId}",
  async (event) => {
    const doc = event.data?.data();
    if (!doc) return;

    // ✅ Solo si realmente está activo como robado
    if (doc.status !== "stolen" || doc.active !== true) return;
    if (doc.verified !== true) return; // tu ReportForm exige verified=true

    const ownerUid = getOwnerUid(doc);
    const user = await getUserByUid(ownerUid);
    const to = safeEmail(user);
    if (!to) return;

    const plate = normalizePlate(doc.plate || doc.plate_normalized);

    await sendEmail({
      to,
      ...vehicleMarkedStolen({
        fullName: user.full_name || "Usuario SKANO",
        plate,
      }),
    });
  }
);

/* =====================================================
   2) STOLEN VEHICLE RE-ACTIVATED / MARKED STOLEN
   (por si el doc existía y lo vuelves a poner stolen+active)
   ===================================================== */
exports.onStolenVehicleUpdated = onDocumentUpdated(
  "stolen_vehicles/{stolenId}",
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};

    // ✅ Condición: antes NO estaba activo como stolen, y ahora SÍ
    const beforeOk =
      before.status === "stolen" && before.active === true && before.verified === true;
    const afterOk =
      after.status === "stolen" && after.active === true && after.verified === true;

    if (beforeOk || !afterOk) return;

    const ownerUid = getOwnerUid(after);
    const user = await getUserByUid(ownerUid);
    const to = safeEmail(user);
    if (!to) return;

    const plate = normalizePlate(after.plate || after.plate_normalized);

    await sendEmail({
      to,
      ...vehicleMarkedStolen({
        fullName: user.full_name || "Usuario SKANO",
        plate,
      }),
    });
  }
);
