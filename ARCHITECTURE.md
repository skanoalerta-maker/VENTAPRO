# Arquitectura VENTAPRO MVP v1.0

## Principio general

VENTAPRO MVP usa JavaScript clásico con módulos por responsabilidad mediante IIFE y namespaces sobre `window`. La decisión mantiene compatibilidad con apertura directa de `index.html` sin servidor local.

## Entrada

```text
ventapro_mvp/index.html
ventapro_mvp/styles.css
ventapro_mvp/app.js
```

`app.js` orquesta inicialización, eventos, navegación, renderizado y sincronización de cálculo.

## Estructura

```text
ventapro_mvp/
  core/
  data/
  state/
  storage/
  ui/
  utils/
```

## Responsabilidades

### data

Contiene datos estáticos de catálogo, demo, empresa y datos técnicos.

### core

Contiene lógica pura:

- `calculator.js`: cálculo técnico.
- `validators.js`: validaciones técnicas.
- `cutList.js`: lista de corte y materiales.
- `quoteBuilder.js`: modelo de cotización.

No debe tocar el DOM.

### state

Contiene estado global y acciones:

- `store.js`: modelos base, normalización, paneles y divisiones.
- `actions.js`: operaciones sobre proyecto, CAD, clientes, cotización, producción, inventario e instalaciones.

### storage

Persistencia local:

- `localStorageService.js`
- `customerStorageService.js`
- `productionStorageService.js`
- `inventoryStorageService.js`
- `installationStorageService.js`

### ui

Renderizado por pantalla:

- Dashboard.
- Catálogo.
- Clientes.
- Medidas.
- CAD.
- Cotización.
- ERP operativo.
- IA / 3D conceptual.

### utils

Constantes y formateadores compartidos.

## Orden de carga crítico

Los scripts se cargan desde `index.html` en este orden:

1. Utils.
2. Data.
3. Storage.
4. Store.
5. Core.
6. Actions.
7. UI.
8. App.

`actions.js` depende de `quoteBuilder.js`, por eso `core/quoteBuilder.js` debe cargarse antes de `state/actions.js`.

## Persistencia

La persistencia usa claves `localStorage` con prefijo `ventapro.*`.

El historial undo/redo no se persiste entre recargas. El estado final del proyecto sí se guarda.

## Límite v1.0

No hay backend, autenticación, multiusuario, sincronización remota ni PDF real avanzado. Esta versión es una base local funcional.
