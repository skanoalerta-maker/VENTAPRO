# VENTAPRO MVP v1.0

VENTAPRO MVP es una aplicación web local para diseño, cálculo, cotización y gestión operativa básica de ventanas y puertas. La versión v1.0 queda cerrada como base arquitectónica funcional, ejecutable directamente desde navegador sin servidor local.

## Ubicación del MVP

La aplicación principal está en:

```text
ventapro_mvp/
```

Archivo de entrada:

```text
ventapro_mvp/index.html
```

## Cómo abrir

Abrir directamente en el navegador:

```text
ventapro_mvp/index.html
```

No requiere instalación, backend, Firebase ni servidor para funcionar en esta fase.

## Módulos incluidos

- Dashboard comercial y operativo.
- Clientes y asociación cliente-proyecto.
- Proyectos con persistencia en `localStorage`.
- Editor CAD 2D con paneles reales, divisiones editables, zoom, pan, snap y undo/redo.
- Motor de cálculo y validaciones técnicas.
- Cotización profesional imprimible.
- Órdenes de fabricación.
- Inventario básico con movimientos y reserva de materiales.
- Agenda de instalaciones, checklist y cierre de proyecto.

## Persistencia local

VENTAPRO MVP guarda datos en `localStorage` del navegador:

- Proyecto actual.
- Lista de proyectos.
- Clientes.
- Órdenes de fabricación.
- Inventario.
- Movimientos de inventario.
- Instalaciones.
- Contadores de cotizaciones, órdenes e instalaciones.

## Verificación técnica v1.0

Comando ejecutado:

```text
node --check
```

Resultado: todos los archivos `.js` dentro de `ventapro_mvp/` pasan sintaxis.

También se validó el flujo completo:

```text
Cliente -> Proyecto -> CAD -> Cálculo -> Cotización -> Orden de fabricación -> Inventario -> Instalación -> Proyecto terminado
```

## Repositorio

Repositorio oficial:

```text
https://github.com/skanoalerta-maker/VENTAPRO
```

Rama principal:

```text
main
```
