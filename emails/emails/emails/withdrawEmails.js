const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const transporter = nodemailer.createTransport({
  host: functions.config().smtp.host,
  port: functions.config().smtp.port,
  secure: false,
  auth: {
    user: functions.config().smtp.user,
    pass: functions.config().smtp.pass,
  },
});

// ================= RETIRO SOLICITADO =================
exports.withdrawRequested = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before.withdraw_request && after.withdraw_request === true) {
      const email = after.email;
      const amount = after.withdraw_amount;

      await transporter.sendMail({
        from: "SKANO <admin@skano.cl>",
        to: email,
        subject: "Solicitud de retiro recibida",
        html: `
          <h2>Solicitud de retiro recibida</h2>
          <p>Hemos recibido tu solicitud de retiro por <b>$${amount}</b>.</p>
          <p>Será revisada y procesada por nuestro equipo.</p>
          <br>
          <p>SKANO</p>
        `,
      });

      await transporter.sendMail({
        from: "SKANO <admin@skano.cl>",
        to: "admin@skano.cl",
        subject: "Nuevo retiro solicitado",
        html: `
          <h3>Nuevo retiro solicitado</h3>
          <p>Usuario: ${email}</p>
          <p>Monto: $${amount}</p>
        `,
      });
    }
  });

// ================= RETIRO PAGADO =================
exports.withdrawPaid = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.withdraw_request === true && after.withdraw_request === false && before.withdraw_amount > 0) {
      await transporter.sendMail({
        from: "SKANO <admin@skano.cl>",
        to: after.email,
        subject: "Tu retiro fue pagado",
        html: `
          <h2>Retiro pagado</h2>
          <p>Tu retiro por <b>$${before.withdraw_amount}</b> fue procesado correctamente.</p>
          <p>Gracias por usar SKANO.</p>
        `,
      });
    }
  });

// ================= RETIRO RECHAZADO =================
exports.withdrawRejected = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.withdraw_request === true && after.withdraw_request === false && before.withdraw_amount === 0) {
      await transporter.sendMail({
        from: "SKANO <admin@skano.cl>",
        to: after.email,
        subject: "Retiro rechazado",
        html: `
          <h2>Retiro rechazado</h2>
          <p>Tu solicitud de retiro fue rechazada.</p>
          <p>Si crees que es un error, contáctanos.</p>
        `,
      });
    }
  });
