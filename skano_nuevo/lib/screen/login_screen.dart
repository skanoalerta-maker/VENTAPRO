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
          "verification_status": "pending",
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
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                28,
                24,
                28,
                viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight -
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
                          height: 90,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Correo",
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!loading) login();
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Contraseña",
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, "/forgot_password");
                            },
                            child: const Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage.isNotEmpty)
                          Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    style: TextStyle(color: Colors.black),
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
}