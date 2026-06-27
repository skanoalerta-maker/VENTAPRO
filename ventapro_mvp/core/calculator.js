(function (window) {
  "use strict";

  function getPanelGlass(panel, technicalData, fallbackGlass) {
    return technicalData.panelGlassTypes[panel.glassType] ||
      technicalData.panelGlassTypes[fallbackGlass] ||
      technicalData.panelGlassTypes.transparente;
  }

  function getPanelProfile(panel, technicalData, fallbackSystem) {
    return technicalData.panelProfileSystems[panel.profileSystem] ||
      technicalData.panelProfileSystems[fallbackSystem] ||
      technicalData.panelProfileSystems.al25;
  }

  function getPanelHardwareCost(panel, hardwareRules) {
    if (panel.openingType === "fijo") {
      return hardwareRules.fixedPanelCost;
    }
    if (panel.openingType === "puerta") {
      return hardwareRules.doorPanelCost;
    }
    return hardwareRules.operablePanelCost;
  }

  function calculatePanel(panel, state, technicalData) {
    const glass = getPanelGlass(panel, technicalData, state.glass);
    const profile = getPanelProfile(panel, technicalData, state.system);
    const thickness = Number(panel.glassThickness || state.glassThickness || 6);
    const area = (Number(panel.width || 0) / 1000) * (Number(panel.height || 0) / 1000);
    const glassCost = area * glass.costM2 * Math.max(0.75, thickness / 6);
    const glassWeight = area * glass.kgM2ByMm * thickness;

    return {
      id: panel.id,
      area,
      glassCost,
      glassWeight,
      hardwareCost: getPanelHardwareCost(panel, technicalData.hardwareRules),
      profileCostFactor: profile.costFactor,
      profileWeightFactor: profile.weightFactor,
    };
  }

  function calculate(state, technicalData) {
    const system = technicalData.systems[state.system];
    const glass = technicalData.glasses[state.glass];
    const costs = technicalData.baseCosts;
    const rules = technicalData.technicalRules;
    const panels = Array.isArray(state.panels) && state.panels.length ? state.panels : [];
    const widthM = state.width / 1000;
    const heightM = state.height / 1000;
    const perimeterMm = (state.width + state.height) * 2;
    const internalBarsMm = state.verticalDivisions * state.height + state.horizontalDivisions * state.width;
    const profileMm = perimeterMm + internalBarsMm;
    const waste = profileMm > rules.highProfileWasteThresholdMm ? rules.highWaste : rules.standardWaste;
    const profileWithWaste = profileMm * (1 + waste);
    const bars = Math.ceil(profileWithWaste / system.barLength);
    const panelCount = panels.length || (state.verticalDivisions + 1) * (state.horizontalDivisions + 1);
    const panelCalculations = panels.map((panel) => calculatePanel(panel, state, technicalData));
    const glassArea = panelCalculations.length
      ? panelCalculations.reduce((total, panel) => total + panel.area, 0)
      : widthM * heightM;
    const profileFactor = panelCalculations.length
      ? panelCalculations.reduce((total, panel) => total + panel.profileCostFactor, 0) / panelCalculations.length
      : 1;
    const profileWeightFactor = panelCalculations.length
      ? panelCalculations.reduce((total, panel) => total + panel.profileWeightFactor, 0) / panelCalculations.length
      : 1;
    const profileCost = (profileWithWaste / 1000) * system.profileCost * profileFactor;
    const glassCost = panelCalculations.length
      ? panelCalculations.reduce((total, panel) => total + panel.glassCost, 0)
      : glassArea * glass.costM2;
    const hardwareCost = panelCalculations.length
      ? panelCalculations.reduce((total, panel) => total + panel.hardwareCost, 0)
      : panelCount * (state.opening === "fijo" ? technicalData.hardwareRules.fixedPanelCost : technicalData.hardwareRules.operablePanelCost);
    const labor = (profileCost + glassCost + hardwareCost) * system.laborFactor;
    const transport = Math.max(costs.minimumTransport, glassArea * costs.transportByM2);
    const installation = Math.max(costs.minimumInstallation, glassArea * costs.installationByM2);
    const subtotal = profileCost + glassCost + hardwareCost + labor + transport + installation;
    const marginAmount = subtotal * (state.margin / 100);
    const net = subtotal + marginAmount;
    const iva = net * costs.iva;
    const total = net + iva;
    const glassWeight = panelCalculations.length
      ? panelCalculations.reduce((sum, panel) => sum + panel.glassWeight, 0)
      : glassArea * glass.kgM2;

    return {
      system,
      glass,
      perimeterMm,
      internalBarsMm,
      profileMm,
      waste,
      profileWithWaste,
      bars,
      glassArea,
      panelCount,
      panelCalculations,
      profileCost,
      glassCost,
      hardwareCost,
      labor,
      transport,
      installation,
      subtotal,
      marginAmount,
      iva,
      total,
      weight: glassWeight + (profileMm / 1000) * system.weight * profileWeightFactor,
    };
  }

  window.VentaProCalculator = {
    calculate,
  };
})(window);
