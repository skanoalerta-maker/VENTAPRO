module.exports = ({ fullName, amount }) => ({
  subject: "💰 Recompensa acreditada en SKANO",
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

        <h2 style="color:#4CAF50;text-align:center;margin-bottom:12px">
          ¡Recompensa acreditada!
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Queremos informarte que se ha acreditado una recompensa asociada
          a uno de tus reportes validados.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            💰 <strong>Monto acreditado:</strong> $${amount}
          </p>
        </div>

        <p style="color:#ddd">
          El monto ha sido registrado en tu saldo dentro de la plataforma
          y quedará disponible según las condiciones del programa de recompensas.
        </p>

        <p style="color:#ddd">
          Gracias por tu aporte responsable a la comunidad y por ayudar
          a mejorar la seguridad vehicular.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Recompensas por reportes validados
        </p>
      </div>
    </div>
  `,
});
