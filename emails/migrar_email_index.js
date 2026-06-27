const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrarEmailIndex() {
  console.log("🚀 Iniciando migración...");

  const usersSnap = await db.collection("users").get();

  let creados = 0;
  let existentes = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const uid = doc.id;
    const email = (data.email || "").trim().toLowerCase();

    if (!email) continue;

    const ref = db.collection("email_index").doc(email);
    const snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        uid: uid,
        createdAt:
          data.created_at ||
          admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Creado:", email);
      creados++;
    } else {
      existentes++;
    }
  }

  console.log("\n🔥 MIGRACIÓN TERMINADA");
  console.log("Creados:", creados);
  console.log("Ya existentes:", existentes);
}

migrarEmailIndex().catch((error) => {
  console.error("❌ Error en migración:", error);
});
