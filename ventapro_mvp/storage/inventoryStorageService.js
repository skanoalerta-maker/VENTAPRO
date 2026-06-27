(function (window) {
  "use strict";

  const ITEMS_KEY = "ventapro.inventoryItems";
  const MOVEMENTS_KEY = "ventapro.inventoryMovements";

  function nowIso() {
    return new Date().toISOString();
  }

  function createId(prefix) {
    return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
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

  function demoItems() {
    const createdAt = nowIso();
    return [
      ["MARCO-H", "Perfil marco horizontal aluminio", "perfil", "barra", 18, 6, 4200, "Proveedor Alum", "negro"],
      ["MARCO-V", "Perfil marco vertical aluminio", "perfil", "barra", 18, 6, 4200, "Proveedor Alum", "negro"],
      ["HOJA-H", "Perfil hoja corredera aluminio", "perfil", "barra", 12, 4, 4800, "Proveedor Alum", "negro"],
      ["JUNQUILLO", "Junquillo vidrio fijo", "perfil", "barra", 20, 6, 1800, "Proveedor Alum", "negro"],
      ["PVC-70", "Perfil PVC estándar", "perfil", "barra", 10, 3, 5200, "PVC Chile", "blanco"],
      ["VID-6", "Vidrio monolítico 6 mm", "vidrio", "m2", 42, 8, 18500, "Cristales Sur", "transparente"],
      ["VID-TERM", "Termopanel", "vidrio", "m2", 24, 6, 46500, "Cristales Sur", "transparente"],
      ["RUE-COR", "Ruedas corredera", "herraje", "unidad", 60, 20, 1450, "Herrajes Pro", ""],
      ["SIL-NEU", "Silicona neutra", "consumible", "unidad", 36, 10, 3200, "Sellos Ltda", ""],
      ["TOR-ALU", "Tornillos aluminio", "accesorio", "unidad", 800, 200, 35, "Fijaciones SPA", ""],
      ["BUR-EPDM", "Burlete EPDM", "accesorio", "metro", 180, 40, 450, "Sellos Ltda", "negro"],
      ["FELPA", "Felpa corredera", "accesorio", "metro", 120, 30, 380, "Herrajes Pro", "gris"],
    ].map(([code, name, category, unit, stock, minStock, cost, supplier, color]) => ({
      id: createId("item"),
      code,
      name,
      category,
      unit,
      stock,
      minStock,
      cost,
      supplier,
      color,
      notes: "",
      createdAt,
      updatedAt: createdAt,
    }));
  }

  function normalizeItem(item) {
    const createdAt = item && item.createdAt ? item.createdAt : nowIso();
    return Object.assign({
      id: createId("item"),
      code: "",
      name: "",
      category: "perfil",
      unit: "unidad",
      stock: 0,
      minStock: 0,
      cost: 0,
      supplier: "",
      color: "",
      notes: "",
      createdAt,
      updatedAt: createdAt,
    }, item || {});
  }

  function normalizeMovement(movement) {
    return Object.assign({
      id: createId("mov"),
      itemId: "",
      type: "entrada",
      quantity: 0,
      reason: "",
      projectId: "",
      productionOrderId: "",
      createdAt: nowIso(),
      notes: "",
    }, movement || {});
  }

  function listItems() {
    const items = readJson(ITEMS_KEY, null);
    if (!Array.isArray(items)) {
      const seeded = demoItems();
      writeJson(ITEMS_KEY, seeded);
      return seeded;
    }
    return items.map(normalizeItem).sort((a, b) => a.category.localeCompare(b.category) || a.code.localeCompare(b.code));
  }

  function saveItems(items) {
    return writeJson(ITEMS_KEY, items.map(normalizeItem));
  }

  function listMovements() {
    const movements = readJson(MOVEMENTS_KEY, []);
    return Array.isArray(movements) ? movements.map(normalizeMovement).sort((a, b) => b.createdAt.localeCompare(a.createdAt)) : [];
  }

  function saveMovements(movements) {
    return writeJson(MOVEMENTS_KEY, movements.map(normalizeMovement));
  }

  function saveItem(item) {
    const normalized = normalizeItem(Object.assign({}, item, {
      id: item.id || createId("item"),
      stock: Number(item.stock || 0),
      minStock: Number(item.minStock || 0),
      cost: Number(item.cost || 0),
      updatedAt: nowIso(),
    }));
    const items = listItems();
    const index = items.findIndex((existing) => existing.id === normalized.id);
    if (index >= 0) {
      items[index] = normalized;
    } else {
      items.unshift(normalized);
    }
    saveItems(items);
    return normalized;
  }

  function deleteItem(id) {
    const items = listItems().filter((item) => item.id !== id);
    saveItems(items);
    return items;
  }

  function searchItems(query, category) {
    const q = String(query || "").trim().toLowerCase();
    return listItems().filter((item) => {
      const matchesCategory = !category || category === "todos" || item.category === category;
      const text = [item.code, item.name, item.category, item.supplier, item.color].join(" ").toLowerCase();
      return matchesCategory && (!q || text.includes(q));
    });
  }

  function getItem(id) {
    return listItems().find((item) => item.id === id) || null;
  }

  function findByCodeOrCategory(code, category) {
    const items = listItems();
    return items.find((item) => item.code === code) ||
      items.find((item) => item.category === category) ||
      null;
  }

  function registerMovement(movement) {
    const normalized = normalizeMovement(Object.assign({}, movement, {
      id: movement.id || createId("mov"),
      quantity: Number(movement.quantity || 0),
      createdAt: nowIso(),
    }));
    const items = listItems();
    const index = items.findIndex((item) => item.id === normalized.itemId);
    if (index < 0) {
      return { item: null, movement: normalized, ok: false, warning: "Item no encontrado." };
    }

    const item = Object.assign({}, items[index]);
    if (normalized.type === "entrada") {
      item.stock += normalized.quantity;
    }
    if (normalized.type === "salida" || normalized.type === "reserva") {
      item.stock = Math.max(0, item.stock - normalized.quantity);
    }
    if (normalized.type === "ajuste") {
      item.stock = normalized.quantity;
    }
    item.updatedAt = nowIso();
    items[index] = item;
    saveItems(items);
    saveMovements([normalized].concat(listMovements()));
    return { item, movement: normalized, ok: true, warning: item.stock <= item.minStock ? "Stock bajo luego del movimiento." : "" };
  }

  function lowStockItems() {
    return listItems().filter((item) => item.stock <= item.minStock);
  }

  function reserveMaterialsForOrder(order) {
    const warnings = [];
    const movements = [];

    (order.cutList || []).forEach((row) => {
      const item = findByCodeOrCategory(row.code, "perfil");
      if (!item) {
        warnings.push(`Sin item para ${row.code}.`);
        return;
      }
      const quantity = Number(row.quantity || 0);
      if (item.stock < quantity) {
        warnings.push(`${item.code}: stock insuficiente (${item.stock}/${quantity}).`);
      }
      const result = registerMovement({
        itemId: item.id,
        type: "reserva",
        quantity,
        reason: `Reserva ${order.orderNumber}`,
        projectId: order.projectId,
        productionOrderId: order.id,
        notes: row.location || "",
      });
      if (result.ok) {
        movements.push(result.movement);
      }
      if (result.warning) {
        warnings.push(`${item.code}: ${result.warning}`);
      }
    });

    return { movements, warnings };
  }

  window.VentaProInventoryStorageService = {
    listItems,
    saveItem,
    deleteItem,
    searchItems,
    getItem,
    listMovements,
    registerMovement,
    lowStockItems,
    reserveMaterialsForOrder,
  };
})(window);
