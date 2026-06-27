(function (window) {
  "use strict";

  window.VentaProDemoData = {
    projects: [
      ["Casa Lo Barnechea", "Dise\u00f1o CAD", "$1.284.900"],
      ["Edificio Centro", "Cotizaci\u00f3n enviada", "$8.640.000"],
      ["Local Comercial Norte", "Producci\u00f3n", "$3.210.400"],
      ["Remodelaci\u00f3n Vitacura", "Medici\u00f3n", "$940.000"],
    ],
    pipeline: [
      ["Prospecto", 12],
      ["Contacto realizado", 8],
      ["Visita t\u00e9cnica", 5],
      ["Cotizaci\u00f3n enviada", 4],
      ["Aprobada", 3],
      ["Producci\u00f3n", 7],
      ["Instalaci\u00f3n", 2],
    ],
    inventory: [
      ["Perfil marco AL-25", "42 barras", "OK"],
      ["Hoja corredera AL-25", "18 barras", "Reponer"],
      ["Vidrio 6 mm", "64 m2", "OK"],
      ["Ruedas corredera", "34 pares", "Cr\u00edtico"],
      ["Burlete EPDM", "220 m", "OK"],
    ],
    production: [
      ["OF-1032", "Casa Lo Barnechea", "Lista de corte lista"],
      ["OF-1033", "Edificio Centro", "Pendiente perfiles"],
      ["OF-1034", "Local Comercial Norte", "En armado"],
    ],
    installChecklist: [
      "Confirmar medidas en obra",
      "Fotograf\u00edas antes de instalaci\u00f3n",
      "Firma del cliente",
      "Acta de conformidad",
    ],
    roadmap: [
      "Fase 1: CAD, cotizaciones, PDF, proyectos y clientes.",
      "Fase 2: c\u00e1lculo avanzado, listas de corte, producci\u00f3n e inventario.",
      "Fase 3: ERP completo, agenda, instalaci\u00f3n y postventa.",
      "Fase 4: IA para reconocimiento de fotograf\u00edas y optimizaci\u00f3n.",
      "Fase 5: 3D, realidad aumentada, DXF/DWG, CNC y API p\u00fablica.",
    ],
  };
})(window);
