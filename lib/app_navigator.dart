// ============================================================================
// 📄 Archivo: app_navigator.dart
// 🧭 Navegación centralizada SKANO (COMPATIBLE)
// ✅ Permite llamadas:
//    - skanoPushReplacementNamed(context, "/ruta", arguments: {...})
//    - skanoPushReplacementNamed("/ruta", arguments: {...})
// ✅ Normaliza rutas (trim + quita slash final + asegura slash inicial)
// ✅ navigatorKey global para MaterialApp
// ============================================================================

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> skanoNavigatorKey = GlobalKey<NavigatorState>();

String _normalizeRoute(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '/home';

  // Asegurar slash inicial
  if (!s.startsWith('/')) s = '/$s';

  // Quitar slashes finales repetidos
  while (s.length > 1 && s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }

  // Eliminar espacios internos (por si viene " /ruta / ")
  s = s.replaceAll(RegExp(r'\s+'), '');

  return s;
}

NavigatorState? _navFrom(dynamic contextOrNull) {
  // Si viene BuildContext, priorizamos Navigator.of(context)
  if (contextOrNull is BuildContext) {
    return Navigator.of(contextOrNull);
  }
  // Si no, usamos navigatorKey global
  return skanoNavigatorKey.currentState;
}

// ---------------------------------------------------------------------------
// PUSH
// ---------------------------------------------------------------------------
Future<void> skanoPushNamed(
  dynamic contextOrRoute,
  String? maybeRoute, {
  Object? arguments,
}) async {
  // Soporta: skanoPushNamed(context, "/ruta")  OR  skanoPushNamed("/ruta")
  final bool calledWithContext = contextOrRoute is BuildContext;
  final String routeName =
      calledWithContext ? (maybeRoute ?? '') : (contextOrRoute?.toString() ?? '');

  final nav = _navFrom(calledWithContext ? contextOrRoute : null);
  if (nav == null) return;

  final r = _normalizeRoute(routeName);
  await nav.pushNamed(r, arguments: arguments);
}

// ---------------------------------------------------------------------------
// REPLACEMENT
// ---------------------------------------------------------------------------
Future<void> skanoPushReplacementNamed(
  dynamic contextOrRoute,
  String? maybeRoute, {
  Object? arguments,
}) async {
  // Soporta: skanoPushReplacementNamed(context, "/ruta") OR skanoPushReplacementNamed("/ruta")
  final bool calledWithContext = contextOrRoute is BuildContext;
  final String routeName =
      calledWithContext ? (maybeRoute ?? '') : (contextOrRoute?.toString() ?? '');

  final nav = _navFrom(calledWithContext ? contextOrRoute : null);
  if (nav == null) return;

  final r = _normalizeRoute(routeName);
  await nav.pushReplacementNamed(r, arguments: arguments);
}

// ---------------------------------------------------------------------------
// REMOVE UNTIL (limpia stack completo)
// ---------------------------------------------------------------------------
Future<void> skanoPushNamedAndRemoveUntil(
  dynamic contextOrRoute,
  String? maybeRoute, {
  Object? arguments,
}) async {
  // Soporta: skanoPushNamedAndRemoveUntil(context, "/ruta") OR skanoPushNamedAndRemoveUntil("/ruta")
  final bool calledWithContext = contextOrRoute is BuildContext;
  final String routeName =
      calledWithContext ? (maybeRoute ?? '') : (contextOrRoute?.toString() ?? '');

  final nav = _navFrom(calledWithContext ? contextOrRoute : null);
  if (nav == null) return;

  final r = _normalizeRoute(routeName);
  await nav.pushNamedAndRemoveUntil(r, (route) => false, arguments: arguments);
}

// ---------------------------------------------------------------------------
// POP / MAYBEPOP
// ---------------------------------------------------------------------------
Future<bool> skanoMaybePop([BuildContext? context]) async {
  final nav = _navFrom(context);
  if (nav == null) return false;
  return nav.maybePop();
}

void skanoPop([BuildContext? context, Object? result]) {
  final nav = _navFrom(context);
  if (nav == null) return;
  nav.pop(result);
}

// ---------------------------------------------------------------------------
// PUSH ROUTE (MaterialPageRoute / PageRoute)
// ---------------------------------------------------------------------------
Future<void> skanoPushRoute(
  dynamic contextOrNull,
  Route route,
) async {
  final nav = _navFrom(contextOrNull);
  if (nav == null) return;
  await nav.push(route);
}

// ---------------------------------------------------------------------------
// REPLACEMENT ROUTE (MaterialPageRoute / PageRoute)
// ---------------------------------------------------------------------------
Future<void> skanoPushReplacementRoute(
  dynamic contextOrNull,
  Route route,
) async {
  final nav = _navFrom(contextOrNull);
  if (nav == null) return;
  await nav.pushReplacement(route);
}
