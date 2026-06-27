import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_blocked_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String errorMessage = "";
  bool showPassword = false;

  static const Color neonBlue = Color(0xFF0A6CFF);

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final uid = cred.user!.uid;
      final usersRef = FirebaseFirestore.instance.collection("users").doc(uid);

      final snap = await usersRef.get();

      if (!snap.exists) {
        await usersRef.set({
          "email": cred.user?.email ?? "",
          "created_at": FieldValue.serverTimestamp(),
          "blocked": false,
          "termsAccepted": false,
          "membership_active": false,
          "faceRegistered": false,
        });
      }

      final data = (await usersRef.get()).data()!;

      if (data["blocked"] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AccountBlockedScreen(
              reason: data["blocked_reason"] ?? "Bloqueo de seguridad",
              blockedUntil: data["blocked_until"] != null
                  ? (data["blocked_until"] as Timestamp).toDate()
                  : null,
              adminComment: data["adminComment"] ?? "",
            ),
          ),
        );
        return;
      }

      if (data["termsAccepted"] != true) {
        Navigator.pushReplacementNamed(context, "/terms_accept");
        return;
      }

      Navigator.pushReplacementNamed(context, "/start_gate");
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = "El correo no es válido";
            break;
          case 'user-not-found':
            errorMessage = "No existe una cuenta con ese correo";
            break;
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = "Correo o contraseña incorrectos";
            break;
          case 'too-many-requests':
            errorMessage = "Demasiados intentos. Inténtalo más tarde";
            break;
          case 'network-request-failed':
            errorMessage = "Sin conexión a internet";
            break;
          default:
            errorMessage = e.message ?? "Error al iniciar sesión";
        }
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    final small = screenSize.width < 370;
    final short = screenSize.height < 680;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                small ? 22 : 28,
                small ? 18 : 24,
                small ? 22 : 28,
                viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize.height -
                      safePadding.top -
                      safePadding.bottom -
                      48,
                ),
                child: Center(
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/skano_logo.png',
                          height: small ? 72 : short ? 78 : 90,
                        ),
                        SizedBox(height: small ? 16 : 20),
                        Text(
                          "Iniciar sesión",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: small ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: small ? 20 : 24),

                        _input(
                          controller: emailCtrl,
                          label: "Correo",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        SizedBox(height: small ? 14 : 16),

                        _input(
                          controller: passCtrl,
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          obscureText: !showPassword,
                          textInputAction: TextInputAction.done,
                          suffix: IconButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white60,
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!loading) login();
                          },
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      "/forgot_password",
                                    );
                                  },
                            child: Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: small ? 12.5 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: small ? 12 : 16),

                        if (errorMessage.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: errorMessage.isNotEmpty ? 18 : 24),

                        SizedBox(
                          width: double.infinity,
                          height: small ? 52 : 56,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonBlue,
                              disabledBackgroundColor: Colors.white12,
                              padding: EdgeInsets.symmetric(
                                vertical: small ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    "ENTRAR",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    final small = MediaQuery.of(context).size.width < 370;

    return TextField(
      controller: controller,
      enabled: !loading,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      cursorColor: neonBlue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.055),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: small ? 14 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonBlue, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );
  }
}