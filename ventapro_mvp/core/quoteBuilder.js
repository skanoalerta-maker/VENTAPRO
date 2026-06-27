(function (window) {
  "use strict";

  function addDays(date, days) {
    const copy = new Date(date.getTime());
    copy.setDate(copy.getDate() + Number(days || 0));
    return copy.toISOString().slice(0, 10);
  }

  function toDate(value) {
    return value || new Date().toISOString().slice(0, 10);
  }

  function panelSummary(project, calc) {
    return project.panels.map((panel) => {
      const panelCalc = (calc.panelCalculations || []).find((item) => item.id === panel.id) || {};
      return {
        id: panel.id,
        label: `F${panel.row + 1} C${panel.col + 1}`,
        openingType: panel.openingType,
        glassType: panel.glassType,
        glassThickness: panel.glassThickness,
        frameColor: panel.frameColor,
        profileSystem: panel.profileSystem,
        width: panel.width,
        height: panel.height,
        area: panelCalc.area || (panel.width / 1000) * (panel.height / 1000),
        weight: panelCalc.glassWeight || 0,
      };
    });
  }

  function cutSummary(cuts) {
    return (cuts || []).map((row) => ({
      code: row.code || row[0],
      description: row.description || "",
      color: row.color || "",
      length: row.lengthMm ? `${row.lengthMm} mm` : row[1],
      lengthMm: row.lengthMm || 0,
      quantity: row.quantity || row[2],
      leftAngle: row.leftAngle || "",
      rightAngle: row.rightAngle || "",
      location: row.location || "",
      notes: row.notes || "",
    }));
  }

  function materialsSummary(billOfMaterials) {
    return (billOfMaterials || []).map((row) => ({
      item: row[0],
      quantity: row[1],
      total: row[2],
    }));
  }

  function buildQuote(project, calc, billOfMaterials, cuts, company, quoteNumber) {
    const previous = project.quote || {};
    const issueDate = toDate(previous.issueDate);
    const previousValidityDays = Number(previous.validityDays || 15);
    const validityDays = Number(previous.validityDays || 15);
    const discount = Number(previous.discount || 0);
    const taxRate = 0.19;
    const netTotal = Math.max(0, calc.subtotal + calc.marginAmount - discount);
    const taxAmount = netTotal * taxRate;
    const finalTotal = netTotal + taxAmount;

    return {
      quoteId: previous.quoteId || `quote-${project.id}`,
      quoteNumber: quoteNumber || previous.quoteNumber,
      projectId: project.id,
      customer: project.customerSnapshot || Object.assign({}, project.customer, {
        name: project.customerId ? project.customer.name : "Cliente no asignado",
        companyName: project.customerId ? project.customer.companyName : "",
      }),
      company,
      issueDate,
      validUntil: previous.validUntil && previousValidityDays === validityDays
        ? previous.validUntil
        : addDays(new Date(`${issueDate}T00:00:00`), validityDays),
      validityDays,
      projectName: project.name,
      measurements: {
        width: project.width,
        height: project.height,
        unit: project.unit,
        verticalDivisions: project.verticalDivisions.length,
        horizontalDivisions: project.horizontalDivisions.length,
      },
      panelsSummary: panelSummary(project, calc),
      materialsSummary: materialsSummary(billOfMaterials),
      cutListSummary: cutSummary(cuts),
      subtotal: calc.subtotal + calc.marginAmount,
      discount,
      netTotal,
      taxRate,
      taxAmount,
      finalTotal,
      paymentTerms: previous.paymentTerms || "50% anticipo, 50% contra entrega.",
      deliveryTime: previous.deliveryTime || "10 a 15 dias habiles desde aprobacion.",
      installationIncluded: previous.installationIncluded !== false,
      notes: previous.notes || project.notes || "",
      terms: previous.terms || "Valores sujetos a confirmacion de medidas en obra. Cotizacion valida hasta la fecha indicada.",
      status: previous.status || "borrador",
    };
  }

  window.VentaProQuoteBuilder = {
    buildQuote,
  };
})(window);
