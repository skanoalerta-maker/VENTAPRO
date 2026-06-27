(function (window, document) {
  "use strict";

  const openingLabels = {
    fijo: "Fijo",
    corredera: "Corredera",
    batiente: "Batiente",
    proyectante: "Proyect.",
    oscilobatiente: "Oscilo",
    puerta: "Puerta",
  };

  const glassLabels = {
    transparente: "Transp.",
    satinado: "Satin.",
    bronce: "Bronce",
    azul: "Azul",
    reflectivo: "Reflect.",
    termopanel: "Termo",
    monolitico: "Mono",
    laminado: "Lam.",
  };

  function setValue(id, value) {
    const element = document.getElementById(id);
    if (element) {
      element.value = value == null ? "" : String(value);
    }
  }

  function getSelectedPanel(context) {
    return context.project.panels.find((panel) => panel.id === context.project.selectedPanelId) ||
      context.project.panels[0] ||
      null;
  }

  function getSegments(total, divisions) {
    const points = [0].concat(divisions.map((division) => division.positionMm), [total]);
    return points.slice(0, -1).map((start, index) => ({
      index,
      start,
      end: points[index + 1],
      size: points[index + 1] - start,
      center: start + (points[index + 1] - start) / 2,
    }));
  }

  function panelFill(panel) {
    if (panel.glassType === "termopanel") {
      return "rgba(117,204,214,.22)";
    }
    if (panel.glassType === "satinado") {
      return "rgba(230,237,240,.55)";
    }
    if (panel.glassType === "bronce") {
      return "rgba(164,116,70,.22)";
    }
    if (panel.glassType === "azul") {
      return "rgba(63,140,205,.22)";
    }
    if (panel.glassType === "reflectivo") {
      return "rgba(170,192,198,.35)";
    }
    return "rgba(117,204,214,.12)";
  }

  function renderPanel(panel, context, originX, originY, ratio) {
    const selected = panel.id === context.project.selectedPanelId;
    const x = originX + panel.x * ratio;
    const y = originY + panel.y * ratio;
    const w = panel.width * ratio;
    const h = panel.height * ratio;
    const centerX = x + w / 2;
    const centerY = y + h / 2;

    return `
      <g class="cad-panel ${selected ? "selected" : ""}" data-panel-id="${panel.id}" tabindex="0" role="button" aria-label="Panel ${panel.row + 1}-${panel.col + 1}">
        <rect x="${x}" y="${y}" width="${w}" height="${h}" class="panel-glass" style="fill:${panelFill(panel)}" />
        <rect x="${x}" y="${y}" width="${w}" height="${h}" class="panel-frame" />
        <text x="${centerX}" y="${centerY - 14}" class="panel-label">${openingLabels[panel.openingType] || panel.openingType}</text>
        <text x="${centerX}" y="${centerY + 10}" class="panel-sub">${glassLabels[panel.glassType] || panel.glassType} ${panel.glassThickness}mm</text>
        <text x="${centerX}" y="${y + h - 14}" class="panel-dim">${panel.width} x ${panel.height} mm</text>
      </g>
    `;
  }

  function renderDivision(division, context, originX, originY, frameW, frameH, ratio) {
    const selected = division.id === context.project.selectedDivisionId &&
      division.orientation === context.project.selectedDivisionOrientation;
    const className = [
      "cad-division",
      division.orientation,
      selected ? "selected" : "",
      division.locked ? "locked" : "",
    ].join(" ");

    if (division.orientation === "vertical") {
      const x = originX + division.positionMm * ratio;
      return `
        <g class="${className}" data-division-id="${division.id}" data-division-orientation="vertical">
          <line x1="${x}" y1="${originY}" x2="${x}" y2="${originY + frameH}" />
          <rect x="${x - 9}" y="${originY}" width="18" height="${frameH}" class="division-hit" />
          <text x="${x + 10}" y="${originY + 22}" class="division-label">${division.label}</text>
        </g>
      `;
    }

    const y = originY + division.positionMm * ratio;
    return `
      <g class="${className}" data-division-id="${division.id}" data-division-orientation="horizontal">
        <line x1="${originX}" y1="${y}" x2="${originX + frameW}" y2="${y}" />
        <rect x="${originX}" y="${y - 9}" width="${frameW}" height="18" class="division-hit" />
        <text x="${originX + 12}" y="${y - 10}" class="division-label">${division.label}</text>
      </g>
    `;
  }

  function renderPartialMeasures(context, originX, originY, frameW, frameH, ratio) {
    const columns = getSegments(context.project.width, context.project.verticalDivisions);
    const rows = getSegments(context.project.height, context.project.horizontalDivisions);
    const columnTexts = columns.map((segment) => `
      <text x="${originX + segment.center * ratio}" y="${originY - 46}" class="measure-label">${Math.round(segment.size)} mm</text>
    `).join("");
    const rowTexts = rows.map((segment) => `
      <text x="${originX - 46}" y="${originY + segment.center * ratio}" class="measure-label vertical-measure">${Math.round(segment.size)} mm</text>
    `).join("");

    return `
      <text x="${originX + frameW / 2}" y="${originY - 24}" class="dim">${context.project.width} mm</text>
      <text x="${originX + frameW + 24}" y="${originY + frameH / 2}" class="dim" transform="rotate(90 ${originX + frameW + 24} ${originY + frameH / 2})">${context.project.height} mm</text>
      ${columnTexts}
      ${rowTexts}
    `;
  }

  function renderDragGuide(context, originX, originY, frameW, frameH, ratio) {
    const guide = context.appState.cadView.dragGuide;
    if (!guide) {
      return "";
    }

    if (guide.orientation === "vertical") {
      const x = originX + guide.positionMm * ratio;
      return `
        <g class="snap-guide">
          <line x1="${x}" y1="${originY - 28}" x2="${x}" y2="${originY + frameH + 28}" />
          <text x="${x + 12}" y="${originY + frameH + 24}">${guide.positionMm} mm · Izq ${guide.beforeMm} / Der ${guide.afterMm}</text>
        </g>
      `;
    }

    const y = originY + guide.positionMm * ratio;
    return `
      <g class="snap-guide">
        <line x1="${originX - 28}" y1="${y}" x2="${originX + frameW + 28}" y2="${y}" />
        <text x="${originX + frameW - 220}" y="${y - 12}">${guide.positionMm} mm · Sup ${guide.beforeMm} / Inf ${guide.afterMm}</text>
      </g>
    `;
  }

  function renderCad(context) {
    const state = context.state;
    const project = context.project;
    const svg = document.getElementById("cadSvg");
    const padding = 90;
    const x = 120;
    const y = 78;
    const maxW = 660;
    const maxH = 380;
    const ratio = Math.min(maxW / state.width, maxH / state.height);
    const cadView = context.appState.cadView;
    const zoom = cadView.zoom;
    const panX = cadView.panX;
    const panY = cadView.panY;
    const w = state.width * ratio;
    const h = state.height * ratio;
    const panels = project.panels.map((panel) => renderPanel(panel, context, x, y, ratio)).join("");
    const verticalDivisions = project.verticalDivisions.map((division) => renderDivision(division, context, x, y, w, h, ratio)).join("");
    const horizontalDivisions = project.horizontalDivisions.map((division) => renderDivision(division, context, x, y, w, h, ratio)).join("");

    svg.dataset.originX = String(x);
    svg.dataset.originY = String(y);
    svg.dataset.ratio = String(ratio);
    svg.dataset.zoom = String(zoom);
    svg.dataset.panX = String(panX);
    svg.dataset.panY = String(panY);
    svg.dataset.frameWidthMm = String(state.width);
    svg.dataset.frameHeightMm = String(state.height);

    svg.innerHTML = `
      <defs>
        <style>
          .panel-glass{stroke:rgba(15,124,134,.22);stroke-width:1}
          .panel-frame{fill:transparent;stroke:#0f7c86;stroke-width:5}
          .cad-panel{cursor:pointer;outline:none}
          .cad-panel.selected .panel-frame{stroke:#f2a541;stroke-width:9}
          .cad-division line{stroke:#183b56;stroke-width:5;stroke-dasharray:8 7}
          .cad-division.selected line{stroke:#f2a541;stroke-width:7;stroke-dasharray:none}
          .cad-division.locked line{stroke:#8b98a5;stroke-width:6;stroke-dasharray:3 5}
          .division-hit{fill:transparent;cursor:grab}
          .cad-division.locked .division-hit{cursor:not-allowed}
          .cad-workspace.pan-mode{cursor:grab}
          .division-label{font:700 13px Segoe UI, Arial;fill:currentColor}
          .panel-label{font:700 15px Segoe UI, Arial;text-anchor:middle;fill:currentColor}
          .panel-sub,.panel-dim{font:12px Segoe UI, Arial;text-anchor:middle;fill:currentColor;opacity:.75}
          .dim{font:18px Segoe UI, Arial;fill:currentColor;text-anchor:middle}
          .measure-label{font:12px Segoe UI, Arial;fill:currentColor;text-anchor:middle;opacity:.8}
          .vertical-measure{text-anchor:end}
          .snap-guide line{stroke:#f2a541;stroke-width:2;stroke-dasharray:5 5}
          .snap-guide text{font:700 13px Segoe UI, Arial;fill:#f2a541}
        </style>
      </defs>
      <rect x="0" y="0" width="900" height="560" fill="transparent" class="cad-background" />
      <g class="cad-workspace ${cadView.mode === "pan" ? "pan-mode" : ""}" transform="translate(${panX} ${panY}) scale(${zoom})">
        ${panels}
        ${verticalDivisions}
        ${horizontalDivisions}
        ${renderDragGuide(context, x, y, w, h, ratio)}
        <rect x="${x}" y="${y}" width="${w}" height="${h}" fill="none" stroke="#0f7c86" stroke-width="10" />
        ${renderPartialMeasures(context, x, y, w, h, ratio)}
        <text x="${padding}" y="520" class="dim">${project.panels.length} paneles - ${context.technicalData.systems[state.system].name}</text>
      </g>
    `;

    document.getElementById("rulerWidth").textContent = `${state.width} ${state.unit}`;
    document.getElementById("rulerHeight").textContent = `${state.height} ${state.unit}`;
    document.getElementById("cadStatus").textContent = `Zoom ${Math.round(zoom * 100)}% · ${cadView.mode === "pan" ? "Pan" : "Selección"} · ${cadView.saved ? "Guardado" : "Editando"}`;
  }

  function renderSelectedPanel(context) {
    const panel = getSelectedPanel(context);
    const info = document.getElementById("selectedPanelInfo");

    if (!panel) {
      info.textContent = "Sin panel seleccionado.";
      return;
    }

    info.innerHTML = `
      <strong>Panel F${panel.row + 1} C${panel.col + 1}</strong>
      <span>${panel.width} x ${panel.height} mm - x:${panel.x} y:${panel.y}</span>
    `;
    setValue("openingInput", panel.openingType);
    setValue("panelGlassInput", panel.glassType);
    setValue("panelThicknessInput", panel.glassThickness);
    setValue("colorInput", panel.frameColor);
    setValue("panelProfileInput", panel.profileSystem);
    setValue("panelNotesInput", panel.notes);
  }

  function renderDivisionList(context) {
    const warning = document.getElementById("cadWarning");
    const list = document.getElementById("divisionList");
    const divisions = context.project.verticalDivisions.concat(context.project.horizontalDivisions);

    warning.textContent = context.project.cadWarning || "";
    list.innerHTML = divisions.length ? divisions.map((division) => {
      const selected = division.id === context.project.selectedDivisionId &&
        division.orientation === context.project.selectedDivisionOrientation;
      return `
        <div class="division-item ${selected ? "selected" : ""} ${division.locked ? "locked" : ""}">
          <strong>${division.label} ${division.orientation === "vertical" ? "Vertical" : "Horizontal"}</strong>
          <input type="number" min="250" value="${division.positionMm}" data-division-action="position" data-division-id="${division.id}" data-division-orientation="${division.orientation}" />
          <button class="tool" data-division-action="select" data-division-id="${division.id}" data-division-orientation="${division.orientation}">Sel</button>
          <button class="tool" data-division-action="lock" data-division-id="${division.id}" data-division-orientation="${division.orientation}">${division.locked ? "Abrir" : "Bloq"}</button>
          <button class="tool" data-division-action="remove" data-division-id="${division.id}" data-division-orientation="${division.orientation}">Eliminar</button>
        </div>
      `;
    }).join("") : "<div class=\"division-empty\">Sin divisiones.</div>";
  }

  function renderMetrics(context) {
    const calc = context.calc;
    const formatters = context.formatters;
    document.getElementById("liveMetrics").innerHTML = [
      ["\u00c1rea de vidrio", `${calc.glassArea.toFixed(2)} m2`],
      ["Longitud perfiles", formatters.meters(calc.profileMm / 1000)],
      ["Barras comerciales", `${calc.bars} barras`],
      ["Paneles reales", `${calc.panelCount}`],
      ["Peso estimado", `${calc.weight.toFixed(1)} kg`],
      ["Costo estimado", formatters.money(calc.total)],
    ].map(([label, value]) => `<div class="metric"><span>${label}</span><strong>${value}</strong></div>`).join("");
  }

  function render(context) {
    renderCad(context);
    renderSelectedPanel(context);
    renderDivisionList(context);
    renderMetrics(context);
  }

  window.VentaProCadView = {
    render,
  };
})(window, document);
