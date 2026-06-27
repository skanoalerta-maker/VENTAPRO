import 'package:flutter/material.dart';

class SpeedBlockScreen extends StatefulWidget {
  final double currentSpeedKmh;
  final double limitKmh;

  const SpeedBlockScreen({
    super.key,
    required this.currentSpeedKmh,
    this.limitKmh = 15,
  });

  @override
  State<SpeedBlockScreen> createState() => _SpeedBlockScreenState();
}

class _SpeedBlockScreenState extends State<SpeedBlockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.92,
      upperBound: 1.06,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const Color bg = Color(0xFF05070D);
  static const Color red = Color(0xFFFF2D2D);
  static const Color darkRed = Color(0xFF3A0606);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 46, 22, 22),
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF3A0606),
              Color(0xFF111827),
              Color(0xFF05070D),
            ],
          ),
        ),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: red.withOpacity(0.14),
                  border: Border.all(color: red, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: red.withOpacity(0.55),
                      blurRadius: 42,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  color: red,
                  size: 82,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "VEHÍCULO EN MOVIMIENTO",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: red,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "LECTURA DE PATENTE BLOQUEADA",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: red.withOpacity(0.85), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: red.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "SKANO NO ACEPTA REPORTES NI LECTURA DE PATENTES EN MOVIMIENTO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "VELOCIDAD DETECTADA",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${widget.currentSpeedKmh.toStringAsFixed(0)} KM/H",
                    style: const TextStyle(
                      color: red,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    "Límite permitido: ${widget.limitKmh.toStringAsFixed(0)} KM/H",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkRed.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: red.withOpacity(0.45)),
              ),
              child: const Text(
                "Detén el vehículo o realiza la verificación caminando.\n\nSKANO no promueve persecuciones, seguimientos ni confrontaciones.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "ENTENDIDO",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  elevation: 16,
                  shadowColor: red.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}