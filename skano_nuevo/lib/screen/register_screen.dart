import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final inviteCodeCtrl = TextEditingController();

  bool loading = false;
  String errorMessage = "";
  bool showPassword = false;

  String? _validateEmail(String rawEmail) {
    final email = rawEmail.trim().toLowerCase();

    if (email.isEmpty) {
      return "Debes ingresar un correo electrónico.";
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return "Ingresa un correo electrónico válido.";
    }

    final domain = email.split("@").last;

    final commonMistakes = {
      "gamil.com": "gmail.com",
      "gmial.com": "gmail.com",
      "gmai.com": "gmail.com",
      "gmail.con": "gmail.com",
      "hotnail.com": "hotmail.com",
      "hotmai.com": "hotmail.com",
      "hotmail.con": "hotmail.com",
      "outlok.com": "outlook.com",
      "outllok.com": "outlook.com",
      "outlook.con": "outlook.com",
    };

    if (commonMistakes.containsKey(domain)) {
      final correctedEmail = email.replaceFirst(
        domain,
        commonMistakes[domain]!,
      );

      return "El correo parece mal escrito. ¿Quisiste decir $correctedEmail?";
    }

    return null;
  }

  Future<void> registerUser() async {
    final fullName = nameCtrl.text.trim();
    final email = emailCtrl.text.trim().toLowerCase();
    final password = passCtrl.text.trim();

    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      if (fullName.isEmpty) {
        setState(() {
          loading = false;
          errorMessage = "Debes ingresar tu nombre completo.";
        });
        return;
      }

      final emailError = _validateEmail(email);
      if (emailError != null) {
        setState(() {
          loading = false;
          errorMessage = emailError;
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          loading = false;
          errorMessage = "La contraseña debe tener al menos 6 caracteres.";
        });
        return;
      }

      final enteredInviteCode = inviteCodeCtrl.text.trim().toUpperCase();

      String invitedByUid = "";
      String invitedByCode = "";

      if (enteredInviteCode.isNotEmpty) {
        final inviterQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("referralCode", isEqualTo: enteredInviteCode)
            .limit(1)
            .get();

        if (inviterQuery.docs.isEmpty) {
          setState(() {
            loading = false;
            errorMessage = "El código de invitación no existe.";
          });
          return;
        }

        invitedByUid = inviterQuery.docs.first.id;
        invitedByCode = enteredInviteCode;
      }

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final referralCode = "SKANO-${uid.substring(0, 6).toUpperCase()}";

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "full_name": fullName,
        "email": email,
        "email_normalized": email,

        "membership": "free",
        "membership_plan": "free",
        "membership_active": false,

        "faceRegistered": false,
        "faceUrl": "",
        "faceVerificationLevel": 0,
        "lastFaceCheck": null,
        "livenessRequired": false,
        "livenessChallenge": "",
        "intentos_fallidos": 0,
        "blocked": false,
        "blocked_reason": "",
        "blocked_until": null,
        "blocked_by_admin": false,

        "verification_status": "draft",
        "documentStatus": "draft",
        "documentsCompleted": false,
        "reviewPending": false,

        "profile_pic": "",

        "idFrontUrl": "",
        "idBackUrl": "",
        "addressProofUrl": "",
        "nationalId": "",
        "phone": "",
        "account_number": "",
        "account_type": "",
        "bank_name": "",
        "bankDocumentUrl": "",
        "adminComment": "",

        "termsAccepted": false,
        "termsAcceptedAt": null,

        "xp_points": 0,
        "vehicles_count": 0,
        "reportes_enviados": 0,
        "reportes_acertados": 0,
        "rewards_balance": 0,
        "level": "bronce",

        "referralCode": referralCode,
        "invitedByUid": invitedByUid,
        "invitedByCode": invitedByCode,
        "referralStats": {
          "invitedUsers": 0,
          "downloads": 0,
          "validReports": 0,
          "goal": 5,
          "rewardEnabled": false,
          "cycleCompleted": false,
        },
        "cycleCount": 0,
        "lastRewardAt": null,

        "created_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection("email_index").doc(email).set({
        "uid": uid,
        "email": email,
        "source": "register_screen",
        "active": true,
        "marketing_email_sent": false,
        "createdAt": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (invitedByUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(invitedByUid)
            .update({
          "referralStats.invitedUsers": FieldValue.increment(1),
          "referralStats.downloads": FieldValue.increment(1),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/terms_accept');
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Error inesperado.";

      if (e.code == "email-already-in-use") {
        message = "Este correo ya está registrado.";
      } else if (e.code == "invalid-email") {
        message = "El correo ingresado no es válido.";
      } else if (e.code == "weak-password") {
        message = "La contraseña es demasiado débil.";
      }

      setState(() => errorMessage = message);
    } catch (e) {
      setState(() => errorMessage = "Error al registrar usuario: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Crear Cuenta",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Regístrate para comenzar a usar SKANO.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),

            const Text("Nombre completo",
                style: TextStyle(color: Colors.white70)),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Ej: Juan Pérez"),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            const Text("Correo electrónico",
                style: TextStyle(color: Colors.white70)),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("correo@ejemplo.com"),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 20),

            const Text("Contraseña",
                style: TextStyle(color: Colors.white70)),
            TextField(
              controller: passCtrl,
              obscureText: !showPassword,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("••••••••").copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      setState(() => showPassword = !showPassword),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Código de invitación (opcional)",
                style: TextStyle(color: Colors.white70)),
            TextField(
              controller: inviteCodeCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration("Ej: SKANO-ABC123"),
            ),

            const SizedBox(height: 30),

            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.redAccent),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Registrarme",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  "¿Ya tienes cuenta? Inicia sesión",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}