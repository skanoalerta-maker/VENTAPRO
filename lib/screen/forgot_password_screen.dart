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
  String message = '';
  String errorMessage = '';

  static const Color neonBlue = Color(0xFF0A6CFF);

  Future<void> resetPassword() async {
    final email = emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Ingresa tu correo electrónico.';
        message = '';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
      message = '';
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        message =
            'Te enviamos un enlace para restablecer tu contraseña. Revisa tu correo y también la carpeta de spam.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _translateFirebaseError(e.code);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ocurrió un error inesperado. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _translateFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta registrada con ese correo.';
      case 'missing-email':
        return 'Debes ingresar un correo electrónico.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente más tarde.';
      default:
        return 'No se pudo enviar el correo de recuperación.';
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset,
                  color: neonBlue,
                  size: 70,
                ),
                const SizedBox(height: 20),
                const Text(
                  '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.email, color: neonBlue),
                    filled: true,
                    fillColor: const Color(0xFF1A1D24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enviar enlace',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}