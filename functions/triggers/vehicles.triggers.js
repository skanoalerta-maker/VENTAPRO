const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

exports.onVehicleCreated = onDocumentCreated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);

exports.onVehicleUpdated = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);

exports.onVehicleApproved = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);

exports.onVehicleRejected = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);

exports.onVehicleRecovered = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (_event) => {
    return;
  }
);