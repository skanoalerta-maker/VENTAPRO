const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

exports.onUserUpdated = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);