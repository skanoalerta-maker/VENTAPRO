import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  bool loading = false;

  static const Color neonBlue = Color(0xFF0A6CFF);

  Future<void> sendReset() async {
    final email = emailCtrl.text.trim();

    if (email.isEmpty) {
      _show("Ingresa tu correo", true);
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _show(
        "Te enviamos un correo para recuperar tu contraseña. Revisa también spam.",
        false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Error al enviar correo";

      switch (e.code) {
        case 'invalid-email':
          msg = "Correo no válido";
          break;
        case 'user-not-found':
          msg = "No existe una cuenta con ese correo";
          break;
        case 'too-many-requests':
          msg = "Demasiados intentos. Intenta más tarde";
          break;
      }

      _show(msg, true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Recuperar cuenta"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, color: neonBlue, size: 60),
            const SizedBox(height: 20),
            const Text(
              "¿Olvidaste tu contraseña?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Ingresa tu correo y te enviaremos un enlace para recuperarla.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Correo",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : sendReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: neonBlue,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "ENVIAR CORREO",
                      style: TextStyle(color: Colors.black),
                    ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Volver",
                style: TextStyle(color: Colors.white70),
              ),
            )
          ],
        ),
      ),
    );
  }
}