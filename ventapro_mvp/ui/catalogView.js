(function (window, document) {
  "use strict";

  function render(context) {
    const q = context.filter.trim().toLowerCase();
    const items = context.catalog.filter((item) => (
      [item.name, item.type, item.openings, item.desc].join(" ").toLowerCase().includes(q)
    ));

    document.getElementById("catalogGrid").innerHTML = items.map((item) => `
      <article class="catalog-card">
        <div class="catalog-visual"></div>
        <strong>${item.name}</strong>
        <p>${item.desc}</p>
        <div class="tag-row"><span class="tag">${item.type}</span><span class="tag">${item.openings}</span></div>
      </article>
    `).join("");
  }

  window.VentaProCatalogView = {
    render,
  };
})(window, document);
