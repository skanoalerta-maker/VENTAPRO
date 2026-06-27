(function (window) {
  "use strict";

  const INSTALLATIONS_KEY = "ventapro.installations";
  const INSTALLATION_COUNTER_KEY = "ventapro.installationCounter";

  const defaultChecklistLabels = [
    "verificar medidas en obra",
    "revisar marco",
    "revisar vidrio",
    "revisar herrajes",
    "revisar sellado",
    "revisar limpieza",
    "prueba de apertura/cierre",
    "retiro de residuos",
    "conformidad cliente",
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function createId() {
    return `ins-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  }

  function readJson(key, fallback) {
    try {
      const raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (error) {
      console.warn(`VENTAPRO: no se pudo leer ${key}.`, error);
      return fallback;
    }
  }

  function writeJson(key, value) {
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (error) {
      console.warn(`VENTAPRO: no se pudo guardar ${key}.`, error);
      return false;
    }
  }

  function defaultChecklist() {
    return defaultChecklistLabels.map((label, index) => ({
      id: `chk-${index + 1}`,
      label,
      checked: false,
      notes: "",
    }));
  }

  function generateInstallationNumber(existingNumber) {
    if (existingNumber) {
      return existingNumber;
    }
    const year = new Date().getFullYear();
    const counter = readJson(INSTALLATION_COUNTER_KEY, {});
    const next = Number(counter[year] || 0) + 1;
    counter[year] = next;
    writeJson(INSTALLATION_COUNTER_KEY, counter);
    return `INS-${year}-${String(next).padStart(4, "0")}`;
  }

  function addHistory(installation, action, detail) {
    const history = Array.isArray(installation.history) ? installation.history.slice() : [];
    history.unshift({
      date: nowIso(),
      user: "sistema",
      action,
      detail: detail || "",
    });
    return Object.assign({}, installation, { history: history.slice(0, 100), updatedAt: nowIso() });
  }

  function normalizeChecklist(checklist) {
    const source = Array.isArray(checklist) && checklist.length ? checklist : defaultChecklist();
    return source.map((item, index) => ({
      id: item.id || `chk-${index + 1}`,
      label: item.label || defaultChecklistLabels[index] || `item ${index + 1}`,
      checked: Boolean(item.checked),
      notes: item.notes || "",
    }));
  }

  function normalizeInstallation(installation) {
    const createdAt = installation && installation.createdAt ? installation.createdAt : nowIso();
    return Object.assign({
      id: createId(),
      installationNumber: "",
      projectId: "",
      productionOrderId: "",
      customerId: "",
      customerSnapshot: null,
      projectSnapshot: null,
      status: "pendiente",
      scheduledDate: "",
      scheduledTime: "",
      address: "",
      city: "",
      assignedTeam: "",
      contactName: "",
      contactPhone: "",
      checklist: defaultChecklist(),
      photos: [],
      notes: "",
      customerSignature: "",
      createdAt,
      updatedAt: createdAt,
      history: [],
    }, installation || {}, {
      checklist: normalizeChecklist((installation || {}).checklist),
      photos: Array.isArray((installation || {}).photos) ? installation.photos : [],
      history: Array.isArray((installation || {}).history) ? installation.history : [],
    });
  }

  function listInstallations() {
    const installations = readJson(INSTALLATIONS_KEY, []);
    return Array.isArray(installations)
      ? installations.map(normalizeInstallation).sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
      : [];
  }

  function saveInstallations(installations) {
    return writeJson(INSTALLATIONS_KEY, installations.map(normalizeInstallation));
  }

  function saveInstallation(installation) {
    const normalized = normalizeInstallation(installation);
    const installations = listInstallations();
    const index = installations.findIndex((item) => item.id === normalized.id);
    if (index >= 0) {
      installations[index] = normalized;
    } else {
      installations.unshift(normalized);
    }
    saveInstallations(installations);
    return normalized;
  }

  function createFromOrder(order) {
    const existing = listInstallations().find((installation) => installation.productionOrderId === order.id);
    if (existing) {
      return existing;
    }

    const customer = order.customerSnapshot || {};
    const project = order.projectSnapshot || {};
    const installation = addHistory(normalizeInstallation({
      id: createId(),
      installationNumber: generateInstallationNumber(),
      projectId: order.projectId,
      productionOrderId: order.id,
      customerId: order.customerId,
      customerSnapshot: customer,
      projectSnapshot: Object.assign({}, project, {
        orderNumber: order.orderNumber,
        quoteTotal: order.quoteTotal || 0,
      }),
      status: "pendiente",
      scheduledDate: order.dueDate || "",
      scheduledTime: "",
      address: customer.address || "",
      city: customer.city || "",
      assignedTeam: order.assignedTo || "",
      contactName: customer.companyName || customer.name || "",
      contactPhone: customer.phone || "",
      notes: "",
    }), "creada", `Instalacion generada desde orden ${order.orderNumber || ""}.`);

    return saveInstallation(installation);
  }

  function getInstallation(id) {
    return listInstallations().find((installation) => installation.id === id) || null;
  }

  function updateInstallation(id, patch, action, detail) {
    const installation = getInstallation(id);
    if (!installation) {
      return null;
    }
    const updated = addHistory(Object.assign({}, installation, patch || {}), action || "actualizada", detail || "");
    return saveInstallation(updated);
  }

  function deleteInstallation(id) {
    const installations = listInstallations().filter((installation) => installation.id !== id);
    saveInstallations(installations);
    return installations;
  }

  function searchInstallations(query, status, scheduledDate) {
    const q = String(query || "").trim().toLowerCase();
    return listInstallations().filter((installation) => {
      const matchesStatus = !status || status === "todos" || installation.status === status;
      const matchesDate = !scheduledDate || installation.scheduledDate === scheduledDate;
      const text = [
        installation.installationNumber,
        installation.projectSnapshot?.name,
        installation.customerSnapshot?.name,
        installation.customerSnapshot?.companyName,
        installation.contactPhone,
      ].join(" ").toLowerCase();
      return matchesStatus && matchesDate && (!q || text.includes(q));
    });
  }

  window.VentaProInstallationStorageService = {
    defaultChecklist,
    normalizeInstallation,
    listInstallations,
    saveInstallation,
    createFromOrder,
    getInstallation,
    updateInstallation,
    deleteInstallation,
    searchInstallations,
    generateInstallationNumber,
  };
})(window);
