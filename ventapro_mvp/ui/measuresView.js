(function (window, document) {
  "use strict";

  function render(context) {
    document.getElementById("validationBox").innerHTML = context.validations.map((check) => (
      `<div class="validation ${check.type}">${check.text}</div>`
    )).join("");
  }

  window.VentaProMeasuresView = {
    render,
  };
})(window, document);
