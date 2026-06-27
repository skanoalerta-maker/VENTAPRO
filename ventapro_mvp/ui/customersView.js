(function (window, document) {
  "use strict";

  function customerName(customer) {
    return customer.companyName || customer.name || "Cliente sin nombre";
  }

  function renderHistory(context) {
    const selectedId = context.appState.selectedCustomerId || context.project.customerId;
    const projects = context.projects.filter((project) => project.customerId === selectedId);
    document.getElementById("customerProjectHistory").innerHTML = projects.length ? projects.map((project) => `
      <div class="list-item">
        <strong>${project.name}</strong>
        <span>${project.status} - ${context.formatters.money(project.quote.finalTotal || 0)} - ${project.updatedAt.slice(0, 10)}</span>
      </div>
    `).join("") : "<div class=\"division-empty\">Sin proyectos asociados.</div>";
  }

  function render(context) {
    const activeCustomerId = context.appState.selectedCustomerId || context.project.customerId;
    const customers = context.customers || [];

    document.getElementById("customerList").innerHTML = customers.length ? customers.map((customer) => `
      <div class="customer-item ${customer.id === activeCustomerId ? "active-project" : ""}">
        <div>
          <strong>${customerName(customer)}</strong>
          <span>${customer.status} - ${customer.rut || "Sin RUT"} - ${customer.phone || "Sin telefono"}</span>
          <small>${customer.email || "Sin correo"} · ${customer.city || ""}</small>
        </div>
        <div class="project-actions">
          <button class="tool" data-customer-action="edit" data-customer-id="${customer.id}">Editar</button>
          <button class="tool" data-customer-action="associate" data-customer-id="${customer.id}">Asociar</button>
          <button class="tool" data-customer-action="delete" data-customer-id="${customer.id}">Eliminar</button>
        </div>
      </div>
    `).join("") : "<div class=\"division-empty\">No hay clientes guardados.</div>";

    renderHistory(context);
  }

  window.VentaProCustomersView = {
    render,
  };
})(window, document);
