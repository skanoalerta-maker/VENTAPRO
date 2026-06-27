import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController fadeController;

  late Animation<double> logoScale;
  late Animation<double> fadeIn;

  @override
  void initState() {
    super.initState();

    // LOGO PULSANTE
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    logoScale = Tween<double>(begin: 0.90, end: 1.08).animate(
      CurvedAnimation(parent: logoController, curve: Curves.easeInOut),
    );

    // FADE–IN DEL CONTENIDO
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    fadeIn = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );

    fadeController.forward();
  }

  @override
  void dispose() {
    logoController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: fadeIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ⭐ LOGO ANIMADO CON PULSO
                ScaleTransition(
                  scale: logoScale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.55),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/skano_logo.png",
                      width: 185,
                      height: 185,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ⭐ TITULO SKANO
                const Text(
                  "SKANO",
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.blueAccent,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ⭐ FRASE PREMIUM
                const Text(
                  "Encuentra tu vehículo robado\ncon la ayuda de la comunidad",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 50),

                // ⭐ BOTÓN CREAR CUENTA
                _neonButton(
                  label: "Crear Cuenta",
                  background: neonBlue,
                  textColor: Colors.white,
                  onTap: () => Navigator.pushNamed(context, '/register'),
                ),

                const SizedBox(height: 18),

                // ⭐ BOTÓN INICIAR SESIÓN
                _outlinedNeonButton(
                  label: "Iniciar Sesión",
                  borderColor: neonBlue,
                  textColor: neonBlue,
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),

                const SizedBox(height: 20),

                // ❌ ELIMINAMOS EL BOTÓN QUE MANDABA A /revision
                // (no corresponde a recuperación de cuenta)

              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  //  BOTÓN NEÓN
  // ------------------------------------------------------
  Widget _neonButton({
    required String label,
    required VoidCallback onTap,
    required Color background,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: background.withOpacity(0.55),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------
  //  BOTÓN NEÓN BORDEADO
  // ------------------------------------------------------
  Widget _outlinedNeonButton({
    required String label,
    required VoidCallback onTap,
    required Color borderColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
