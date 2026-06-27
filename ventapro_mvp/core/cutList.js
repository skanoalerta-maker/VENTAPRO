(function (window) {
  "use strict";

  function generateBillOfMaterials(state, calc, formatters) {
    return [
      ["Perfiles", `${(calc.profileWithWaste / 1000).toFixed(2)} m`, formatters.money(calc.profileCost)],
      ["Vidrios", `${calc.glassArea.toFixed(2)} m2`, formatters.money(calc.glassCost)],
      ["Herrajes", `${calc.panelCount} paneles`, formatters.money(calc.hardwareCost)],
      ["Mano de obra", "Dise\u00f1o + taller", formatters.money(calc.labor)],
      ["Transporte", "Proyecto", formatters.money(calc.transport)],
      ["Instalaci\u00f3n", "Incluida", formatters.money(calc.installation)],
    ];
  }

  function colorLabel(panel, state) {
    return panel.frameColor || state.color || "negro";
  }

  function panelLocation(panel) {
    return `F${panel.row + 1} C${panel.col + 1}`;
  }

  function generateCutList(state) {
    const rows = [];

    (state.panels || []).forEach((panel) => {
      const location = panelLocation(panel);
      const color = colorLabel(panel, state);
      rows.push({
        code: "MARCO-H",
        description: "Perfil marco horizontal",
        color,
        lengthMm: panel.width,
        quantity: 2,
        leftAngle: "45",
        rightAngle: "45",
        location,
        notes: "Superior e inferior",
      });
      rows.push({
        code: "MARCO-V",
        description: "Perfil marco vertical",
        color,
        lengthMm: panel.height,
        quantity: 2,
        leftAngle: "45",
        rightAngle: "45",
        location,
        notes: "Laterales",
      });
      rows.push({
        code: panel.openingType === "fijo" ? "JUNQUILLO" : "HOJA-H",
        description: panel.openingType === "fijo" ? "Junquillo vidrio fijo" : "Perfil hoja horizontal",
        color,
        lengthMm: Math.max(0, panel.width - 28),
        quantity: panel.openingType === "fijo" ? 4 : 2,
        leftAngle: "90",
        rightAngle: "90",
        location,
        notes: `${panel.openingType} / ${panel.glassType} ${panel.glassThickness}mm`,
      });
    });

    if (!rows.length) {
      rows.push({
        code: "MARCO-H",
        description: "Perfil marco horizontal",
        color: state.color || "negro",
        lengthMm: state.width,
        quantity: 2,
        leftAngle: "45",
        rightAngle: "45",
        location: "Proyecto",
        notes: "Generado sin paneles",
      });
    }

    return rows;
  }

  window.VentaProCutList = {
    generateBillOfMaterials,
    generateCutList,
  };
})(window);
