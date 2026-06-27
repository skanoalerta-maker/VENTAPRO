module.exports = ({
  fullName,
  plate,
  location,
  reportedAt,
  imageUrl,
}) => ({
  subject: "🚨 Posible ubicación de tu vehículo robado",
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

        <h2 style="color:#FF3D00;text-align:center;margin-bottom:12px">
          Vehículo reportado como robado
        </h2>

        <p style="color:#ddd">
          Hola <strong>${fullName || "Usuario SKANO"}</strong>,
        </p>

        <p style="color:#ddd">
          Un miembro de la comunidad SKANO ha reportado el avistamiento de un vehículo
          que coincide con el tuyo, registrado como robado.
        </p>

        <div style="background:#1a1a1a;border-radius:12px;padding:14px;margin:16px 0">
          <p style="margin:0;color:#fff">
            🚗 <strong>Patente:</strong> ${plate}
          </p>
          <p style="margin:4px 0 0;color:#ddd">
            📍 <strong>Ubicación aproximada:</strong> ${location}
          </p>
          <p style="margin:4px 0 0;color:#ddd">
            🕒 <strong>Fecha del reporte:</strong> ${reportedAt}
          </p>
        </div>

        ${
          imageUrl
            ? `
        <div style="margin:20px 0;text-align:center">
          <p style="color:#ddd;margin-bottom:8px">
            📸 Evidencia visual enviada por el reportador
          </p>
          <img 
            src="${imageUrl}" 
            alt="Evidencia del vehículo"
            style="max-width:100%;border-radius:12px;border:1px solid #333"
          />
        </div>
        `
            : ""
        }

        <p style="color:#ddd;margin-top:16px">
          Este reporte está siendo procesado y validado por nuestros sistemas de seguridad.
        </p>

        <p style="color:#ddd;font-weight:bold;margin-top:12px">
          📌 Te notificaremos cuando la autoridad competente lo tenga en su poder.
        </p>

        <p style="color:#888;margin-top:20px;font-size:12px">
          🛡️ SKANO actúa como plataforma de reporte ciudadano.
          La coordinación final corresponde exclusivamente a la autoridad competente.
        </p>
      </div>
    </div>
  `,
});
