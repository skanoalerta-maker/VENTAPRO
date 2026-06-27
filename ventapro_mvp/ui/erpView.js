(function (window, document) {
  "use strict";

  const statuses = ["pendiente", "en_fabricacion", "corte", "armado", "vidriado", "control_calidad", "despacho", "instalacion", "terminado", "pausado", "cancelado"];
  const installationStatuses = ["pendiente", "programada", "en_ruta", "en_instalacion", "observada", "completada", "reprogramada", "cancelada"];
  const priorities = ["baja", "media", "alta", "urgente"];

  function customerName(order) {
    return order.customerSnapshot?.companyName || order.customerSnapshot?.name || "Cliente no asignado";
  }

  function renderSelect(values, current, action, orderId) {
    return `
      <select data-production-action="${action}" data-order-id="${orderId}">
        ${values.map((value) => `<option value="${value}" ${value === current ? "selected" : ""}>${value}</option>`).join("")}
      </select>
    `;
  }

  function selectedOrder(context) {
    return context.productionOrders.find((order) => order.id === context.appState.selectedProductionOrderId) ||
      context.productionOrders[0] ||
      null;
  }

  function installationName(installation) {
    return installation.customerSnapshot?.companyName || installation.customerSnapshot?.name || "Cliente no asignado";
  }

  function selectedInstallation(context) {
    return context.installations.find((installation) => installation.id === context.appState.selectedInstallationId) ||
      context.installations[0] ||
      null;
  }

  function renderInstallationStatusSelect(installation) {
    return `
      <label>Estado
        <select data-installation-action="status" data-installation-id="${installation.id}">
          ${installationStatuses.map((status) => `<option value="${status}" ${installation.status === status ? "selected" : ""}>${status}</option>`).join("")}
        </select>
      </label>
    `;
  }

  function stockStatus(item) {
    if (Number(item.stock || 0) <= 0) {
      return ["danger", "sin stock"];
    }
    if (Number(item.stock || 0) <= Number(item.minStock || 0)) {
      return ["warn", "stock bajo"];
    }
    return ["good", "stock OK"];
  }

  function renderOrders(context) {
    document.getElementById("productionList").innerHTML = context.productionOrders.length ? context.productionOrders.map((order) => `
      <div class="list-item project-item ${order.id === context.appState.selectedProductionOrderId ? "active-project" : ""}">
        <strong>${order.orderNumber} - ${order.projectSnapshot?.name || "Proyecto"}</strong>
        <span>${customerName(order)} - ${order.status} - ${order.priority} - entrega ${order.dueDate || "sin fecha"}</span>
        <span>${context.formatters.money(order.quoteTotal || 0)} - ${order.panels.length} paneles - ${order.cutList.length} cortes</span>
        <div class="project-actions">
          <button class="tool" data-production-action="open" data-order-id="${order.id}">Abrir</button>
          <button class="tool" data-production-action="delete" data-order-id="${order.id}">Eliminar</button>
        </div>
        <div class="project-actions">
          ${renderSelect(statuses, order.status, "status", order.id)}
          ${renderSelect(priorities, order.priority, "priority", order.id)}
        </div>
        <textarea data-production-action="notes" data-order-id="${order.id}" placeholder="Notas de producción">${order.notes || ""}</textarea>
      </div>
    `).join("") : "<div class=\"division-empty\">No hay órdenes de fabricación.</div>";
  }

  function renderDetail(context, order) {
    const detail = document.getElementById("productionDetail");
    if (!order) {
      detail.innerHTML = "<div class=\"division-empty\">Selecciona una orden.</div>";
      document.getElementById("scheduleInstallationBtn").disabled = true;
      return;
    }

    detail.innerHTML = [
      ["Orden", order.orderNumber],
      ["Proyecto", order.projectSnapshot?.name || ""],
      ["Cliente", customerName(order)],
      ["Estado", order.status],
      ["Prioridad", order.priority],
      ["Asignado", order.assignedTo || "Sin asignar"],
      ["Total cotizado", context.formatters.money(order.quoteTotal || 0)],
      ["Historial", `${order.history.length} eventos`],
      ["Reserva", order.materialsReservedAt ? `Reservado ${order.materialsReservedAt.slice(0, 10)}` : "Pendiente"],
    ].map(([label, value]) => `<div class="metric"><span>${label}</span><strong>${value}</strong></div>`).join("");
    const scheduleBtn = document.getElementById("scheduleInstallationBtn");
    const canSchedule = ["despacho", "instalacion"].includes(order.status);
    scheduleBtn.disabled = !canSchedule;
    scheduleBtn.textContent = order.installationId ? "Ver / actualizar instalacion" : "Programar instalacion";
    document.getElementById("inventoryReservationWarnings").innerHTML = (order.inventoryWarnings || []).map((warning) => (
      `<div>${warning}</div>`
    )).concat(order.installationWarning ? [`<div>${order.installationWarning}</div>`] : []).join("");
  }

  function renderCutList(order) {
    document.getElementById("productionCutTable").innerHTML = order && order.cutList.length ? order.cutList.map((row) => `
      <tr>
        <td>${row.code}</td>
        <td>${row.description || ""}</td>
        <td>${row.color || ""}</td>
        <td>${row.length || row.lengthMm || ""}</td>
        <td>${row.quantity || ""}</td>
        <td>${row.leftAngle || ""}/${row.rightAngle || ""}</td>
        <td>${row.location || ""}</td>
      </tr>
    `).join("") : "<tr><td colspan=\"7\">Sin lista de corte.</td></tr>";
  }

  function renderMaterials(order) {
    document.getElementById("productionMaterialsTable").innerHTML = order && order.materials.length ? order.materials.map((row) => `
      <tr><td>${row.item || row[0]}</td><td>${row.quantity || row[1]}</td><td>${row.total || row[2]}</td></tr>
    `).join("") : "<tr><td colspan=\"3\">Sin materiales.</td></tr>";
  }

  function renderInventory(context) {
    document.getElementById("inventoryTable").innerHTML = context.inventoryItems.length ? context.inventoryItems.map((item) => {
      const [type, label] = stockStatus(item);
      return `
        <tr>
          <td>${item.code}</td>
          <td>${item.name}</td>
          <td>${item.category}</td>
          <td>${item.unit}</td>
          <td>${item.stock}</td>
          <td>${item.minStock}</td>
          <td><span class="alert ${type}">${label}</span></td>
          <td>
            <button class="tool" data-inventory-action="edit" data-item-id="${item.id}">Editar</button>
            <button class="tool" data-inventory-action="delete" data-item-id="${item.id}">Eliminar</button>
          </td>
        </tr>
      `;
    }).join("") : "<tr><td colspan=\"8\">Sin inventario.</td></tr>";

    document.getElementById("inventoryMovements").innerHTML = context.inventoryMovements.slice(0, 8).map((movement) => {
      const item = context.inventoryItems.find((candidate) => candidate.id === movement.itemId) || {};
      return `<div class="list-item"><strong>${movement.type} ${movement.quantity}</strong><span>${item.code || movement.itemId} - ${movement.reason} - ${movement.createdAt.slice(0, 10)}</span></div>`;
    }).join("") || "<div class=\"division-empty\">Sin movimientos.</div>";
  }

  function renderInstallations(context) {
    document.getElementById("installationList").innerHTML = context.installations.length ? context.installations.map((installation) => `
      <div class="list-item project-item ${installation.id === context.appState.selectedInstallationId ? "active-project" : ""}">
        <strong>${installation.installationNumber} - ${installation.projectSnapshot?.name || "Proyecto"}</strong>
        <span>${installationName(installation)} - ${installation.status} - ${installation.scheduledDate || "sin fecha"} ${installation.scheduledTime || ""}</span>
        <span>${installation.address || "sin direccion"}${installation.city ? `, ${installation.city}` : ""} - ${installation.assignedTeam || "sin equipo"}</span>
        <div class="project-actions">
          <button class="tool" data-installation-action="open" data-installation-id="${installation.id}">Abrir</button>
          <button class="tool" data-installation-action="delete" data-installation-id="${installation.id}">Eliminar</button>
        </div>
      </div>
    `).join("") : "<div class=\"division-empty\">No hay instalaciones programadas.</div>";
  }

  function renderInstallationDetail(installation) {
    const detail = document.getElementById("installationDetail");
    const checklist = document.getElementById("installationChecklist");
    const closeBtn = document.getElementById("closeProjectFromInstallationBtn");
    if (!installation) {
      detail.innerHTML = "<div class=\"division-empty\">Selecciona una instalacion.</div>";
      checklist.innerHTML = "";
      closeBtn.disabled = true;
      return;
    }

    detail.innerHTML = `
      <div class="metric"><span>Numero</span><strong>${installation.installationNumber}</strong></div>
      <div class="metric"><span>Proyecto</span><strong>${installation.projectSnapshot?.name || ""}</strong></div>
      <div class="metric"><span>Cliente</span><strong>${installationName(installation)}</strong></div>
      <div class="installation-form">
        ${renderInstallationStatusSelect(installation)}
        <label>Fecha
          <input type="date" value="${installation.scheduledDate || ""}" data-installation-action="scheduledDate" data-installation-id="${installation.id}" />
        </label>
        <label>Hora
          <input type="time" value="${installation.scheduledTime || ""}" data-installation-action="scheduledTime" data-installation-id="${installation.id}" />
        </label>
        <label>Equipo
          <input value="${installation.assignedTeam || ""}" data-installation-action="assignedTeam" data-installation-id="${installation.id}" />
        </label>
        <label>Direccion
          <input value="${installation.address || ""}" data-installation-action="address" data-installation-id="${installation.id}" />
        </label>
        <label>Ciudad
          <input value="${installation.city || ""}" data-installation-action="city" data-installation-id="${installation.id}" />
        </label>
        <label>Contacto
          <input value="${installation.contactName || ""}" data-installation-action="contactName" data-installation-id="${installation.id}" />
        </label>
        <label>Telefono
          <input value="${installation.contactPhone || ""}" data-installation-action="contactPhone" data-installation-id="${installation.id}" />
        </label>
        <label class="full">Notas
          <textarea data-installation-action="notes" data-installation-id="${installation.id}">${installation.notes || ""}</textarea>
        </label>
      </div>
      <div class="metric"><span>Historial</span><strong>${installation.history.length} eventos</strong></div>
    `;

    checklist.innerHTML = installation.checklist.map((item) => `
      <div class="check-item installation-check-item">
        <label>
          <input type="checkbox" ${item.checked ? "checked" : ""} data-checklist-action="checked" data-installation-id="${installation.id}" data-checklist-id="${item.id}" />
          ${item.label}
        </label>
        <input value="${item.notes || ""}" placeholder="Nota" data-checklist-action="notes" data-installation-id="${installation.id}" data-checklist-id="${item.id}" />
      </div>
    `).join("");
    closeBtn.disabled = installation.status !== "completada";
  }

  function render(context) {
    const order = selectedOrder(context);
    const installation = selectedInstallation(context);
    renderOrders(context);
    renderDetail(context, order);
    renderCutList(order);
    renderMaterials(order);
    renderInventory(context);
    renderInstallations(context);
    renderInstallationDetail(installation);
  }

  window.VentaProErpView = {
    render,
  };
})(window, document);
