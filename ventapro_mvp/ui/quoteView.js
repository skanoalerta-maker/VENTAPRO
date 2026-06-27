(function (window, document) {
  "use strict";

  function setValue(id, value) {
    const element = document.getElementById(id);
    if (element) {
      element.value = value == null ? "" : String(value);
    }
  }

  function money(formatters, value) {
    return formatters.money(Number(value || 0));
  }

  function renderDesignPreview(project) {
    const width = 420;
    const height = 220;
    const ratio = Math.min((width - 32) / project.width, (height - 32) / project.height);
    const originX = 16;
    const originY = 16;
    const frameW = project.width * ratio;
    const frameH = project.height * ratio;
    const panels = project.panels.map((panel) => {
      const x = originX + panel.x * ratio;
      const y = originY + panel.y * ratio;
      const w = panel.width * ratio;
      const h = panel.height * ratio;
      return `
        <g>
          <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="rgba(117,204,214,.16)" stroke="#0f7c86" stroke-width="2" />
          <text x="${x + w / 2}" y="${y + h / 2}" text-anchor="middle" font-size="10" fill="#183b56">${panel.openingType}</text>
        </g>
      `;
    }).join("");

    return `
      <svg class="quote-design-svg" viewBox="0 0 ${width} ${height}" role="img" aria-label="Vista del diseño cotizado">
        ${panels}
        <rect x="${originX}" y="${originY}" width="${frameW}" height="${frameH}" fill="none" stroke="#183b56" stroke-width="4" />
      </svg>
    `;
  }

  function renderRows(rows, emptyText, mapper) {
    return rows.length ? rows.map(mapper).join("") : `<tr><td colspan="6">${emptyText}</td></tr>`;
  }

  function render(context) {
    const quote = context.project.quote || {};
    const company = quote.company || {};
    const formatters = context.formatters;

    setValue("quoteStatusInput", quote.status || "borrador");
    setValue("quoteDiscountInput", quote.discount || 0);
    setValue("quoteValidityInput", quote.validityDays || 15);
    setValue("quoteDeliveryInput", quote.deliveryTime || "");
    setValue("quotePaymentInput", quote.paymentTerms || "");
    setValue("quoteNotesInput", quote.notes || "");

    document.getElementById("quoteDocument").innerHTML = `
      <section class="quote-paper">
        <header class="quote-header">
          <div class="quote-brand">
            <div class="quote-logo">${company.logoText || "VENTAPRO"}</div>
            <div>
              <strong>${company.companyName || "VENTAPRO"}</strong>
              <span>RUT ${company.rut || ""}</span>
              <span>${company.address || ""}, ${company.city || ""}</span>
              <span>${company.phone || ""} · ${company.email || ""}</span>
              <span>${company.website || ""}</span>
            </div>
          </div>
          <div class="quote-meta">
            <h3>Cotización</h3>
            <strong>${quote.quoteNumber || "VENTA-PENDIENTE"}</strong>
            <span>Emisión: ${quote.issueDate || ""}</span>
            <span>Válida hasta: ${quote.validUntil || ""}</span>
            <span class="quote-status">${quote.status || "borrador"}</span>
          </div>
        </header>

        <div class="quote-two-col">
          <section>
            <h4>Cliente</h4>
            <p><strong>${quote.customer?.name || ""}</strong></p>
            <p>RUT: ${quote.customer?.rut || ""}</p>
            <p>${quote.customer?.email || ""} · ${quote.customer?.phone || ""}</p>
            <p>${quote.customer?.address || ""}, ${quote.customer?.city || ""}</p>
          </section>
          <section>
            <h4>Proyecto</h4>
            <p><strong>${quote.projectName || ""}</strong></p>
            <p>Medidas: ${quote.measurements?.width || 0} x ${quote.measurements?.height || 0} ${quote.measurements?.unit || "mm"}</p>
            <p>Paneles: ${(quote.panelsSummary || []).length}</p>
            <p>Instalación: ${quote.installationIncluded ? "Incluida" : "No incluida"}</p>
          </section>
        </div>

        <section class="quote-design">
          <h4>Vista del diseño</h4>
          ${renderDesignPreview(context.project)}
        </section>

        <section>
          <h4>Paneles cotizados</h4>
          <table class="quote-table">
            <thead><tr><th>Panel</th><th>Apertura</th><th>Vidrio</th><th>Medida</th><th>Área</th><th>Peso vidrio</th></tr></thead>
            <tbody>
              ${renderRows(quote.panelsSummary || [], "Sin paneles.", (panel) => `
                <tr>
                  <td>${panel.label}</td>
                  <td>${panel.openingType}</td>
                  <td>${panel.glassType} ${panel.glassThickness} mm</td>
                  <td>${panel.width} x ${panel.height} mm</td>
                  <td>${Number(panel.area || 0).toFixed(2)} m2</td>
                  <td>${Number(panel.weight || 0).toFixed(1)} kg</td>
                </tr>
              `)}
            </tbody>
          </table>
        </section>

        <section>
          <h4>Materiales</h4>
          <table class="quote-table">
            <thead><tr><th>Ítem</th><th>Cantidad</th><th>Total</th></tr></thead>
            <tbody id="bomTable">
              ${renderRows(quote.materialsSummary || [], "Sin materiales.", (row) => `<tr><td>${row.item}</td><td>${row.quantity}</td><td>${row.total}</td></tr>`)}
            </tbody>
          </table>
        </section>

        <section>
          <h4>Lista de corte resumida</h4>
          <table class="quote-table compact">
            <thead><tr><th>Código</th><th>Largo</th><th>Cant.</th></tr></thead>
            <tbody id="cutTable">
              ${renderRows(quote.cutListSummary || [], "Sin cortes.", (row) => `<tr><td>${row.code}</td><td>${row.length || row.lengthMm}</td><td>${row.quantity}</td></tr>`)}
            </tbody>
          </table>
        </section>

        <section class="quote-total-box" id="quoteSummary">
          <div><span>Subtotal</span><strong>${money(formatters, quote.subtotal)}</strong></div>
          <div><span>Descuento</span><strong>${money(formatters, quote.discount)}</strong></div>
          <div><span>Neto</span><strong>${money(formatters, quote.netTotal)}</strong></div>
          <div><span>IVA ${Math.round(Number(quote.taxRate || 0) * 100)}%</span><strong>${money(formatters, quote.taxAmount)}</strong></div>
          <div class="final"><span>Total final</span><strong>${money(formatters, quote.finalTotal)}</strong></div>
        </section>

        <section class="quote-two-col commercial">
          <div>
            <h4>Condiciones comerciales</h4>
            <p><strong>Pago:</strong> ${quote.paymentTerms || ""}</p>
            <p><strong>Entrega:</strong> ${quote.deliveryTime || ""}</p>
            <p><strong>Términos:</strong> ${quote.terms || ""}</p>
          </div>
          <div>
            <h4>Observaciones</h4>
            <p>${quote.notes || "Sin observaciones."}</p>
          </div>
        </section>

        <footer class="quote-signature">
          <div><span>Firma cliente</span></div>
          <div><span>Fecha aprobación</span></div>
        </footer>
      </section>
    `;
  }

  window.VentaProQuoteView = {
    render,
  };
})(window, document);
