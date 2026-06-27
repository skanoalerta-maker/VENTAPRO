import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bgTop = Color(0xFF071225);
  static const Color bgBottom = Color(0xFF02040A);
  static const Color cardColor = Color(0xFF0B1220);

  bool sending = false;
  bool checking = false;
  String message = '';
  bool messageIsError = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sendVerificationIfNeeded();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationIfNeeded() async {
    if (user != null && !user!.emailVerified) {
      try {
        await user!.sendEmailVerification();
        if (!mounted) return;
        setState(() {
          message =
              "Te enviamos un correo de verificación. Revisa tu bandeja de entrada o spam.";
          messageIsError = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          message =
              "No se pudo enviar el correo de verificación. Intenta nuevamente.";
          messageIsError = true;
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    if (sending) return;

    setState(() => sending = true);

    try {
      await user!.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        message = "Correo de verificación reenviado correctamente.";
        messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = "Error al reenviar el correo. Intenta más tarde.";
        messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _checkVerification() async {
    if (checking) return;

    setState(() => checking = true);

    try {
      await user!.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/start_gate');
        return;
      }

      if (!mounted) return;
      setState(() {
        message =
            "Aún no hemos detectado la verificación. Revisa tu correo y vuelve a intentar.";
        messageIsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = "No se pudo comprobar la verificación. Intenta nuevamente.";
        messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -90,
                right: -80,
                child: _GlowCircle(size: 220, opacity: 0.25),
              ),
              const Positioned(
                bottom: 120,
                left: -120,
                child: _GlowCircle(size: 260, opacity: 0.12),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 18, 22, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: "Cerrar sesión",
                      ),
                    ),
                    const SizedBox(height: 8),

                    _mainCard(email),

                    const SizedBox(height: 18),

                    if (message.isNotEmpty) _messageBox(message),

                    const SizedBox(height: 18),

                    _stepsCard(),

                    const SizedBox(height: 22),

                    _primaryButton(
                      label: "REENVIAR CORREO",
                      icon: Icons.mark_email_read_outlined,
                      loading: sending,
                      onPressed: sending ? null : _resendEmail,
                    ),

                    const SizedBox(height: 12),

                    _successButton(
                      label: "YA VERIFIQUÉ, CONTINUAR",
                      icon: Icons.verified_user_outlined,
                      loading: checking,
                      onPressed: checking ? null : _checkVerification,
                    ),

                    const SizedBox(height: 18),

                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      label: const Text(
                        "Cerrar sesión",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "SKANO • Detecta • Reporta • Protege",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainCard(String email) {
    final small = MediaQuery.of(context).size.width < 370;

    return Container(
      padding: EdgeInsets.all(small ? 16 : 22),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.10),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: small ? 90 : 112,
              height: small ? 90 : 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A6CFF), Color(0xFF54A3FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.48),
                    blurRadius: 34,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: small ? 44 : 54,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Verifica tu correo",
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 24 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Para continuar usando SKANO debes confirmar tu correo electrónico.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: small ? 13.5 : 15.5,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: neonBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: neonBlue.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alternate_email, color: neonBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    email.isNotEmpty ? email : "Correo no disponible",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: small ? 13 : 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox(String text) {
    final color = messageIsError ? Colors.redAccent : neonBlue;
    final icon =
        messageIsError ? Icons.error_outline : Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "¿Qué debes hacer?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _StepItem(
            number: "1",
            text: "Abre el correo que enviamos desde Firebase/SKANO.",
          ),
          _StepItem(
            number: "2",
            text: "Presiona el enlace de verificación.",
          ),
          _StepItem(
            number: "3",
            text: "Vuelve a la app y toca “Ya verifiqué, continuar”.",
          ),
          SizedBox(height: 4),
          Text(
            "Si no aparece, revisa spam, promociones o correo no deseado.",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    final small = MediaQuery.of(context).size.width < 370;

    return SizedBox(
      width: double.infinity,
      height: small ? 52 : 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A6CFF), Color(0xFF4A8DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: neonBlue.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: loading
              ? const SizedBox.shrink()
              : Icon(icon, color: Colors.white, size: small ? 18 : 20),
          label: loading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: small ? 13.8 : 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    final small = MediaQuery.of(context).size.width < 370;

    return SizedBox(
      width: double.infinity,
      height: small ? 52 : 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox.shrink()
            : Icon(
                icon,
                color: const Color(0xFF4ADE80),
                size: small ? 18 : 20,
              ),
        label: loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  color: Color(0xFF4ADE80),
                  strokeWidth: 3,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF4ADE80),
                  fontSize: small ? 13.8 : 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF4ADE80).withOpacity(0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: const Color(0xFF4ADE80).withOpacity(0.08),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A6CFF).withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A6CFF).withOpacity(opacity),
            blurRadius: 90,
            spreadRadius: 35,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0A6CFF).withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0A6CFF).withOpacity(0.45),
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF7DB7FF),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.8,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}