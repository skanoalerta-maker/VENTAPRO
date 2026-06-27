import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool sending = false;
  bool checking = false;
  String message = '';

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _sendVerificationIfNeeded();
  }

  // ------------------------------------------------------------
  // 📧 ENVÍO AUTOMÁTICO DE CORREO
  // ------------------------------------------------------------
  Future<void> _sendVerificationIfNeeded() async {
    if (user != null && !user!.emailVerified) {
      try {
        await user!.sendEmailVerification();
        setState(() {
          message =
              "📧 Te enviamos un correo de verificación. Revisa tu bandeja de entrada o spam.";
        });
      } catch (_) {
        setState(() {
          message =
              "⚠️ No se pudo enviar el correo de verificación. Intenta nuevamente.";
        });
      }
    }
  }

  // ------------------------------------------------------------
  // 🔁 REENVIAR CORREO
  // ------------------------------------------------------------
  Future<void> _resendEmail() async {
    setState(() => sending = true);
    try {
      await user!.sendEmailVerification();
      setState(() {
        message = "📨 Correo de verificación reenviado correctamente.";
      });
    } catch (_) {
      setState(() {
        message = "❌ Error al reenviar el correo. Intenta más tarde.";
      });
    } finally {
      setState(() => sending = false);
    }
  }

  // ------------------------------------------------------------
  // ✅ VERIFICAR Y VOLVER AL START GATE
  // ------------------------------------------------------------
  Future<void> _checkVerification() async {
    setState(() => checking = true);

    await user!.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      if (!mounted) return;

      // 🔐 REGRA DE ORO:
      // DESPUÉS DE VERIFICAR EMAIL NUNCA IR A HOME
      // SIEMPRE VOLVER A START GATE
      Navigator.pushReplacementNamed(context, '/start_gate');
      return;
    }

    setState(() {
      message =
          "⏳ Aún no hemos detectado la verificación. Revisa tu correo y vuelve a intentar.";
    });

    setState(() => checking = false);
  }

  // ------------------------------------------------------------
  // 🚪 CERRAR SESIÓN
  // ------------------------------------------------------------
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread,
                  size: 80, color: Color(0xFF0A6CFF)),
              const SizedBox(height: 24),

              const Text(
                "Verifica tu correo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                "Para continuar usando SKANO debes confirmar tu correo electrónico.",
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                user?.email ?? '',
                style: const TextStyle(
                    color: Color(0xFF0A6CFF), fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: sending ? null : _resendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6CFF),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Reenviar correo"),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: checking ? null : _checkVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: checking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Ya verifiqué, continuar"),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: _logout,
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
