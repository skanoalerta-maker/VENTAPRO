(function (window, document) {
  "use strict";

  const projectStatuses = ["borrador", "cotizado", "enviado", "aprobado", "produccion", "instalacion", "terminado", "cancelado"];

  function customerLabel(project) {
    return project.customerSnapshot?.companyName || project.customerSnapshot?.name || project.customer?.name || "Cliente no asignado";
  }

  function projectActions(project, customers) {
    return `
      <div class="project-actions">
        <button class="tool" data-project-action="open" data-project-id="${project.id}">Abrir</button>
        <button class="tool" data-project-action="duplicate" data-project-id="${project.id}">Duplicar</button>
        <button class="tool" data-project-action="delete" data-project-id="${project.id}">Eliminar</button>
      </div>
      <div class="project-actions">
        <select data-project-action="status" data-project-id="${project.id}">
          ${projectStatuses.map((status) => `<option value="${status}" ${project.status === status ? "selected" : ""}>${status}</option>`).join("")}
        </select>
        <select data-project-action="associate" data-project-id="${project.id}">
          <option value="">Asociar cliente</option>
          ${customers.map((customer) => `<option value="${customer.id}" ${project.customerId === customer.id ? "selected" : ""}>${customer.companyName || customer.name}</option>`).join("")}
        </select>
      </div>
    `;
  }

  function renderProjects(context) {
    const activeId = context.project.id;
    const projects = context.projects.length ? context.projects : [context.project];

    return `
      <div class="project-toolbar">
        <button class="primary-action" data-project-action="new">Nuevo proyecto</button>
      </div>
      ${projects.map((project) => `
        <div class="list-item project-item ${project.id === activeId ? "active-project" : ""}">
          <strong>${project.name}</strong>
          <span>${customerLabel(project)} - ${project.status} - ${project.updatedAt.slice(0, 10)}</span>
          <span>${context.formatters.money(project.quote.finalTotal || 0)} - ${project.panels.length} paneles - ${project.quote.status || "borrador"}</span>
          ${projectActions(project, context.customers || [])}
        </div>
      `).join("")}
    `;
  }

  function render(context) {
    const projectList = document.getElementById("projectList");
    const wasteKpi = document.getElementById("wasteKpi");
    const alertList = document.getElementById("alertList");
    const projects = context.projects.length ? context.projects : [context.project];
    const totalQuoted = projects.reduce((sum, project) => sum + Number(project.quote.finalTotal || 0), 0);
    const sent = projects.filter((project) => ["enviada", "enviado"].includes(project.quote.status) || project.status === "enviado").length;
    const approved = projects.filter((project) => project.quote.status === "aprobada" || project.status === "aprobado").length;
    const orders = context.productionOrders || [];
    const pendingOrders = orders.filter((order) => order.status === "pendiente").length;
    const activeOrders = orders.filter((order) => ["en_fabricacion", "corte", "armado", "vidriado", "control_calidad"].includes(order.status)).length;
    const doneOrders = orders.filter((order) => order.status === "terminado").length;
    const orderedProjectIds = orders.map((order) => order.projectId);
    const approvedWithoutOrder = projects.filter((project) => (
      (project.quote.status === "aprobada" || project.status === "aprobado") && !orderedProjectIds.includes(project.id)
    )).length;
    const noStock = (context.inventoryItems || []).filter((item) => Number(item.stock || 0) <= 0).length;
    const materialWarnings = orders.filter((order) => (order.inventoryWarnings || []).length).length;
    const installations = context.installations || [];
    const scheduledInstallations = installations.filter((installation) => installation.status === "programada").length;
    const pendingInstallations = installations.filter((installation) => installation.status === "pendiente").length;
    const completedInstallations = installations.filter((installation) => installation.status === "completada").length;
    const observedInstallations = installations.filter((installation) => installation.status === "observada").length;
    const today = new Date().toISOString().slice(0, 10);
    const upcomingInstallations = installations.filter((installation) => (
      installation.scheduledDate && installation.scheduledDate >= today && !["completada", "cancelada"].includes(installation.status)
    )).length;

    document.querySelector(".kpi-card:nth-child(1) strong").textContent = String(projects.length);
    document.querySelector(".kpi-card:nth-child(1) small").textContent = `${context.customers.length} clientes · ${context.lowStockItems.length} bajo mínimo`;
    document.querySelector(".kpi-card:nth-child(2) strong").textContent = context.formatters.money(totalQuoted);
    document.querySelector(".kpi-card:nth-child(2) small").textContent = `${sent} cotizaciones enviadas`;
    document.querySelector(".kpi-card:nth-child(3) strong").textContent = `${activeOrders} en fabricación`;
    document.querySelector(".kpi-card:nth-child(3) small").textContent = `${pendingOrders} pendientes · ${doneOrders} terminadas · ${noStock} sin stock`;
    document.querySelector(".kpi-card:nth-child(4) span").textContent = "Instalaciones";
    document.querySelector(".kpi-card:nth-child(4) strong").textContent = `${scheduledInstallations} programadas`;
    document.querySelector(".kpi-card:nth-child(4) small").textContent = `${pendingInstallations} pendientes · ${completedInstallations} completadas`;

    projectList.innerHTML = renderProjects(context);
    wasteKpi.textContent = context.formatters.percent(context.calc.waste);
    alertList.innerHTML = [
      ["good", "Dise\u00f1o dentro de rango de fabricaci\u00f3n."],
      [approvedWithoutOrder > 0 ? "warn" : "good", `${approvedWithoutOrder} proyectos aprobados sin orden.`],
      [materialWarnings > 0 ? "warn" : "good", `${materialWarnings} órdenes con materiales pendientes.`],
      [observedInstallations > 0 ? "warn" : "good", `${observedInstallations} instalaciones observadas.`],
      [upcomingInstallations > 0 ? "good" : "warn", `${upcomingInstallations} proximas instalaciones.`],
      [context.calc.weight > 80 ? "warn" : "good", `Peso estimado: ${context.calc.weight.toFixed(1)} kg.`],
      [context.calc.bars > 2 ? "warn" : "good", `Barras comerciales requeridas: ${context.calc.bars}.`],
    ].map(([type, text]) => `<div class="alert ${type}">${text}</div>`).join("");
  }

  window.VentaProDashboardView = {
    render,
  };
})(window, document);
