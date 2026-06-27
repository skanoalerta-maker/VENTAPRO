(function (window) {
  "use strict";

  const MIN_DIVISION_GAP_MM = 250;

  function createId(prefix) {
    return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  }

  function nowIso() {
    return new Date().toISOString();
  }

  function createCustomer(overrides) {
    const createdAt = nowIso();
    return Object.assign({
      id: createId("customer"),
      type: "empresa",
      name: "Constructora Demo",
      rut: "76.123.456-7",
      companyName: "Constructora Demo",
      email: "contacto@constructora-demo.cl",
      phone: "+56 9 5555 0000",
      secondaryPhone: "",
      address: "Av. Apoquindo 3200",
      city: "Santiago",
      region: "Metropolitana",
      notes: "Cliente demo para cotizacion inicial.",
      createdAt,
      updatedAt: createdAt,
      status: "activo",
    }, overrides || {});
  }

  function customerSnapshot(customer) {
    const normalized = createCustomer(customer || {});
    return {
      id: normalized.id,
      type: normalized.type,
      name: normalized.name,
      rut: normalized.rut,
      companyName: normalized.companyName,
      email: normalized.email,
      phone: normalized.phone,
      address: normalized.address,
      city: normalized.city,
      region: normalized.region,
      status: normalized.status,
    };
  }

  function addHistory(project, action, detail, user) {
    const history = Array.isArray(project.history) ? project.history.slice() : [];
    history.unshift({
      date: nowIso(),
      user: user || "sistema",
      action,
      detail: detail || "",
    });
    return Object.assign({}, project, { history: history.slice(0, 100) });
  }

  function createDivision(orientation, positionMm, index, overrides) {
    const prefix = orientation === "horizontal" ? "h" : "v";
    return Object.assign({
      id: createId(prefix),
      orientation,
      positionMm: Math.round(Number(positionMm || 0)),
      locked: false,
      label: `${prefix.toUpperCase()}${index + 1}`,
    }, overrides || {});
  }

  function distributeDivisions(count, total, orientation) {
    const safeCount = Math.max(0, Number(count || 0));
    const divisions = [];
    for (let index = 0; index < safeCount; index += 1) {
      divisions.push(createDivision(orientation, Math.round((total / (safeCount + 1)) * (index + 1)), index));
    }
    return divisions;
  }

  function clampDivisionPosition(position, divisions, index, total) {
    const previous = index === 0 ? 0 : divisions[index - 1].positionMm;
    const next = index === divisions.length - 1 ? total : divisions[index + 1].positionMm;
    const min = previous + MIN_DIVISION_GAP_MM;
    const max = next - MIN_DIVISION_GAP_MM;
    if (max < min) {
      return Math.round((previous + next) / 2);
    }
    return Math.min(max, Math.max(min, Math.round(Number(position || 0))));
  }

  function normalizeDivisions(value, orientation, total) {
    const source = Array.isArray(value)
      ? value
      : distributeDivisions(Number(value || 0), total, orientation);

    const sorted = source
      .filter((division) => division && typeof division === "object")
      .map((division, index) => createDivision(orientation, division.positionMm, index, {
        id: division.id || createId(orientation === "horizontal" ? "h" : "v"),
        locked: Boolean(division.locked),
        label: division.label || `${orientation === "horizontal" ? "H" : "V"}${index + 1}`,
      }))
      .sort((a, b) => a.positionMm - b.positionMm);

    return sorted.map((division, index, divisions) => Object.assign({}, division, {
      positionMm: clampDivisionPosition(division.positionMm, divisions, index, total),
      label: division.label || `${orientation === "horizontal" ? "H" : "V"}${index + 1}`,
    }));
  }

  function createPanel(values) {
    return Object.assign({
      id: createId("panel"),
      row: 0,
      col: 0,
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      openingType: "corredera",
      glassType: "transparente",
      glassThickness: 6,
      profileSystem: "aluminio_liviano",
      frameColor: "negro",
      locked: false,
      notes: "",
    }, values || {});
  }

  function normalizePanelValues(panel) {
    const normalized = Object.assign({}, panel);
    if (normalized.glassType === "monolitico" || normalized.glassType === "laminado") {
      normalized.glassType = "transparente";
    }
    if (normalized.profileSystem === "al25" || normalized.profileSystem === "muro") {
      normalized.profileSystem = "aluminio_liviano";
    }
    if (normalized.profileSystem === "pvc70") {
      normalized.profileSystem = "pvc_estandar";
    }
    if (String(normalized.frameColor || "").toLowerCase().includes("blanco")) {
      normalized.frameColor = "blanco";
    } else if (String(normalized.frameColor || "").toLowerCase().includes("gris") || String(normalized.frameColor || "").toLowerCase().includes("grafito")) {
      normalized.frameColor = "gris";
    } else if (String(normalized.frameColor || "").toLowerCase().includes("bronce")) {
      normalized.frameColor = "bronce";
    } else if (String(normalized.frameColor || "").toLowerCase().includes("madera")) {
      normalized.frameColor = "madera";
    } else {
      normalized.frameColor = "negro";
    }
    return normalized;
  }

  function getSegments(total, divisions) {
    const positions = normalizeDivisions(divisions, "vertical", total).map((division) => division.positionMm);
    const points = [0].concat(positions, [Number(total || 0)]);
    return points.slice(0, -1).map((start, index) => ({
      index,
      start,
      end: points[index + 1],
      size: points[index + 1] - start,
    }));
  }

  function createPanels(project) {
    const verticalDivisions = normalizeDivisions(project.verticalDivisions, "vertical", Number(project.width || 0));
    const horizontalDivisions = normalizeDivisions(project.horizontalDivisions, "horizontal", Number(project.height || 0));
    const columns = getSegments(Number(project.width || 0), verticalDivisions);
    const rows = getSegments(Number(project.height || 0), horizontalDivisions);
    const previous = Array.isArray(project.panels) ? project.panels : [];
    const panels = [];

    rows.forEach((rowSegment, row) => {
      columns.forEach((colSegment, col) => {
        const existing = previous.find((panel) => panel.row === row && panel.col === col);
        const defaults = {
          row,
          col,
          x: colSegment.start,
          y: rowSegment.start,
          width: colSegment.size,
          height: rowSegment.size,
          openingType: project.productType,
          glassType: project.glassType === "termopanel" ? "termopanel" : "transparente",
          glassThickness: project.glassThickness,
          profileSystem: project.profileSystem === "pvc70" ? "pvc_estandar" : "aluminio_liviano",
          frameColor: String(project.frameColor || "negro").toLowerCase().includes("blanco") ? "blanco" : "negro",
        };
        panels.push(createPanel(Object.assign({}, defaults, normalizePanelValues(existing || {}), {
          row,
          col,
          x: colSegment.start,
          y: rowSegment.start,
          width: colSegment.size,
          height: rowSegment.size,
        })));
      });
    });

    return panels;
  }

  function createProject(overrides) {
    const createdAt = nowIso();
    const base = Object.assign({
      id: createId("project"),
      name: "Casa Lo Barnechea",
      customer: createCustomer(),
      customerId: "",
      customerSnapshot: null,
      status: "borrador",
      createdAt,
      updatedAt: createdAt,
      unit: "mm",
      width: 1800,
      height: 1400,
      category: "Ventanas",
      productType: "corredera",
      profileSystem: "al25",
      frameColor: "Negro mate",
      glassType: "monolitico",
      glassThickness: 6,
      margin: 28,
      panels: [],
      verticalDivisions: distributeDivisions(1, 1800, "vertical"),
      horizontalDivisions: [],
      quote: {},
      calculations: {},
      cutList: [],
      selectedPanelId: "",
      selectedDivisionId: "",
      selectedDivisionOrientation: "",
      cadWarning: "",
      history: [],
      notes: "Ventana corredera para living, color negro mate, instalacion incluida.",
    }, overrides || {});

    base.customer = createCustomer(base.customer);
    base.customerId = base.customerId || "";
    base.customerSnapshot = base.customerSnapshot || null;
    base.history = Array.isArray(base.history) ? base.history : [];
    base.verticalDivisions = normalizeDivisions(base.verticalDivisions, "vertical", Number(base.width || 0));
    base.horizontalDivisions = normalizeDivisions(base.horizontalDivisions, "horizontal", Number(base.height || 0));
    base.panels = createPanels(base);
    base.selectedPanelId = base.selectedPanelId || base.panels[0].id;
    return base;
  }

  function normalizeProject(project) {
    const fallback = createProject();
    const merged = Object.assign({}, fallback, project || {});
    merged.customer = createCustomer(merged.customer);
    merged.customerId = merged.customerId || "";
    merged.customerSnapshot = merged.customerSnapshot || (merged.customerId ? customerSnapshot(merged.customer) : null);
    merged.customer = createCustomer(Object.assign({}, merged.customerSnapshot || {}, merged.customer));
    merged.width = Number(merged.width || fallback.width);
    merged.height = Number(merged.height || fallback.height);
    merged.verticalDivisions = normalizeDivisions(merged.verticalDivisions, "vertical", merged.width);
    merged.horizontalDivisions = normalizeDivisions(merged.horizontalDivisions, "horizontal", merged.height);
    merged.margin = Number(merged.margin || fallback.margin);
    merged.panels = createPanels(merged);
    merged.selectedPanelId = merged.panels.some((panel) => panel.id === merged.selectedPanelId)
      ? merged.selectedPanelId
      : (merged.panels[0] ? merged.panels[0].id : "");
    const selectedList = merged.selectedDivisionOrientation === "horizontal" ? merged.horizontalDivisions : merged.verticalDivisions;
    merged.selectedDivisionId = selectedList.some((division) => division.id === merged.selectedDivisionId)
      ? merged.selectedDivisionId
      : "";
    merged.selectedDivisionOrientation = merged.selectedDivisionId ? merged.selectedDivisionOrientation : "";
    merged.quote = merged.quote && typeof merged.quote === "object" ? merged.quote : {};
    merged.calculations = merged.calculations && typeof merged.calculations === "object" ? merged.calculations : {};
    merged.cutList = Array.isArray(merged.cutList) ? merged.cutList : [];
    merged.cadWarning = merged.cadWarning || "";
    merged.history = Array.isArray(merged.history) ? merged.history : [];
    return merged;
  }

  function duplicateProject(project) {
    const timestamp = nowIso();
    return normalizeProject(Object.assign({}, project, {
      id: createId("project"),
      name: `${project.name} copia`,
      createdAt: timestamp,
      updatedAt: timestamp,
      verticalDivisions: project.verticalDivisions.map((division, index) => createDivision("vertical", division.positionMm, index, Object.assign({}, division, { id: createId("v") }))),
      horizontalDivisions: project.horizontalDivisions.map((division, index) => createDivision("horizontal", division.positionMm, index, Object.assign({}, division, { id: createId("h") }))),
      panels: project.panels.map((panel) => Object.assign({}, panel, { id: createId("panel") })),
      selectedPanelId: "",
      selectedDivisionId: "",
      selectedDivisionOrientation: "",
    }));
  }

  function toCalculationState(project) {
    return {
      width: project.width,
      height: project.height,
      unit: project.unit,
      system: project.profileSystem,
      glass: project.glassType,
      glassThickness: project.glassThickness,
      margin: project.margin,
      opening: project.productType,
      color: project.frameColor,
      verticalDivisions: project.verticalDivisions.length,
      horizontalDivisions: project.horizontalDivisions.length,
      verticalDivisionItems: project.verticalDivisions,
      horizontalDivisionItems: project.horizontalDivisions,
      panels: project.panels,
    };
  }

  function getSelectedPanel(project) {
    return project.panels.find((panel) => panel.id === project.selectedPanelId) || project.panels[0] || null;
  }

  function getDivisionList(project, orientation) {
    return orientation === "horizontal" ? project.horizontalDivisions : project.verticalDivisions;
  }

  const initialProject = createProject();
  const initialState = {
    view: "dashboard",
    project: initialProject,
    projects: [initialProject],
    selectedCustomerId: initialProject.customerId,
    selectedProductionOrderId: "",
    selectedInventoryItemId: "",
    selectedInstallationId: "",
    undoStack: [],
    redoStack: [],
    cadView: {
      zoom: 1,
      panX: 0,
      panY: 0,
      mode: "select",
      saved: true,
      dragGuide: null,
    },
    storageWarning: "",
  };

  let state = Object.assign({}, initialState);

  function getState() {
    return state;
  }

  function setState(patch) {
    state = Object.assign({}, state, patch);
    return state;
  }

  function setProject(project) {
    return setState({ project: normalizeProject(project) });
  }

  function setProjects(projects) {
    return setState({ projects: Array.isArray(projects) ? projects.map(normalizeProject) : [] });
  }

  function resetState() {
    const project = createProject();
    state = {
      view: "dashboard",
      project,
      projects: [project],
      selectedCustomerId: project.customerId,
      selectedProductionOrderId: "",
      selectedInventoryItemId: "",
      selectedInstallationId: "",
      undoStack: [],
      redoStack: [],
      cadView: {
        zoom: 1,
        panX: 0,
        panY: 0,
        mode: "select",
        saved: true,
        dragGuide: null,
      },
      storageWarning: "",
    };
    return state;
  }

  window.VentaProStore = {
    getState,
    setState,
    setProject,
    setProjects,
    resetState,
    createProject,
    createCustomer,
    customerSnapshot,
    addHistory,
    createPanel,
    createPanels,
    createDivision,
    normalizeDivisions,
    normalizeProject,
    duplicateProject,
    toCalculationState,
    getSelectedPanel,
    getDivisionList,
    minDivisionGapMm: MIN_DIVISION_GAP_MM,
    nowIso,
  };
})(window);
