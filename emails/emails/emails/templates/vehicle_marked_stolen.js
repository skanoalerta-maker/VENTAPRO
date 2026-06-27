module.exports = function vehicleMarkedStolen({ fullName, plate }) {
  const safeName = (fullName || "Usuario SKANO").toString();
  const safePlate = (plate || "").toString();

  const subject = `SKANO · Vehículo activado como ROBADO (${safePlate})`;

  const html = `
  <div style="font-family: Arial, Helvetica, sans-serif; background:#0b0f17; padding:24px;">
    <div style="max-width:640px; margin:0 auto; background:#0f172a; border:1px solid rgba(10,108,255,.35); border-radius:16px; overflow:hidden;">
      
      <div style="padding:18px 20px; background:#060a12; border-bottom:1px solid rgba(255,255,255,.08);">
        <div style="font-size:14px; color:#9CA3AF;">SKANO</div>
        <div style="font-size:18px; font-weight:800; color:#FFFFFF; margin-top:4px;">
          Vehículo activado como <span style="color:#FF3B30;">ROBADO</span>
        </div>
      </div>

      <div style="padding:20px; color:#E5E7EB;">
        <p style="margin:0 0 12px 0; color:#E5E7EB;">
          Hola <b>${safeName}</b>,
        </p>

        <p style="margin:0 0 14px 0; color:#E5E7EB; line-height:1.45;">
          Tu vehículo con patente <b style="letter-spacing:1px;">${safePlate}</b> fue activado correctamente en SKANO como
          <b style="color:#FF3B30;">vehículo robado</b>.
        </p>

        <div style="padding:14px 14px; background:rgba(255,59,48,.08); border:1px solid rgba(255,59,48,.28); border-radius:12px; margin:14px 0;">
          <div style="font-weight:800; color:#FF3B30; margin-bottom:6px;">¿Qué significa esto?</div>
          <ul style="margin:0; padding-left:18px; color:#E5E7EB; line-height:1.5;">
            <li>El vehículo queda <b>activo</b> para detección en el sistema.</li>
            <li>Si un usuario verificado lo detecta, podrás recibir reportes según el flujo de SKANO.</li>
            <li>Tu seguridad y la del sistema se protege con verificación y revisión administrativa.</li>
          </ul>
        </div>

        <p style="margin:0 0 10px 0; color:#9CA3AF; line-height:1.45;">
          Importante: SKANO no reemplaza a Carabineros ni garantiza recuperación, pero acelera la detección mediante tecnología y comunidad.
        </p>

        <div style="margin-top:18px; padding:12px 14px; background:rgba(10,108,255,.08); border:1px solid rgba(10,108,255,.22); border-radius:12px;">
          <div style="color:#93C5FD; font-weight:800; margin-bottom:6px;">Consejo</div>
          <div style="color:#E5E7EB; line-height:1.45;">
            Mantén tus datos actualizados en <b>Mi Cuenta</b> para recibir notificaciones sin problemas.
          </div>
        </div>

        <p style="margin:18px 0 0 0; color:#E5E7EB;">
          Equipo <b>SKANO</b>
        </p>
      </div>

      <div style="padding:14px 20px; background:#060a12; border-top:1px solid rgba(255,255,255,.08); color:#9CA3AF; font-size:12px; line-height:1.4;">
        Este correo fue enviado automáticamente por seguridad del sistema.
      </div>
    </div>
  </div>
  `;

  return { subject, html };
};
