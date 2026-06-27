module.exports = ({ fullName }) => ({
  subject: "✅ Tus documentos fueron aprobados",
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
          Documentos verificados correctamente
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Hemos revisado la información y los documentos que enviaste,
          y estos fueron aprobados correctamente.
        </p>

        <p style="color:#ddd">
          A partir de ahora tienes acceso completo a las funciones de SKANO
          según el estado de tu cuenta y vehículos registrados.
        </p>

        <p style="color:#ddd">
          Gracias por completar tu verificación y ayudar a mantener
          una comunidad segura y confiable.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Verificación responsable para una comunidad más segura
        </p>
      </div>
    </div>
  `,
});
