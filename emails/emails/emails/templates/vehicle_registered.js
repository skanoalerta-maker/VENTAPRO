module.exports = ({ fullName, plate }) => ({
  subject: "🚗 Vehículo registrado en SKANO",
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

        <h2 style="color:#42A5F5;text-align:center;margin-bottom:12px">
          Vehículo registrado correctamente
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          El vehículo que registraste fue recibido correctamente en la plataforma SKANO.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0;text-align:center">
          <p style="margin:0;color:#fff;font-size:18px">
            🚗 <strong>${plate}</strong>
          </p>
        </div>

        <p style="color:#ddd">
          Actualmente, el vehículo se encuentra en proceso de revisión
          para validar la información y los documentos asociados.
        </p>

        <p style="color:#ddd">
          Te notificaremos por correo una vez que la revisión haya finalizado,
          ya sea con la aprobación o con observaciones.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO • Registro y validación responsable de vehículos
        </p>
      </div>
    </div>
  `,
});
