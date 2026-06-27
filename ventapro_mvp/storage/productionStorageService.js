(function (window) {
  "use strict";

  const ORDERS_KEY = "ventapro.productionOrders";
  const ORDER_COUNTER_KEY = "ventapro.productionOrderCounter";

  function nowIso() {
    return new Date().toISOString();
  }

  function createId() {
    return `op-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
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

  function generateOrderNumber(existingNumber) {
    if (existingNumber) {
      return existingNumber;
    }
    const year = new Date().getFullYear();
    const counter = readJson(ORDER_COUNTER_KEY, {});
    const next = Number(counter[year] || 0) + 1;
    counter[year] = next;
    writeJson(ORDER_COUNTER_KEY, counter);
    return `OP-${year}-${String(next).padStart(4, "0")}`;
  }

  function addHistory(order, action, detail) {
    const history = Array.isArray(order.history) ? order.history.slice() : [];
    history.unshift({
      date: nowIso(),
      user: "sistema",
      action,
      detail: detail || "",
    });
    return Object.assign({}, order, { history: history.slice(0, 100), updatedAt: nowIso() });
  }

  function normalizeOrder(order) {
    const createdAt = order.createdAt || nowIso();
    return Object.assign({
      id: createId(),
      orderNumber: "",
      projectId: "",
      quoteId: "",
      customerId: "",
      customerSnapshot: null,
      projectSnapshot: null,
      status: "pendiente",
      priority: "media",
      createdAt,
      updatedAt: createdAt,
      dueDate: "",
      assignedTo: "",
      panels: [],
      materials: [],
      cutList: [],
      quoteTotal: 0,
      notes: "",
      history: [],
    }, order || {});
  }

  function listOrders() {
    const orders = readJson(ORDERS_KEY, []);
    return Array.isArray(orders) ? orders.map(normalizeOrder).sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)) : [];
  }

  function saveOrders(orders) {
    return writeJson(ORDERS_KEY, orders.map(normalizeOrder));
  }

  function saveOrder(order) {
    const normalized = normalizeOrder(order);
    const orders = listOrders();
    const index = orders.findIndex((item) => item.id === normalized.id);
    if (index >= 0) {
      orders[index] = normalized;
    } else {
      orders.unshift(normalized);
    }
    saveOrders(orders);
    return normalized;
  }

  function createOrderFromProject(project) {
    const quote = project.quote || {};
    const existing = listOrders().find((order) => order.projectId === project.id && order.quoteId === quote.quoteId);
    if (existing) {
      return existing;
    }

    const order = addHistory(normalizeOrder({
      id: createId(),
      orderNumber: generateOrderNumber(),
      projectId: project.id,
      quoteId: quote.quoteId,
      customerId: project.customerId,
      customerSnapshot: project.customerSnapshot,
      projectSnapshot: {
        id: project.id,
        name: project.name,
        width: project.width,
        height: project.height,
        panels: project.panels.length,
        status: project.status,
        quoteNumber: quote.quoteNumber,
      },
      status: "pendiente",
      priority: "media",
      dueDate: quote.validUntil || "",
      panels: project.panels,
      materials: quote.materialsSummary || [],
      cutList: quote.cutListSummary || project.cutList || [],
      quoteTotal: quote.finalTotal || 0,
      notes: "",
    }), "creada", `Orden generada desde cotizacion ${quote.quoteNumber || ""}.`);

    return saveOrder(order);
  }

  function getOrder(id) {
    return listOrders().find((order) => order.id === id) || null;
  }

  function updateOrder(id, patch, action, detail) {
    const order = getOrder(id);
    if (!order) {
      return null;
    }
    const updated = addHistory(Object.assign({}, order, patch || {}), action || "actualizada", detail || "");
    return saveOrder(updated);
  }

  function deleteOrder(id) {
    const orders = listOrders().filter((order) => order.id !== id);
    saveOrders(orders);
    return orders;
  }

  function searchOrders(query, status) {
    const q = String(query || "").trim().toLowerCase();
    return listOrders().filter((order) => {
      const matchesStatus = !status || status === "todos" || order.status === status;
      const text = [order.orderNumber, order.projectSnapshot?.name, order.customerSnapshot?.name, order.customerSnapshot?.companyName].join(" ").toLowerCase();
      return matchesStatus && (!q || text.includes(q));
    });
  }

  window.VentaProProductionStorageService = {
    listOrders,
    saveOrder,
    createOrderFromProject,
    getOrder,
    updateOrder,
    deleteOrder,
    searchOrders,
    generateOrderNumber,
  };
})(window);
