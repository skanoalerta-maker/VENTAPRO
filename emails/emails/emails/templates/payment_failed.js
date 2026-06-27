module.exports = ({ fullName }) => ({
  subject: "💳 No pudimos procesar tu pago en SKANO",
  html: `
    <div style="font-family:Arial;background:#0b0b0b;padding:24px">
      <div style="max-width:640px;margin:auto;background:#111;border-radius:16px;padding:24px;color:#ffffff">

        <!-- LOGO -->
        <div style="text-align:center;margin-bottom:20px">
          <img 
            src="https://skano.cl/assets/logo-skano.png"
            alt="SKANO"
            style="max-width:140px"
          />
        </div>

        <h2 style="color:#FF5252;text-align:center;margin-bottom:12px">
          Error al procesar el pago
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Intentamos procesar tu pago, pero no fue posible completarlo.
        </p>

        <p style="color:#ddd">
          Te recomendamos revisar tu método de pago e intentarlo nuevamente
          desde la aplicación.
        </p>

        <p style="color:#ddd">
          Mientras el pago no sea confirmado, la membresía o el servicio asociado
          permanecerá inactivo.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Pagos seguros y protección vehicular
        </p>
      </div>
    </div>
  `,
});
