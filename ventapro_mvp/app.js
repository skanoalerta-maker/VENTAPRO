(function (window, document) {
  "use strict";

  const constants = window.VentaProConstants;
  const store = window.VentaProStore;
  const actions = window.VentaProActions;
  const formatters = window.VentaProFormatters;
  const technicalData = window.VentaProTechnicalData;
  const catalogData = window.VentaProCatalogData;
  const demoData = window.VentaProDemoData;
  const customerStorage = window.VentaProCustomerStorageService;
  const productionStorage = window.VentaProProductionStorageService;
  const inventoryStorage = window.VentaProInventoryStorageService;
  const installationStorage = window.VentaProInstallationStorageService;
  const calculator = window.VentaProCalculator;
  const validators = window.VentaProValidators;
  const cutList = window.VentaProCutList;
  let activeDivisionDrag = null;
  let activePanDrag = null;

  function getElement(id) {
    return document.getElementById(id);
  }

  function buildContext() {
    const appState = store.getState();
    const project = appState.project;
    const viewState = store.toCalculationState(project);
    const calc = calculator.calculate(viewState, technicalData);
    const validations = validators.validateProject(viewState, calc, technicalData);
    const billOfMaterials = cutList.generateBillOfMaterials(viewState, calc, formatters);
    const cuts = cutList.generateCutList(viewState, calc);

    return {
      appState,
      state: viewState,
      project,
      projects: appState.projects,
      customers: customerStorage.searchCustomers(getElement("customerSearch") ? getElement("customerSearch").value : ""),
      productionOrders: productionStorage.searchOrders(
        getElement("productionSearch") ? getElement("productionSearch").value : "",
        getElement("productionStatusFilter") ? getElement("productionStatusFilter").value : "todos"
      ),
      inventoryItems: inventoryStorage.searchItems(
        getElement("inventorySearch") ? getElement("inventorySearch").value : "",
        getElement("inventoryCategoryFilter") ? getElement("inventoryCategoryFilter").value : "todos"
      ),
      inventoryMovements: inventoryStorage.listMovements(),
      lowStockItems: inventoryStorage.lowStockItems(),
      installations: installationStorage.searchInstallations(
        getElement("installationSearch") ? getElement("installationSearch").value : "",
        getElement("installationStatusFilter") ? getElement("installationStatusFilter").value : "todos",
        getElement("installationDateFilter") ? getElement("installationDateFilter").value : ""
      ),
      calc,
      validations,
      billOfMaterials,
      cutList: cuts,
      catalog: catalogData.catalog,
      demoData,
      technicalData,
      formatters,
      filter: getElement("catalogSearch") ? getElement("catalogSearch").value : "",
    };
  }

  function switchView(view) {
    actions.setActiveView(view);

    document.querySelectorAll(".view").forEach((el) => {
      el.classList.toggle("active", el.id === view);
    });

    document.querySelectorAll(".nav-item").forEach((el) => {
      el.classList.toggle("active", el.dataset.view === view);
    });

    getElement("viewTitle").textContent = constants.VIEW_TITLES[view];
  }

  function syncFormFromProject() {
    const project = store.getState().project;
    getElement("widthInput").value = project.width;
    getElement("heightInput").value = project.height;
    getElement("unitInput").value = project.unit;
    getElement("systemInput").value = project.profileSystem;
    getElement("glassInput").value = project.glassType;
    getElement("marginInput").value = project.margin;
    getElement("notesInput").value = project.notes || "";
    getElement("sidebarProject").textContent = project.name;
  }

  function syncInputs() {
    actions.updateProjectMeasurements({
      width: getElement("widthInput").value,
      height: getElement("heightInput").value,
      unit: getElement("unitInput").value,
      profileSystem: getElement("systemInput").value,
      glassType: getElement("glassInput").value,
      glassThickness: store.getState().project.glassThickness,
      margin: getElement("marginInput").value,
    });

    actions.saveCurrentProject();
    renderAll();
  }

  function syncNotes() {
    actions.updateProjectNotes(getElement("notesInput").value);
    renderAll();
  }

  function renderAll() {
    const context = buildContext();
    actions.syncProjectOutputs(context.calc, context.billOfMaterials, context.cutList);
    const syncedContext = buildContext();

    window.VentaProDashboardView.render(syncedContext);
    window.VentaProCatalogView.render(syncedContext);
    window.VentaProCustomersView.render(syncedContext);
    window.VentaProMeasuresView.render(syncedContext);
    window.VentaProCadView.render(syncedContext);
    window.VentaProQuoteView.render(syncedContext);
    window.VentaProErpView.render(syncedContext);
    window.VentaProAiView.render(syncedContext);
    getElement("sidebarProject").textContent = syncedContext.project.name;
    getElement("cadUndo").disabled = !actions.canUndo();
    getElement("cadRedo").disabled = !actions.canRedo();
  }

  function loadProjectAndRender(projectId) {
    actions.loadProject(projectId);
    syncFormFromProject();
    renderAll();
  }

  function registerNavigationEvents() {
    document.querySelectorAll("[data-view]").forEach((btn) => {
      btn.addEventListener("click", () => switchView(btn.dataset.view));
    });

    document.querySelectorAll("[data-view-shortcut]").forEach((btn) => {
      btn.addEventListener("click", () => switchView(btn.dataset.viewShortcut));
    });
  }

  function registerInputEvents() {
    [
      "widthInput",
      "heightInput",
      "unitInput",
      "systemInput",
      "glassInput",
      "marginInput",
    ].forEach((id) => {
      getElement(id).addEventListener("input", syncInputs);
    });

    [
      "openingInput",
      "panelGlassInput",
      "panelThicknessInput",
      "colorInput",
      "panelProfileInput",
      "panelNotesInput",
    ].forEach((id) => {
      getElement(id).addEventListener("input", syncSelectedPanel);
    });

    getElement("notesInput").addEventListener("input", syncNotes);
    getElement("catalogSearch").addEventListener("input", renderAll);
    getElement("customerSearch").addEventListener("input", renderAll);
    getElement("productionSearch").addEventListener("input", renderAll);
    getElement("productionStatusFilter").addEventListener("change", renderAll);
    getElement("inventorySearch").addEventListener("input", renderAll);
    getElement("inventoryCategoryFilter").addEventListener("change", renderAll);
    getElement("installationSearch").addEventListener("input", renderAll);
    getElement("installationStatusFilter").addEventListener("change", renderAll);
    getElement("installationDateFilter").addEventListener("change", renderAll);

    [
      "quoteStatusInput",
      "quoteDiscountInput",
      "quoteValidityInput",
      "quoteDeliveryInput",
      "quotePaymentInput",
      "quoteNotesInput",
    ].forEach((id) => {
      getElement(id).addEventListener("change", syncQuoteSettings);
    });
  }

  function syncQuoteSettings() {
    actions.updateQuoteSettings({
      status: getElement("quoteStatusInput").value,
      discount: Number(getElement("quoteDiscountInput").value || 0),
      validityDays: Number(getElement("quoteValidityInput").value || 15),
      validUntil: "",
      deliveryTime: getElement("quoteDeliveryInput").value,
      paymentTerms: getElement("quotePaymentInput").value,
      notes: getElement("quoteNotesInput").value,
    });
    renderAll();
  }

  function syncSelectedPanel(event) {
    const field = event.target.dataset.panelField;
    const rawValue = event.target.value;
    const value = field === "glassThickness" ? Number(rawValue) : rawValue;

    actions.updateSelectedPanel({ [field]: value });
    renderAll();
  }

  function registerCadEvents() {
    getElement("addVertical").addEventListener("click", () => {
      actions.addVerticalDivision();
      syncFormFromProject();
      renderAll();
    });

    getElement("addHorizontal").addEventListener("click", () => {
      actions.addHorizontalDivision();
      syncFormFromProject();
      renderAll();
    });

    getElement("removeVertical").addEventListener("click", () => {
      actions.removeDivision("vertical");
      syncFormFromProject();
      renderAll();
    });

    getElement("removeHorizontal").addEventListener("click", () => {
      actions.removeDivision("horizontal");
      syncFormFromProject();
      renderAll();
    });

    getElement("cadSvg").addEventListener("click", (event) => {
      if (activeDivisionDrag && activeDivisionDrag.moved) {
        activeDivisionDrag = null;
        return;
      }
      if (activePanDrag && activePanDrag.moved) {
        activePanDrag = null;
        return;
      }
      const divisionNode = event.target.closest("[data-division-id]");
      if (divisionNode) {
        actions.selectDivision(divisionNode.dataset.divisionId, divisionNode.dataset.divisionOrientation);
        renderAll();
        return;
      }
      const panelNode = event.target.closest("[data-panel-id]");
      if (!panelNode) {
        return;
      }
      actions.selectPanel(panelNode.dataset.panelId);
      renderAll();
    });

    getElement("cadSvg").addEventListener("pointerdown", (event) => {
      const divisionNode = event.target.closest("[data-division-id]");
      const panelNode = event.target.closest("[data-panel-id]");
      const cadView = store.getState().cadView;

      if (!divisionNode && cadView.mode === "pan" && !panelNode) {
        activePanDrag = {
          x: event.clientX,
          y: event.clientY,
          moved: false,
        };
        event.preventDefault();
        return;
      }

      if (!divisionNode) {
        return;
      }
      const project = store.getState().project;
      const orientation = divisionNode.dataset.divisionOrientation;
      const divisions = orientation === "horizontal" ? project.horizontalDivisions : project.verticalDivisions;
      const division = divisions.find((item) => item.id === divisionNode.dataset.divisionId);
      if (!division || division.locked) {
        return;
      }
      activeDivisionDrag = {
        id: division.id,
        orientation,
        moved: false,
      };
      actions.pushHistory();
      actions.selectDivision(division.id, orientation);
      event.preventDefault();
    });

    window.addEventListener("pointermove", (event) => {
      if (activePanDrag) {
        const deltaX = event.clientX - activePanDrag.x;
        const deltaY = event.clientY - activePanDrag.y;
        if (Math.abs(deltaX) > 0 || Math.abs(deltaY) > 0) {
          activePanDrag.moved = true;
          activePanDrag.x = event.clientX;
          activePanDrag.y = event.clientY;
          actions.panCad(deltaX, deltaY);
          renderAll();
        }
        return;
      }

      if (!activeDivisionDrag) {
        return;
      }
      const position = getDivisionPositionFromPointer(event, activeDivisionDrag.orientation);
      if (position == null) {
        return;
      }
      activeDivisionDrag.moved = true;
      actions.updateDivisionPosition(activeDivisionDrag.id, activeDivisionDrag.orientation, position);
      actions.setCadDragGuide(buildDragGuide(activeDivisionDrag.id, activeDivisionDrag.orientation));
      renderAll();
    });

    window.addEventListener("pointerup", () => {
      actions.setCadDragGuide(null);
      activeDivisionDrag = null;
      activePanDrag = null;
      renderAll();
    });

    getElement("divisionList").addEventListener("change", handleDivisionListEvent);
    getElement("divisionList").addEventListener("click", handleDivisionListEvent);

    getElement("cadZoomIn").addEventListener("click", () => {
      actions.zoomCad(0.1);
      renderAll();
    });

    getElement("cadZoomOut").addEventListener("click", () => {
      actions.zoomCad(-0.1);
      renderAll();
    });

    getElement("cadResetView").addEventListener("click", () => {
      actions.resetCadView();
      renderAll();
    });

    getElement("cadFitView").addEventListener("click", () => {
      actions.fitCadView();
      renderAll();
    });

    getElement("cadPanMode").addEventListener("click", () => {
      const mode = store.getState().cadView.mode === "pan" ? "select" : "pan";
      actions.setCadMode(mode);
      renderAll();
    });

    getElement("cadUndo").addEventListener("click", () => {
      actions.undo();
      syncFormFromProject();
      renderAll();
    });

    getElement("cadRedo").addEventListener("click", () => {
      actions.redo();
      syncFormFromProject();
      renderAll();
    });

    getElement("cadSvg").addEventListener("wheel", (event) => {
      event.preventDefault();
      actions.zoomCad(event.deltaY < 0 ? 0.08 : -0.08);
      renderAll();
    }, { passive: false });
  }

  function getDivisionPositionFromPointer(event, orientation) {
    const svg = getElement("cadSvg");
    const rect = svg.getBoundingClientRect();
    const viewBox = svg.viewBox.baseVal;
    const svgX = ((event.clientX - rect.left) / rect.width) * viewBox.width + viewBox.x;
    const svgY = ((event.clientY - rect.top) / rect.height) * viewBox.height + viewBox.y;
    const originX = Number(svg.dataset.originX || 0);
    const originY = Number(svg.dataset.originY || 0);
    const ratio = Number(svg.dataset.ratio || 1);
    const zoom = Number(svg.dataset.zoom || 1);
    const panX = Number(svg.dataset.panX || 0);
    const panY = Number(svg.dataset.panY || 0);
    const workspaceX = (svgX - panX) / zoom;
    const workspaceY = (svgY - panY) / zoom;
    return orientation === "horizontal"
      ? Math.round((workspaceY - originY) / ratio)
      : Math.round((workspaceX - originX) / ratio);
  }

  function buildDragGuide(id, orientation) {
    const project = store.getState().project;
    const divisions = orientation === "horizontal" ? project.horizontalDivisions : project.verticalDivisions;
    const total = orientation === "horizontal" ? project.height : project.width;
    const division = divisions.find((item) => item.id === id);
    if (!division) {
      return null;
    }
    const sorted = divisions.slice().sort((a, b) => a.positionMm - b.positionMm);
    const index = sorted.findIndex((item) => item.id === id);
    const previous = index <= 0 ? 0 : sorted[index - 1].positionMm;
    const next = index >= sorted.length - 1 ? total : sorted[index + 1].positionMm;
    return {
      orientation,
      positionMm: division.positionMm,
      beforeMm: division.positionMm - previous,
      afterMm: next - division.positionMm,
    };
  }

  function handleDivisionListEvent(event) {
    const target = event.target.closest("[data-division-action]");
    if (!target) {
      return;
    }

    const action = target.dataset.divisionAction;
    const id = target.dataset.divisionId;
    const orientation = target.dataset.divisionOrientation;

    if (action === "position" && event.type === "change") {
      actions.pushHistory();
      actions.updateDivisionPosition(id, orientation, target.value);
      renderAll();
    }

    if (action === "select" && event.type === "click") {
      actions.selectDivision(id, orientation);
      renderAll();
    }

    if (action === "lock" && event.type === "click") {
      actions.toggleDivisionLock(id, orientation);
      renderAll();
    }

    if (action === "remove" && event.type === "click") {
      actions.removeDivision(id, orientation);
      renderAll();
    }
  }

  function registerProjectEvents() {
    getElement("projectList").addEventListener("click", (event) => {
      const button = event.target.closest("[data-project-action]");
      if (!button) {
        return;
      }

      const action = button.dataset.projectAction;
      const projectId = button.dataset.projectId;

      if (action === "new") {
        actions.createNewProject();
        syncFormFromProject();
        renderAll();
      }

      if (action === "open") {
        loadProjectAndRender(projectId);
      }

      if (action === "duplicate") {
        actions.duplicateProject(projectId);
        syncFormFromProject();
        renderAll();
      }

      if (action === "delete") {
        actions.deleteProject(projectId);
        syncFormFromProject();
        renderAll();
      }
    });

    getElement("projectList").addEventListener("change", (event) => {
      const target = event.target.closest("[data-project-action]");
      if (!target) {
        return;
      }
      const action = target.dataset.projectAction;
      if (action === "status") {
        loadProjectAndRender(target.dataset.projectId);
        actions.changeProjectStatus(target.value);
        renderAll();
      }
      if (action === "associate" && target.value) {
        loadProjectAndRender(target.dataset.projectId);
        actions.associateCustomer(target.value);
        renderAll();
      }
    });
  }

  function customerFromForm() {
    return {
      id: getElement("customerIdInput").value,
      type: getElement("customerTypeInput").value,
      status: getElement("customerStatusInput").value,
      name: getElement("customerNameInput").value,
      companyName: getElement("customerCompanyInput").value,
      rut: getElement("customerRutInput").value,
      email: getElement("customerEmailInput").value,
      phone: getElement("customerPhoneInput").value,
      secondaryPhone: getElement("customerSecondaryPhoneInput").value,
      address: getElement("customerAddressInput").value,
      city: getElement("customerCityInput").value,
      region: getElement("customerRegionInput").value,
      notes: getElement("customerNotesInput").value,
    };
  }

  function fillCustomerForm(customer) {
    const value = customer || customerStorage.normalizeCustomer({});
    getElement("customerIdInput").value = value.id || "";
    getElement("customerTypeInput").value = value.type || "particular";
    getElement("customerStatusInput").value = value.status || "prospecto";
    getElement("customerNameInput").value = value.name || "";
    getElement("customerCompanyInput").value = value.companyName || "";
    getElement("customerRutInput").value = value.rut || "";
    getElement("customerEmailInput").value = value.email || "";
    getElement("customerPhoneInput").value = value.phone || "";
    getElement("customerSecondaryPhoneInput").value = value.secondaryPhone || "";
    getElement("customerAddressInput").value = value.address || "";
    getElement("customerCityInput").value = value.city || "";
    getElement("customerRegionInput").value = value.region || "";
    getElement("customerNotesInput").value = value.notes || "";
    store.setState({ selectedCustomerId: value.id || "" });
  }

  function registerCustomerEvents() {
    getElement("newCustomerBtn").addEventListener("click", () => {
      fillCustomerForm(customerStorage.normalizeCustomer({ id: "" }));
    });

    getElement("saveCustomerBtn").addEventListener("click", () => {
      const customer = actions.saveCustomer(customerFromForm());
      fillCustomerForm(customer);
      renderAll();
    });

    getElement("customerList").addEventListener("click", (event) => {
      const button = event.target.closest("[data-customer-action]");
      if (!button) {
        return;
      }
      const customerId = button.dataset.customerId;
      const action = button.dataset.customerAction;
      if (action === "edit") {
        fillCustomerForm(customerStorage.getCustomer(customerId));
        renderAll();
      }
      if (action === "associate") {
        actions.associateCustomer(customerId);
        fillCustomerForm(customerStorage.getCustomer(customerId));
        renderAll();
      }
      if (action === "delete") {
        actions.deleteCustomer(customerId);
        fillCustomerForm(null);
        renderAll();
      }
    });
  }

  function registerUtilityEvents() {
    getElement("themeToggle").addEventListener("click", () => {
      document.body.classList.toggle("dark");
    });

    getElement("fakePdfBtn").addEventListener("click", () => {
      window.print();
    });

    getElement("printQuoteBtn").addEventListener("click", () => {
      window.print();
    });

    getElement("generateProductionOrderBtn").addEventListener("click", () => {
      actions.createProductionOrderFromCurrentProject();
      renderAll();
      switchView("erp");
    });
  }

  function inventoryFromForm() {
    return {
      id: getElement("inventoryIdInput").value,
      code: getElement("inventoryCodeInput").value,
      name: getElement("inventoryNameInput").value,
      category: getElement("inventoryCategoryInput").value,
      unit: getElement("inventoryUnitInput").value,
      stock: Number(getElement("inventoryStockInput").value || 0),
      minStock: Number(getElement("inventoryMinStockInput").value || 0),
      cost: Number(getElement("inventoryCostInput").value || 0),
      supplier: getElement("inventorySupplierInput").value,
      color: getElement("inventoryColorInput").value,
      notes: getElement("inventoryNotesInput").value,
    };
  }

  function fillInventoryForm(item) {
    const value = item || {};
    getElement("inventoryIdInput").value = value.id || "";
    getElement("inventoryCodeInput").value = value.code || "";
    getElement("inventoryNameInput").value = value.name || "";
    getElement("inventoryCategoryInput").value = value.category || "perfil";
    getElement("inventoryUnitInput").value = value.unit || "unidad";
    getElement("inventoryStockInput").value = value.stock || 0;
    getElement("inventoryMinStockInput").value = value.minStock || 0;
    getElement("inventoryCostInput").value = value.cost || 0;
    getElement("inventorySupplierInput").value = value.supplier || "";
    getElement("inventoryColorInput").value = value.color || "";
    getElement("inventoryNotesInput").value = value.notes || "";
    store.setState({ selectedInventoryItemId: value.id || "" });
  }

  function registerProductionEvents() {
    getElement("productionList").addEventListener("click", (event) => {
      const button = event.target.closest("[data-production-action]");
      if (!button) {
        return;
      }
      const action = button.dataset.productionAction;
      const orderId = button.dataset.orderId;
      if (action === "open") {
        actions.selectProductionOrder(orderId);
      }
      if (action === "delete") {
        actions.deleteProductionOrder(orderId);
      }
      renderAll();
    });

    getElement("productionList").addEventListener("change", (event) => {
      const target = event.target.closest("[data-production-action]");
      if (!target) {
        return;
      }
      const orderId = target.dataset.orderId;
      if (target.dataset.productionAction === "status") {
        actions.updateProductionOrder(orderId, { status: target.value }, "estado cambiado", target.value);
      }
      if (target.dataset.productionAction === "priority") {
        actions.updateProductionOrder(orderId, { priority: target.value }, "prioridad cambiada", target.value);
      }
      if (target.dataset.productionAction === "notes") {
        actions.updateProductionOrder(orderId, { notes: target.value }, "notas actualizadas", target.value);
      }
      renderAll();
    });

    getElement("reserveMaterialsBtn").addEventListener("click", () => {
      actions.reserveMaterialsForSelectedOrder();
      renderAll();
    });

    getElement("scheduleInstallationBtn").addEventListener("click", () => {
      actions.createInstallationFromSelectedOrder();
      renderAll();
    });

    getElement("inventoryTable").addEventListener("click", (event) => {
      const button = event.target.closest("[data-inventory-action]");
      if (!button) {
        return;
      }
      const itemId = button.dataset.itemId;
      if (button.dataset.inventoryAction === "edit") {
        actions.selectInventoryItem(itemId);
        fillInventoryForm(inventoryStorage.getItem(itemId));
      }
      if (button.dataset.inventoryAction === "delete") {
        actions.deleteInventoryItem(itemId);
        fillInventoryForm(null);
      }
      renderAll();
    });

    getElement("newInventoryItemBtn").addEventListener("click", () => {
      fillInventoryForm(null);
    });

    getElement("saveInventoryItemBtn").addEventListener("click", () => {
      const item = actions.saveInventoryItem(inventoryFromForm());
      fillInventoryForm(item);
      renderAll();
    });

    getElement("inventoryEntryBtn").addEventListener("click", () => {
      const itemId = store.getState().selectedInventoryItemId || getElement("inventoryIdInput").value;
      actions.registerInventoryMovement(itemId, "entrada", getElement("inventoryMoveQtyInput").value, "Entrada manual", "");
      fillInventoryForm(inventoryStorage.getItem(itemId));
      renderAll();
    });

    getElement("inventoryExitBtn").addEventListener("click", () => {
      const itemId = store.getState().selectedInventoryItemId || getElement("inventoryIdInput").value;
      actions.registerInventoryMovement(itemId, "salida", getElement("inventoryMoveQtyInput").value, "Salida manual", "");
      fillInventoryForm(inventoryStorage.getItem(itemId));
      renderAll();
    });

    getElement("installationList").addEventListener("click", (event) => {
      const button = event.target.closest("[data-installation-action]");
      if (!button) {
        return;
      }
      const installationId = button.dataset.installationId;
      if (button.dataset.installationAction === "open") {
        actions.selectInstallation(installationId);
      }
      if (button.dataset.installationAction === "delete") {
        actions.deleteInstallation(installationId);
      }
      renderAll();
    });

    getElement("installationDetail").addEventListener("change", (event) => {
      const target = event.target.closest("[data-installation-action]");
      if (!target) {
        return;
      }
      const installationId = target.dataset.installationId;
      const action = target.dataset.installationAction;
      const patch = {};
      patch[action] = target.value;
      actions.updateInstallation(installationId, patch, `${action} actualizado`, target.value);
      renderAll();
    });

    getElement("installationChecklist").addEventListener("change", (event) => {
      const target = event.target.closest("[data-checklist-action]");
      if (!target) {
        return;
      }
      const patch = {};
      if (target.dataset.checklistAction === "checked") {
        patch.checked = target.checked;
      }
      if (target.dataset.checklistAction === "notes") {
        patch.notes = target.value;
      }
      actions.updateInstallationChecklist(target.dataset.installationId, target.dataset.checklistId, patch);
      renderAll();
    });

    getElement("closeProjectFromInstallationBtn").addEventListener("click", () => {
      const installationId = store.getState().selectedInstallationId;
      actions.closeProjectFromInstallation(installationId);
      renderAll();
    });
  }

  function init() {
    actions.hydrateFromStorage();
    syncFormFromProject();
    registerNavigationEvents();
    registerInputEvents();
    registerCadEvents();
    registerProjectEvents();
    registerCustomerEvents();
    registerProductionEvents();
    registerUtilityEvents();
    renderAll();
  }

  init();
})(window, document);
