(function (window, document) {
  "use strict";

  function render(context) {
    const rules = context.technicalData.technicalRules;
    const rec = context.calc.weight > rules.heavyWeightAiKg
      ? "El peso estimado es alto. Sugiero revisar espesores, dividir m\u00f3dulos o planificar instalaci\u00f3n con cuadrilla reforzada."
      : `Configuraci\u00f3n apta. ${context.calc.glass.name} y ${context.calc.system.name} son compatibles para las medidas actuales.`;

    document.getElementById("aiRecommendation").textContent = rec;
    document.getElementById("roadmap").innerHTML = context.demoData.roadmap.map((item) => (
      `<div class="roadmap-item">${item}</div>`
    )).join("");
  }

  window.VentaProAiView = {
    render,
  };
})(window, document);
