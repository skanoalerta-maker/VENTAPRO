(function (window) {
  "use strict";

  const CUSTOMERS_KEY = "ventapro.customers";

  function nowIso() {
    return new Date().toISOString();
  }

  function createId() {
    return `customer-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  }

  function readCustomers() {
    try {
      const raw = window.localStorage.getItem(CUSTOMERS_KEY);
      const customers = raw ? JSON.parse(raw) : [];
      return Array.isArray(customers) ? customers.filter(Boolean).map(normalizeCustomer) : [];
    } catch (error) {
      console.warn("VENTAPRO: no se pudo leer clientes.", error);
      return [];
    }
  }

  function writeCustomers(customers) {
    try {
      window.localStorage.setItem(CUSTOMERS_KEY, JSON.stringify(customers.map(normalizeCustomer)));
      return true;
    } catch (error) {
      console.warn("VENTAPRO: no se pudo guardar clientes.", error);
      return false;
    }
  }

  function normalizeCustomer(customer) {
    const createdAt = customer && customer.createdAt ? customer.createdAt : nowIso();
    return Object.assign({
      id: createId(),
      type: "particular",
      name: "",
      rut: "",
      companyName: "",
      email: "",
      phone: "",
      secondaryPhone: "",
      address: "",
      city: "",
      region: "",
      notes: "",
      createdAt,
      updatedAt: createdAt,
      status: "prospecto",
    }, customer || {});
  }

  function customerSnapshot(customer) {
    const normalized = normalizeCustomer(customer || {});
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

  function listCustomers() {
    return readCustomers().sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  }

  function getCustomer(id) {
    return listCustomers().find((customer) => customer.id === id) || null;
  }

  function saveCustomer(customer) {
    const customers = listCustomers();
    const normalized = normalizeCustomer(Object.assign({}, customer, {
      id: customer.id || createId(),
      updatedAt: nowIso(),
    }));
    const index = customers.findIndex((item) => item.id === normalized.id);
    if (index >= 0) {
      customers[index] = normalized;
    } else {
      customers.unshift(normalized);
    }
    writeCustomers(customers);
    return normalized;
  }

  function deleteCustomer(id) {
    const customers = listCustomers().filter((customer) => customer.id !== id);
    writeCustomers(customers);
    return customers;
  }

  function searchCustomers(query) {
    const q = String(query || "").trim().toLowerCase();
    if (!q) {
      return listCustomers();
    }
    return listCustomers().filter((customer) => (
      [customer.name, customer.rut, customer.email, customer.phone, customer.secondaryPhone, customer.companyName]
        .join(" ")
        .toLowerCase()
        .includes(q)
    ));
  }

  window.VentaProCustomerStorageService = {
    normalizeCustomer,
    customerSnapshot,
    listCustomers,
    getCustomer,
    saveCustomer,
    deleteCustomer,
    searchCustomers,
  };
})(window);
