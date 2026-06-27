const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function normalizarRut(value) {
  return String(value || "")
    .replace(/\./g, "")
    .replace(/-/g, "")
    .replace(/\s+/g, "")
    .trim()
    .toLowerCase()
    .replace(/k$/, "k");
}

async function migrarRutIndex() {
  console.log("🚀 Iniciando migración de RUT...");

  const usersSnap = await db.collection("users").get();

  let creados = 0;
  let existentes = 0;
  let omitidos = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const uid = doc.id;

    let rut =
      data.rut_normalized ||
      data.nationalId ||
      data.rut ||
      "";

    rut = normalizarRut(rut);

    if (!rut) {
      omitidos++;
      continue;
    }

    const ref = db.collection("rut_index").doc(rut);
    const snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        uid: uid,
        createdAt:
          data.created_at ||
          admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Creado:", rut);
      creados++;
    } else {
      existentes++;
    }
  }

  console.log("\n🔥 MIGRACIÓN RUT TERMINADA");
  console.log("Creados:", creados);
  console.log("Ya existentes:", existentes);
  console.log("Omitidos:", omitidos);
}

migrarRutIndex().catch((error) => {
  console.error("❌ Error en migración RUT:", error);
});