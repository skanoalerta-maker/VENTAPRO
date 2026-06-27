import 'package:flutter/material.dart';

/// Archivo de constantes globales para colores, tamaños y estilos.
/// Esto permite mantener un diseño consistente en toda la app SKANO.
class AppConstants {
  // ============================
  // 🎨 PALETA DE COLORES SKANO
  // ============================

  /// Azul neón principal (brand)
  static const Color neonBlue = Color(0xFF0A6CFF);

  /// Azul neón suave (bordes y brillos)
  static const Color neonBlueSoft = Color(0xFF4D9BFF);

  /// Fondo principal oscuro
  static const Color background = Color(0xFF0D0D0D);

  /// Superficie de tarjetas
  static const Color surface = Color(0xFF1A1A1A);

  /// Superficie alternativa (inputs, overlays)
  static const Color surfaceAlt = Color(0xFF121212);

  /// Texto blanco principal
  static const Color textPrimary = Colors.white;

  /// Texto gris suave
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Verde para estados de éxito
  static const Color success = Color(0xFF1DB954);

  /// Rojo para alertas
  static const Color danger = Color(0xFFFF4444);

  /// Amarillo para advertencias
  static const Color warning = Color(0xFFFFC107);


  // ============================
  // 🔤 TIPOGRAFÍA
  // ============================

  static const double titleXL = 26;
  static const double titleL = 22;
  static const double titleM = 18;
  static const double bodyL = 16;
  static const double bodyM = 14;
  static const double bodyS = 12;


  // ============================
  // 📦 ESPACIADOS
  // ============================

  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;


  // ============================
  // ⭕ BORDES
  // ============================

  static BorderRadius radiusM = BorderRadius.circular(12);
  static BorderRadius radiusL = BorderRadius.circular(18);


  // ============================
  // ⚡ SOMBRAS NEÓN
  // ============================

  static List<BoxShadow> neonShadow = [
    BoxShadow(
      color: neonBlue.withOpacity(0.5),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];
}
