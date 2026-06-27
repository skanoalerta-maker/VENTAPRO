const { onDocumentUpdated } =
  require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { sendEmail } = require("../services/email_service");

// Templates
const membershipActivated = require("../emails/templates/membership_activated");
const membershipExpiring = require("../emails/templates/membership_expiring");
const membershipExpired = require("../emails/templates/membership_expired");
const paymentFailed = require("../emails/templates/payment_failed");

/* =====================================================
   ⭐ MEMBRESÍA ACTIVADA (NO MP)
   ===================================================== */
exports.onMembershipActivated = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.membership_active !== true &&
      after.membership_active === true &&
      !after.mp_activated // evita duplicar MP
    ) {
      if (!after.email) return;

      await sendEmail({
        to: after.email,
        ...membershipActivated({
          fullName: after.full_name || "Usuario SKANO",
          plan: after.membership_plan || "SKANO",
        }),
      });
    }
  }
);

/* =====================================================
   ⏰ MEMBRESÍA POR VENCER
   (admin o job que marque membership_expiring_days)
   ===================================================== */
exports.onMembershipExpiring = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.membership_expiring_days !== after.membership_expiring_days &&
      after.membership_expiring_days > 0 &&
      after.membership_active === true
    ) {
      if (!after.email) return;

      await sendEmail({
        to: after.email,
        ...membershipExpiring({
          fullName: after.full_name || "Usuario SKANO",
          days: after.membership_expiring_days,
        }),
      });
    }
  }
);

/* =====================================================
   ❌ MEMBRESÍA VENCIDA
   ===================================================== */
exports.onMembershipExpired = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.membership_active === true &&
      after.membership_active === false &&
      after.membership_expired === true
    ) {
      if (!after.email) return;

      await sendEmail({
        to: after.email,
        ...membershipExpired({
          fullName: after.full_name || "Usuario SKANO",
        }),
      });
    }
  }
);

/* =====================================================
   💳 ERROR DE PAGO
   ===================================================== */
exports.onPaymentError = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.payment_error !== true &&
      after.payment_error === true
    ) {
      if (!after.email) return;

      await sendEmail({
        to: after.email,
        ...paymentFailed({ // ✅ AQUÍ ESTÁ EL FIX
          fullName: after.full_name || "Usuario SKANO",
        }),
      });
    }
  }
);