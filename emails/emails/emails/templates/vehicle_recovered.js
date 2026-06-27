module.exports = ({ fullName, plate }) => ({
  subject: "🎉 Tu vehículo fue recuperado",
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
          Vehículo recuperado
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Queremos informarte que tu vehículo ha sido marcado como
          <strong>recuperado</strong> dentro de la plataforma SKANO.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          Este estado indica que el proceso de búsqueda y alertas activas
          ha finalizado correctamente.
        </p>

        <p style="color:#ddd">
          Agradecemos tu confianza en SKANO y el uso responsable de la plataforma.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Tecnología y comunidad al servicio de la seguridad vehicular
        </p>
      </div>
    </div>
  `,
});
