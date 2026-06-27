# Changelog

## VENTAPRO_MVP_v1.0 - 2026-06-27

### Estado

Versión cerrada como base arquitectónica inicial.

### Incluido

- Arquitectura modular en `ventapro_mvp/`.
- Separación de datos, estado, cálculo, validaciones, renderizado, acciones y persistencia.
- Persistencia local con `localStorage`.
- Modelo de proyecto, cliente, paneles, cotización, producción, inventario e instalación.
- CAD con paneles reales, divisiones con posición en milímetros, selección, edición, zoom, pan, snap y undo/redo.
- Cotización profesional con numeración `VENTA-AAAA-NNNN`.
- Órdenes de fabricación con numeración `OP-AAAA-NNNN`.
- Inventario local con stock, movimientos y reserva de materiales.
- Instalaciones con numeración `INS-AAAA-NNNN`, checklist y cierre de proyecto.
- Dashboard alimentado por datos reales locales.

### Correcciones de cierre

- Se corrigió el orden de carga de scripts en `index.html` para cargar `quoteBuilder.js` antes de `actions.js`.
- Se corrigieron mensajes de historial en `actions.js` que usaban variables fuera de alcance.
- Se actualizó documentación raíz del proyecto.

### Verificación

- `node --check` en todos los `.js` del MVP: OK.
- Scripts declarados en `index.html`: 26, faltantes: 0.
- IDs usados por JavaScript contra `index.html`: faltantes: 0.
- Vistas y navegación: 8 vistas, 8 entradas de navegación, sin vistas huérfanas.
- Flujo completo simulado con `localStorage`: OK.

### Riesgos conocidos

- La versión usa `localStorage`, por lo que no hay multiusuario ni sincronización real.
- La exportación PDF usa impresión del navegador, no generación PDF avanzada.
- El repositorio contiene archivos heredados fuera de `ventapro_mvp/`; la app VENTAPRO v1.0 está delimitada en la carpeta del MVP.
