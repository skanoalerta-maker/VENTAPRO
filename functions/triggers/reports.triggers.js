const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { sendEmail } = require("../emails/sendEmail");

// ================== TEMPLATES ==================
const vehicleFound = require("../emails/templates/vehicle_found_with_evidence");
const reportValidated = require("../emails/templates/report_validated");
const reportRejected = require("../emails/templates/report_rejected");
const vehicleRecovered = require("../emails/templates/vehicle_recovered");

/* =====================================================
   🚨 VEHÍCULO ROBADO AVISTADO → CORREO AL DUEÑO
   ===================================================== */
exports.onVehicleFoundReport = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const report = event.data?.data();
    if (!report) return;

    const { plate, owner_uid, reporter_photo_url, location } = report;
    if (!plate || !owner_uid || !reporter_photo_url) return;

    const ownerSnap = await admin
      .firestore()
      .collection("users")
      .doc(owner_uid)
      .get();

    if (!ownerSnap.exists) return;

    const owner = ownerSnap.data();
    if (!owner?.email) return;

    await sendEmail({
      to: owner.email,
      ...vehicleFound({
        fullName: owner.full_name || "Usuario SKANO",
        plate,
        imageUrl: reporter_photo_url,
        location: location
          ? `Lat: ${location.latitude}, Lng: ${location.longitude}`
          : "Ubicación no disponible",
      }),
    });
  }
);

/* =====================================================
   ✅ REPORTE VALIDADO → CORREO AL REPORTANTE
   ===================================================== */
exports.onReportValidated = onDocumentUpdated(
  "reports/{reportId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "validated") return;

    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(after.reporter_uid)
      .get();

    if (!userSnap.exists) return;

    const user = userSnap.data();
    if (!user?.email) return;

    await sendEmail({
      to: user.email,
      ...reportValidated({ plate: after.plate }),
    });
  }
);

/* =====================================================
   ❌ REPORTE RECHAZADO → CORREO AL REPORTANTE
   ===================================================== */
exports.onReportRejected = onDocumentUpdated(
  "reports/{reportId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "rejected") return;
    if (!after.admin_comment) return;

    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(after.reporter_uid)
      .get();

    if (!userSnap.exists) return;

    const user = userSnap.data();
    if (!user?.email) return;

    await sendEmail({
      to: user.email,
      ...reportRejected({
        plate: after.plate,
        reason: after.admin_comment,
      }),
    });
  }
);

/* =====================================================
   🚗 VEHÍCULO RECUPERADO → CORREO AL DUEÑO
   ===================================================== */
exports.onVehicleRecovered = onDocumentUpdated(
  "stolen_vehicles/{vehicleId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    if (before.status === "stolen" && after.status === "recovered") {
      const ownerUid = after.owner_uid;
      if (!ownerUid) return;

      const userSnap = await admin
        .firestore()
        .collection("users")
        .doc(ownerUid)
        .get();

      if (!userSnap.exists) return;

      const user = userSnap.data();
      if (!user?.email) return;

      await sendEmail({
        to: user.email,
        ...vehicleRecovered({
          fullName: user.full_name || "Usuario SKANO",
          plate: after.plate,
        }),
      });
    }
  }
);
