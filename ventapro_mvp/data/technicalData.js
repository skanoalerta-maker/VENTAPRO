(function (window) {
  "use strict";

  const systems = {
    al25: {
      name: "Aluminio Serie AL-25",
      profileCost: 4200,
      barLength: 6000,
      laborFactor: 0.22,
      weight: 0.82,
    },
    pvc70: {
      name: "PVC L\u00ednea 70",
      profileCost: 5200,
      barLength: 5800,
      laborFactor: 0.25,
      weight: 0.95,
    },
    muro: {
      name: "Fachada Muro Cortina",
      profileCost: 7800,
      barLength: 6000,
      laborFactor: 0.32,
      weight: 1.35,
    },
  };

  const glasses = {
    monolitico: { name: "Monol\u00edtico 6 mm", costM2: 18500, kgM2: 15 },
    termopanel: { name: "Termopanel 20 mm", costM2: 46500, kgM2: 25 },
    laminado: { name: "Laminado seguridad 8 mm", costM2: 38500, kgM2: 20 },
  };

  const hardwareRules = {
    fixedPanelCost: 3800,
    operablePanelCost: 14500,
    doorPanelCost: 32000,
  };

  const panelGlassTypes = {
    transparente: { name: "Transparente", costM2: 18500, kgM2ByMm: 2.5 },
    satinado: { name: "Satinado", costM2: 24500, kgM2ByMm: 2.5 },
    bronce: { name: "Bronce", costM2: 26500, kgM2ByMm: 2.5 },
    azul: { name: "Azul", costM2: 28500, kgM2ByMm: 2.5 },
    reflectivo: { name: "Reflectivo", costM2: 36500, kgM2ByMm: 2.5 },
    termopanel: { name: "Termopanel", costM2: 46500, kgM2ByMm: 1.25 },
    monolitico: { name: "Monolitico", costM2: 18500, kgM2ByMm: 2.5 },
    laminado: { name: "Laminado", costM2: 38500, kgM2ByMm: 2.5 },
  };

  const panelProfileSystems = {
    aluminio_liviano: { name: "Aluminio liviano", costFactor: 0.94, weightFactor: 0.92 },
    aluminio_premium: { name: "Aluminio premium", costFactor: 1.22, weightFactor: 1.08 },
    pvc_estandar: { name: "PVC estandar", costFactor: 1.05, weightFactor: 1.05 },
    pvc_premium: { name: "PVC premium", costFactor: 1.28, weightFactor: 1.12 },
    al25: { name: "Aluminio Serie AL-25", costFactor: 1, weightFactor: 1 },
    pvc70: { name: "PVC Linea 70", costFactor: 1.12, weightFactor: 1.1 },
    muro: { name: "Fachada Muro Cortina", costFactor: 1.42, weightFactor: 1.35 },
  };

  const baseCosts = {
    minimumTransport: 18000,
    transportByM2: 8500,
    minimumInstallation: 35000,
    installationByM2: 22000,
    iva: 0.19,
  };

  const technicalRules = {
    wideOpeningWarningMm: 2600,
    monolithicWarningMm: 2200,
    highWeightWarningKg: 95,
    heavyWeightAiKg: 80,
    highProfileWasteThresholdMm: 7200,
    standardWaste: 0.08,
    highWaste: 0.10,
  };

  window.VentaProTechnicalData = {
    systems,
    glasses,
    hardwareRules,
    panelGlassTypes,
    panelProfileSystems,
    baseCosts,
    technicalRules,
  };
})(window);
