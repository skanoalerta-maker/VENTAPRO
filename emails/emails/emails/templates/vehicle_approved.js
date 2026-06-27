module.exports = ({ fullName, plate }) => ({
  subject: "✅ Tu vehículo fue aprobado en SKANO",
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
          Vehículo aprobado correctamente
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Tu vehículo fue revisado y aprobado por el sistema de validación de SKANO.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          A partir de ahora, tu vehículo queda habilitado dentro de la plataforma
          y puede recibir alertas en caso de reportes asociados.
        </p>

        <p style="color:#ddd">
          Gracias por confiar en SKANO para la protección de tu vehículo.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Protección comunitaria con validación de seguridad
        </p>
      </div>
    </div>
  `,
});
