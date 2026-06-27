(function (window) {
  "use strict";

  const store = window.VentaProStore;
  const storage = window.VentaProLocalStorageService;
  const customerStorage = window.VentaProCustomerStorageService;
  const productionStorage = window.VentaProProductionStorageService;
  const inventoryStorage = window.VentaProInventoryStorageService;
  const installationStorage = window.VentaProInstallationStorageService;
  const quoteBuilder = window.VentaProQuoteBuilder;
  const companyData = window.VentaProCompanyData;

  function persist(project, projects) {
    if (!project || !project.id) {
      console.warn("VENTAPRO: no se puede persistir un proyecto sin id.");
      return store.getState();
    }

    const normalizedProject = store.normalizeProject(project);
    const savedProjects = storage.upsertProject(normalizedProject);
    return store.setState({
      project: normalizedProject,
      projects: projects || savedProjects,
      cadView: Object.assign({}, store.getState().cadView, { saved: true }),
    });
  }

  function cloneProject(project) {
    return JSON.parse(JSON.stringify(project));
  }

  function pushHistory() {
    const state = store.getState();
    return store.setState({
      undoStack: state.undoStack.concat([cloneProject(state.project)]).slice(-50),
      redoStack: [],
      cadView: Object.assign({}, state.cadView, { saved: false }),
    });
  }

  function canUndo() {
    return store.getState().undoStack.length > 0;
  }

  function canRedo() {
    return store.getState().redoStack.length > 0;
  }

  function undo() {
    const state = store.getState();
    if (!canUndo()) {
      return state;
    }

    const previous = state.undoStack[state.undoStack.length - 1];
    const project = store.normalizeProject(previous);
    storage.saveCurrentProject(project);
    const projects = storage.upsertProject(project);
    return store.setState({
      project,
      projects,
      undoStack: state.undoStack.slice(0, -1),
      redoStack: state.redoStack.concat([cloneProject(state.project)]).slice(-50),
      cadView: Object.assign({}, state.cadView, { saved: true, dragGuide: null }),
    });
  }

  function redo() {
    const state = store.getState();
    if (!canRedo()) {
      return state;
    }

    const next = state.redoStack[state.redoStack.length - 1];
    const project = store.normalizeProject(next);
    storage.saveCurrentProject(project);
    const projects = storage.upsertProject(project);
    return store.setState({
      project,
      projects,
      undoStack: state.undoStack.concat([cloneProject(state.project)]).slice(-50),
      redoStack: state.redoStack.slice(0, -1),
      cadView: Object.assign({}, state.cadView, { saved: true, dragGuide: null }),
    });
  }

  function setCadView(patch) {
    const state = store.getState();
    return store.setState({
      cadView: Object.assign({}, state.cadView, patch || {}),
    });
  }

  function setCadZoom(zoom) {
    return setCadView({ zoom: Math.min(3, Math.max(0.4, Number(zoom || 1))) });
  }

  function zoomCad(delta) {
    const state = store.getState();
    return setCadZoom(state.cadView.zoom + delta);
  }

  function resetCadView() {
    return setCadView({ zoom: 1, panX: 0, panY: 0, dragGuide: null });
  }

  function fitCadView() {
    return setCadView({ zoom: 1, panX: 0, panY: 0, mode: "select", dragGuide: null });
  }

  function setCadMode(mode) {
    return setCadView({ mode: mode === "pan" ? "pan" : "select" });
  }

  function panCad(deltaX, deltaY) {
    const state = store.getState();
    return setCadView({
      panX: state.cadView.panX + Number(deltaX || 0),
      panY: state.cadView.panY + Number(deltaY || 0),
    });
  }

  function setCadDragGuide(guide) {
    return setCadView({ dragGuide: guide || null });
  }

  function touchProject(project) {
    return store.normalizeProject(Object.assign({}, project, {
      updatedAt: store.nowIso(),
    }));
  }

  function withHistory(project, action, detail) {
    return store.addHistory(project, action, detail);
  }

  function getDivisionTotal(project, orientation) {
    return orientation === "horizontal" ? project.height : project.width;
  }

  function getDivisionKey(orientation) {
    return orientation === "horizontal" ? "horizontalDivisions" : "verticalDivisions";
  }

  function findLargestGap(divisions, total) {
    const points = [0].concat(divisions.map((division) => division.positionMm), [total]);
    let best = { size: 0, position: 0 };
    for (let index = 0; index < points.length - 1; index += 1) {
      const start = points[index];
      const end = points[index + 1];
      const size = end - start;
      if (size > best.size) {
        best = { size, position: Math.round(start + size / 2) };
      }
    }
    return best;
  }

  function hasEnoughRoom(divisions, total) {
    return findLargestGap(divisions, total).size >= store.minDivisionGapMm * 2;
  }

  function setCadWarning(project, message) {
    return Object.assign({}, project, { cadWarning: message || "" });
  }

  function setActiveView(view) {
    return store.setState({ view });
  }

  function hydrateFromStorage() {
    const loadedProjects = storage.loadProjects();
    const loadedProject = storage.loadCurrentProject();
    const project = loadedProject || loadedProjects[0] || store.createProject();
    const normalizedProject = store.normalizeProject(project);
    const projects = loadedProjects.length ? loadedProjects.map(store.normalizeProject) : [normalizedProject];

    storage.saveCurrentProject(normalizedProject);
    storage.saveProjects(projects.some((item) => item.id === normalizedProject.id) ? projects : [normalizedProject].concat(projects));
    return store.setState({
      project: normalizedProject,
      projects: storage.loadProjects(),
      storageWarning: loadedProject ? "" : "Se inicio con proyecto demo porque no habia proyecto guardado.",
    });
  }

  function createNewProject() {
    pushHistory();
    const project = withHistory(store.createProject({
      name: `Proyecto ${new Date().toLocaleDateString("es-CL")}`,
      customer: store.createCustomer({
        name: "Cliente no asignado",
        rut: "",
        email: "",
        phone: "",
        address: "",
        city: "",
        notes: "",
      }),
      customerId: "",
      customerSnapshot: null,
      status: "borrador",
    }), "proyecto creado", "Proyecto creado desde VENTAPRO MVP.");
    return persist(project);
  }

  function updateProjectMeasurements(values) {
    pushHistory();
    const state = store.getState();
    const draft = Object.assign({}, state.project, {
      width: Number(values.width || 0),
      height: Number(values.height || 0),
      unit: values.unit,
      profileSystem: values.profileSystem,
      glassType: values.glassType,
      glassThickness: Number(values.glassThickness || state.project.glassThickness),
      margin: Number(values.margin || 0),
    });
    draft.verticalDivisions = store.normalizeDivisions(draft.verticalDivisions, "vertical", draft.width);
    draft.horizontalDivisions = store.normalizeDivisions(draft.horizontalDivisions, "horizontal", draft.height);
    return persist(withHistory(touchProject(draft), "medidas actualizadas", `${draft.width} x ${draft.height} ${draft.unit}`));
  }

  function updateProjectOptions(values) {
    pushHistory();
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      productType: values.productType,
      frameColor: values.frameColor,
    }));
    return persist(withHistory(project, "cliente actualizado", "Datos de cliente del proyecto actualizados."));
  }

  function updateCustomer(values) {
    pushHistory();
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      customer: Object.assign({}, state.project.customer, values || {}),
    }));
    return persist(withHistory(project, "panel editado", `Panel ${panelId} actualizado.`));
  }

  function updateProjectNotes(notes) {
    pushHistory();
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      notes: notes || "",
    }));
    return persist(withHistory(project, "division agregada", `Division ${orientation} agregada.`));
  }

  function updatePanel(panelId, values) {
    pushHistory();
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      panels: state.project.panels.map((panel) => (
        panel.id === panelId ? Object.assign({}, panel, values || {}) : panel
      )),
    }));
    return persist(withHistory(project, "panel editado", `Panel ${panelId} actualizado.`));
  }

  function selectPanel(panelId) {
    const state = store.getState();
    if (!state.project.panels.some((panel) => panel.id === panelId)) {
      return state;
    }
    const project = Object.assign({}, state.project, {
      selectedPanelId: panelId,
      selectedDivisionId: "",
      selectedDivisionOrientation: "",
    });
    storage.saveCurrentProject(project);
    return store.setState({ project });
  }

  function getSelectedPanel() {
    return store.getSelectedPanel(store.getState().project);
  }

  function updateSelectedPanel(values) {
    const selectedPanel = getSelectedPanel();
    if (!selectedPanel) {
      return store.getState();
    }
    return updatePanel(selectedPanel.id, values);
  }

  function selectDivision(id, orientation) {
    const state = store.getState();
    const divisions = store.getDivisionList(state.project, orientation);
    if (!divisions.some((division) => division.id === id)) {
      return state;
    }
    const project = Object.assign({}, state.project, {
      selectedDivisionId: id,
      selectedDivisionOrientation: orientation,
    });
    storage.saveCurrentProject(project);
    return store.setState({ project });
  }

  function addDivision(orientation) {
    pushHistory();
    const state = store.getState();
    const key = getDivisionKey(orientation);
    const total = getDivisionTotal(state.project, orientation);
    const divisions = store.normalizeDivisions(state.project[key], orientation, total);

    if (!hasEnoughRoom(divisions, total)) {
      const project = setCadWarning(state.project, "No hay espacio suficiente para otra division con margen minimo de 250 mm.");
      return persist(touchProject(project));
    }

    const gap = findLargestGap(divisions, total);
    const nextDivision = store.createDivision(orientation, gap.position, divisions.length);
    const project = touchProject(Object.assign({}, state.project, {
      [key]: divisions.concat(nextDivision),
      selectedDivisionId: nextDivision.id,
      selectedDivisionOrientation: orientation,
      cadWarning: "",
    }));
    return persist(withHistory(project, "division agregada", `Division ${orientation} agregada.`));
  }

  function updateDivisionPosition(id, orientation, positionMm) {
    const state = store.getState();
    const key = getDivisionKey(orientation);
    const total = getDivisionTotal(state.project, orientation);
    const divisions = store.normalizeDivisions(state.project[key], orientation, total);
    const current = divisions.find((division) => division.id === id);

    if (!current || current.locked) {
      return state;
    }

    const snappedPosition = Math.round(Number(positionMm || 0) / 50) * 50;
    const project = touchProject(Object.assign({}, state.project, {
      [key]: divisions.map((division) => (
        division.id === id ? Object.assign({}, division, { positionMm: snappedPosition }) : division
      )),
      selectedDivisionId: id,
      selectedDivisionOrientation: orientation,
      cadWarning: "",
    }));
    return persist(withHistory(project, "division movida", `${orientation} ${snappedPosition} mm.`));
  }

  function toggleDivisionLock(id, orientation) {
    pushHistory();
    const state = store.getState();
    const key = getDivisionKey(orientation);
    const divisions = store.getDivisionList(state.project, orientation);
    const project = touchProject(Object.assign({}, state.project, {
      [key]: divisions.map((division) => (
        division.id === id ? Object.assign({}, division, { locked: !division.locked }) : division
      )),
      selectedDivisionId: id,
      selectedDivisionOrientation: orientation,
    }));
    return persist(withHistory(project, "division eliminada", `${resolvedOrientation} ${id}.`));
  }

  function removeDivision(idOrOrientation, orientation) {
    pushHistory();
    const state = store.getState();
    const resolvedOrientation = orientation || idOrOrientation;
    const key = getDivisionKey(resolvedOrientation);
    const divisions = store.getDivisionList(state.project, resolvedOrientation);
    const id = orientation ? idOrOrientation : (divisions[divisions.length - 1] && divisions[divisions.length - 1].id);

    if (!id) {
      return state;
    }

    const project = touchProject(Object.assign({}, state.project, {
      [key]: divisions.filter((division) => division.id !== id),
      selectedDivisionId: state.project.selectedDivisionId === id ? "" : state.project.selectedDivisionId,
      selectedDivisionOrientation: state.project.selectedDivisionId === id ? "" : state.project.selectedDivisionOrientation,
      cadWarning: "",
    }));
    return persist(project);
  }

  function normalizeDivisions() {
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      verticalDivisions: store.normalizeDivisions(state.project.verticalDivisions, "vertical", state.project.width),
      horizontalDivisions: store.normalizeDivisions(state.project.horizontalDivisions, "horizontal", state.project.height),
    }));
    return persist(project);
  }

  function migrateOldDivisions() {
    return normalizeDivisions();
  }

  function regeneratePanelsFromDivisions() {
    const state = store.getState();
    const project = touchProject(Object.assign({}, state.project, {
      panels: store.createPanels(state.project),
    }));
    return persist(project);
  }

  function addVerticalDivision() {
    return addDivision("vertical");
  }

  function addHorizontalDivision() {
    return addDivision("horizontal");
  }

  function saveCurrentProject() {
    const state = store.getState();
    return persist(touchProject(state.project));
  }

  function loadProject(projectId) {
    const projects = storage.loadProjects();
    const project = projects.find((item) => item.id === projectId);
    if (!project) {
      console.warn(`VENTAPRO: proyecto no encontrado (${projectId}).`);
      return store.getState();
    }
    const normalizedProject = store.normalizeProject(project);
    storage.saveCurrentProject(normalizedProject);
    return store.setState({ project: normalizedProject, projects });
  }

  function duplicateProject(projectId) {
    const state = store.getState();
    const source = state.projects.find((item) => item.id === projectId) || state.project;
    const project = store.duplicateProject(source);
    return persist(project);
  }

  function deleteProject(projectId) {
    const state = store.getState();
    const remaining = state.projects.filter((item) => item.id !== projectId);
    const nextProject = state.project.id === projectId ? (remaining[0] || store.createProject()) : state.project;
    const projects = remaining.length ? remaining : [nextProject];

    storage.saveProjects(projects);
    storage.saveCurrentProject(nextProject);
    return store.setState({ project: nextProject, projects });
  }

  function resetProject() {
    pushHistory();
    const project = store.createProject();
    storage.clearCurrentProject();
    return persist(project);
  }

  function syncProjectOutputs(calc, billOfMaterials, cuts) {
    const state = store.getState();
    const quoteNumber = storage.generateQuoteNumber(state.project.quote && state.project.quote.quoteNumber);
    const quote = quoteBuilder.buildQuote(state.project, calc, billOfMaterials, cuts, companyData, quoteNumber);
    const hasQuote = Boolean(state.project.quote && state.project.quote.quoteNumber);
    const draft = Object.assign({}, state.project, {
      quote,
      calculations: calc,
      cutList: cuts,
    });
    const project = store.normalizeProject(hasQuote ? draft : withHistory(draft, "cotizacion generada", quote.quoteNumber));

    storage.saveCurrentProject(project);
    const projects = storage.upsertProject(project);
    return store.setState({ project, projects });
  }

  function updateQuoteSettings(values) {
    pushHistory();
    const state = store.getState();
    const quote = Object.assign({}, state.project.quote || {}, values || {});
    const project = touchProject(Object.assign({}, state.project, { quote }));
    return persist(withHistory(project, "cotizacion actualizada", "Condiciones comerciales actualizadas."));
  }

  function saveCustomer(customer) {
    return customerStorage.saveCustomer(customer);
  }

  function deleteCustomer(id) {
    customerStorage.deleteCustomer(id);
    return customerStorage.listCustomers();
  }

  function associateCustomer(customerId) {
    pushHistory();
    const state = store.getState();
    const customer = customerStorage.getCustomer(customerId);
    if (!customer) {
      return state;
    }
    const snapshot = customerStorage.customerSnapshot(customer);
    const project = withHistory(touchProject(Object.assign({}, state.project, {
      customerId: customer.id,
      customerSnapshot: snapshot,
      customer: store.createCustomer(snapshot),
    })), "cliente asociado", snapshot.name || snapshot.companyName || customer.id);
    return persist(project);
  }

  function changeProjectStatus(status) {
    pushHistory();
    const state = store.getState();
    const project = withHistory(touchProject(Object.assign({}, state.project, {
      status,
    })), "estado cambiado", status);
    return persist(project);
  }

  function createProductionOrderFromCurrentProject() {
    const state = store.getState();
    const quoteStatus = state.project.quote && state.project.quote.status;
    if (quoteStatus !== "aprobada" && state.project.status !== "aprobado") {
      const project = store.addHistory(state.project, "orden no generada", "La cotizacion debe estar aprobada.");
      return persist(project);
    }
    const order = productionStorage.createOrderFromProject(state.project);
    const project = store.addHistory(touchProject(Object.assign({}, state.project, {
      status: "produccion",
    })), "orden de fabricacion generada", order.orderNumber);
    persist(project);
    return store.setState({ selectedProductionOrderId: order.id });
  }

  function selectProductionOrder(id) {
    return store.setState({ selectedProductionOrderId: id });
  }

  function updateProductionOrder(id, patch, action, detail) {
    const order = productionStorage.updateOrder(id, patch, action, detail);
    if (order) {
      store.setState({ selectedProductionOrderId: order.id });
    }
    return order;
  }

  function deleteProductionOrder(id) {
    productionStorage.deleteOrder(id);
    return store.setState({ selectedProductionOrderId: "" });
  }

  function saveInventoryItem(item) {
    const saved = inventoryStorage.saveItem(item);
    store.setState({ selectedInventoryItemId: saved.id });
    return saved;
  }

  function deleteInventoryItem(id) {
    inventoryStorage.deleteItem(id);
    return store.setState({ selectedInventoryItemId: "" });
  }

  function selectInventoryItem(id) {
    return store.setState({ selectedInventoryItemId: id });
  }

  function registerInventoryMovement(itemId, type, quantity, reason, notes) {
    return inventoryStorage.registerMovement({
      itemId,
      type,
      quantity,
      reason,
      notes,
      projectId: store.getState().project.id,
    });
  }

  function reserveMaterialsForSelectedOrder() {
    const state = store.getState();
    const order = productionStorage.getOrder(state.selectedProductionOrderId) || productionStorage.listOrders()[0];
    if (!order) {
      return { movements: [], warnings: ["No hay orden seleccionada."] };
    }
    const result = inventoryStorage.reserveMaterialsForOrder(order);
    productionStorage.updateOrder(order.id, {
      inventoryWarnings: result.warnings,
      materialsReservedAt: store.nowIso(),
    }, "materiales reservados", `${result.movements.length} movimientos, ${result.warnings.length} advertencias`);
    store.setState({ selectedProductionOrderId: order.id });
    return result;
  }

  function createInstallationFromSelectedOrder() {
    const state = store.getState();
    const order = productionStorage.getOrder(state.selectedProductionOrderId) || productionStorage.listOrders()[0];
    if (!order) {
      return null;
    }
    if (!["despacho", "instalacion"].includes(order.status)) {
      productionStorage.updateOrder(order.id, {
        installationWarning: "La orden debe estar en despacho o instalacion para programar instalacion.",
      }, "instalacion no programada", "Estado requerido: despacho o instalacion.");
      store.setState({ selectedProductionOrderId: order.id });
      return null;
    }

    const installation = installationStorage.createFromOrder(order);
    productionStorage.updateOrder(order.id, {
      installationId: installation.id,
      installationWarning: "",
    }, "instalacion programada", installation.installationNumber);
    return store.setState({
      selectedProductionOrderId: order.id,
      selectedInstallationId: installation.id,
    });
  }

  function selectInstallation(id) {
    return store.setState({ selectedInstallationId: id });
  }

  function updateInstallation(id, patch, action, detail) {
    const installation = installationStorage.updateInstallation(id, patch, action, detail);
    if (installation) {
      store.setState({ selectedInstallationId: installation.id });
    }
    return installation;
  }

  function updateInstallationChecklist(id, itemId, patch) {
    const installation = installationStorage.getInstallation(id);
    if (!installation) {
      return null;
    }
    const checklist = installation.checklist.map((item) => (
      item.id === itemId ? Object.assign({}, item, patch || {}) : item
    ));
    return updateInstallation(id, { checklist }, "checklist actualizado", itemId);
  }

  function deleteInstallation(id) {
    installationStorage.deleteInstallation(id);
    return store.setState({ selectedInstallationId: "" });
  }

  function closeProjectFromInstallation(id) {
    const installation = installationStorage.getInstallation(id);
    if (!installation || installation.status !== "completada") {
      return null;
    }

    const projects = storage.loadProjects();
    const source = projects.find((project) => project.id === installation.projectId);
    if (!source) {
      installationStorage.updateInstallation(id, {}, "cierre no aplicado", "Proyecto no encontrado.");
      return null;
    }

    const closedProject = store.addHistory(store.normalizeProject(Object.assign({}, source, {
      status: "terminado",
      updatedAt: store.nowIso(),
    })), "proyecto terminado", `Cierre desde instalacion ${installation.installationNumber}.`);
    const savedProjects = storage.upsertProject(closedProject);
    installationStorage.updateInstallation(id, {}, "proyecto cerrado", closedProject.name);

    const patch = {
      projects: savedProjects,
      selectedInstallationId: id,
    };
    if (store.getState().project.id === closedProject.id) {
      patch.project = closedProject;
    }
    return store.setState(patch);
  }

  window.VentaProActions = {
    setActiveView,
    pushHistory,
    undo,
    redo,
    canUndo,
    canRedo,
    setCadView,
    setCadZoom,
    zoomCad,
    resetCadView,
    fitCadView,
    setCadMode,
    panCad,
    setCadDragGuide,
    hydrateFromStorage,
    createNewProject,
    updateProjectMeasurements,
    updateProjectOptions,
    updateCustomer,
    updateProjectNotes,
    updatePanel,
    selectPanel,
    updateSelectedPanel,
    selectDivision,
    addDivision,
    updateDivisionPosition,
    toggleDivisionLock,
    removeDivision,
    normalizeDivisions,
    migrateOldDivisions,
    regeneratePanelsFromDivisions,
    getSelectedPanel,
    addVerticalDivision,
    addHorizontalDivision,
    saveCurrentProject,
    loadProject,
    duplicateProject,
    deleteProject,
    resetProject,
    syncProjectOutputs,
    updateQuoteSettings,
    saveCustomer,
    deleteCustomer,
    associateCustomer,
    changeProjectStatus,
    createProductionOrderFromCurrentProject,
    selectProductionOrder,
    updateProductionOrder,
    deleteProductionOrder,
    saveInventoryItem,
    deleteInventoryItem,
    selectInventoryItem,
    registerInventoryMovement,
    reserveMaterialsForSelectedOrder,
    createInstallationFromSelectedOrder,
    selectInstallation,
    updateInstallation,
    updateInstallationChecklist,
    deleteInstallation,
    closeProjectFromInstallation,
  };
})(window);
