import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color bgTop = Color(0xFF07091F);
  static const Color bgBottom = Colors.black;
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color cardColor = Color(0xFF101827);

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  String errorMessage = "";
  bool showPassword = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => errorMessage = "Debes ingresar tu nombre completo.");
      return false;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => errorMessage = "Ingresa un correo electrónico válido.");
      return false;
    }

    if (pass.length < 6) {
      setState(() => errorMessage = "La contraseña debe tener al menos 6 caracteres.");
      return false;
    }

    return true;
  }

  Future<void> registerUser() async {
    FocusScope.of(context).unfocus();

    setState(() {
      errorMessage = "";
    });

    if (!_validateForm()) return;

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final uid = credential.user!.uid;
      final referralCode = "SKANO-${uid.substring(0, 6).toUpperCase()}";

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "full_name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),

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

        "verification_status": "draft",
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
        "invitedByUid": "",
        "invitedByCode": "",
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

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/terms_accept');
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = _firebaseMessage(e));
    } catch (e) {
      setState(() => errorMessage = "No se pudo crear la cuenta. Intenta nuevamente.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado en SKANO.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'network-request-failed':
        return 'No hay conexión. Revisa internet e intenta nuevamente.';
      default:
        return e.message ?? 'Error inesperado al crear la cuenta.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 370;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 6),

                _hero(),
                const SizedBox(height: 22),

                Container(
                  padding: EdgeInsets.all(small ? 14 : 18),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Datos de acceso",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Crea tu cuenta para comenzar el proceso de verificación.",
                        style: TextStyle(color: Colors.white60, height: 1.35),
                      ),
                      const SizedBox(height: 18),

                      _fieldLabel("Nombre completo"),
                      _input(
                        controller: nameCtrl,
                        hint: "Ej: Juan Pérez",
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel("Correo electrónico"),
                      _input(
                        controller: emailCtrl,
                        hint: "correo@ejemplo.com",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel("Contraseña"),
                      _input(
                        controller: passCtrl,
                        hint: "Mínimo 6 caracteres",
                        icon: Icons.lock_outline,
                        obscureText: !showPassword,
                        textInputAction: TextInputAction.done,
                        suffix: IconButton(
                          onPressed: () => setState(() => showPassword = !showPassword),
                          icon: Icon(
                            showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                        ),
                        onSubmitted: (_) {
                          if (!loading) registerUser();
                        },
                      ),

                      const SizedBox(height: 16),
                      _securityNote(),

                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _errorBox(errorMessage),
                      ],

                      const SizedBox(height: 20),
                      _primaryButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: loading ? null : () => Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        color: neonBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Detecta • Reporta • Protege",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final small = MediaQuery.of(context).size.width < 370;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: small ? 78 : 96,
          height: small ? 78 : 96,
          padding: EdgeInsets.all(small ? 10 : 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: neonBlue.withOpacity(0.10),
            border: Border.all(color: neonBlue.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: neonBlue.withOpacity(0.35),
                blurRadius: small ? 26 : 35,
                spreadRadius: small ? 1 : 2,
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/skano_logo.png",
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Crear cuenta SKANO",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 24 : 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Únete a la comunidad chilena que ayuda a detectar vehículos con encargo por robo.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: small ? 13 : 14.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      cursorColor: neonBlue,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.065),
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
          borderSide: const BorderSide(color: neonBlue, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
    );
  }

  Widget _securityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: neonBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonBlue.withOpacity(0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: neonBlue, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Luego deberás aceptar términos y completar tu verificación para usar todas las funciones.",
              style: TextStyle(color: Colors.white70, height: 1.3, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    final small = MediaQuery.of(context).size.width < 370;

    return SizedBox(
      width: double.infinity,
      height: small ? 52 : 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0A6CFF), Color(0xFF4A8DFF)],
                ),
          color: loading ? Colors.white12 : null,
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.38),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : registerUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.8,
                  ),
                )
              : const Text(
                  "CREAR CUENTA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}