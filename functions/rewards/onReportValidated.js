const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 🔒 Calcula nivel según reglas SKANO
 */
function calculateLevel(hits) {
  if (hits >= 31) return "elite";
  if (hits >= 11) return "oro";
  if (hits >= 6) return "plata";
  return "bronce";
}

/**
 * 🧮 Cloud Function
 * Se dispara cuando un reporte pasa a "validated"
 */
exports.onReportValidated = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // 🔒 Solo si CAMBIA a validated
    if (before.status === "validated") return null;
    if (after.status !== "validated") return null;

    const userUid = after.userUid;
    if (!userUid) return null;

    const userRef = admin.firestore().collection("users").doc(userUid);

    await admin.firestore().runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      const user = userSnap.data();

      const hits = (user.reportes_acertados || 0) + 1;
      const total = (user.reportes_enviados || 0);

      const newLevel = calculateLevel(hits);

      tx.update(userRef, {
        reportes_acertados: hits,
        level: newLevel,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(
      `✅ Nivel actualizado para usuario ${userUid}`
    );

    return null;
  });

