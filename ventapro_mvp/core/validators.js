(function (window) {
  "use strict";

  function validateProject(state, calc, technicalData) {
    const rules = technicalData.technicalRules;
    const checks = [
      {
        type: "good",
        text: "Medidas generales registradas y listas para dise\u00f1o param\u00e9trico.",
      },
      {
        type: state.width > rules.wideOpeningWarningMm ? "warn" : "good",
        text: state.width > rules.wideOpeningWarningMm
          ? "Ancho alto: validar refuerzo o divisi\u00f3n adicional."
          : "Ancho dentro de rango recomendado.",
      },
      {
        type: state.glass === "monolitico" && state.width > rules.monolithicWarningMm ? "warn" : "good",
        text: state.glass === "monolitico" && state.width > rules.monolithicWarningMm
          ? "Vidrio monol\u00edtico podr\u00eda no ser ideal para este ancho."
          : "Vidrio compatible con configuraci\u00f3n actual.",
      },
      {
        type: calc.weight > rules.highWeightWarningKg ? "danger" : "good",
        text: calc.weight > rules.highWeightWarningKg
          ? "Peso elevado: revisar manipulaci\u00f3n e instalaci\u00f3n."
          : "Peso estimado apto para instalaci\u00f3n est\u00e1ndar.",
      },
    ];

    (state.panels || []).forEach((panel) => {
      const label = `Panel F${panel.row + 1} C${panel.col + 1}`;
      if (panel.width < 300) {
        checks.push({ type: "warn", text: `${label}: ancho menor a 300 mm.` });
      }
      if (panel.height < 300) {
        checks.push({ type: "warn", text: `${label}: alto menor a 300 mm.` });
      }
      if (panel.openingType === "puerta" && panel.height < 1800) {
        checks.push({ type: "danger", text: `${label}: puerta con alto menor a 1800 mm.` });
      }
      if (panel.glassType === "termopanel" && Number(panel.glassThickness || 0) < 10) {
        checks.push({ type: "warn", text: `${label}: termopanel con espesor menor a 10 mm.` });
      }
    });

    return checks;
  }

  window.VentaProValidators = {
    validateProject,
  };
})(window);
