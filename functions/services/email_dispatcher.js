const { sendEmail } = require("./email_service");

const templates = {
  welcome: require("../emails/templates/welcome"),
  account_blocked: require("../emails/templates/account_blocked"),

  documents_approved: require("../emails/templates/documents_approved"),
  documents_rejected: require("../emails/templates/documents_rejected"),

  vehicle_registered: require("../emails/templates/vehicle_registered"),
  vehicle_approved: require("../emails/templates/vehicle_approved"),
  vehicle_rejected: require("../emails/templates/vehicle_rejected"),
  vehicle_recovered: require("../emails/templates/vehicle_recovered"),

  report_received: require("../emails/templates/report_received"),
  report_validated: require("../emails/templates/report_validated"),
  report_rejected: require("../emails/templates/report_rejected"),

  reward_granted: require("../emails/templates/reward_granted"),

  membership_activated: require("../emails/templates/membership_activated"),
  membership_expiring: require("../emails/templates/membership_expiring"),
  membership_expired: require("../emails/templates/membership_expired"),

  payment_failed: require("../emails/templates/payment_failed"),
};

async function dispatchEmail(type, to, data) {
  if (!templates[type]) {
    throw new Error(`Plantilla de correo no existe: ${type}`);
  }

  const { subject, html } = templates[type](data);

  await sendEmail({
    to,
    subject,
    html,
  });
}

module.exports = { dispatchEmail };
