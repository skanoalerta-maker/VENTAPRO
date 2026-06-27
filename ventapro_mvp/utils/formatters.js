(function (window) {
  "use strict";

  function money(value) {
    return new Intl.NumberFormat("es-CL", {
      style: "currency",
      currency: "CLP",
      maximumFractionDigits: 0,
    }).format(value);
  }

  function meters(value) {
    return `${Number(value).toFixed(2)} m`;
  }

  function millimeters(value) {
    return `${Math.round(Number(value))} mm`;
  }

  function percent(value) {
    return `${Math.round(Number(value) * 100)}%`;
  }

  function number(value, digits) {
    return Number(value).toFixed(digits);
  }

  window.VentaProFormatters = {
    money,
    meters,
    millimeters,
    percent,
    number,
  };
})(window);
