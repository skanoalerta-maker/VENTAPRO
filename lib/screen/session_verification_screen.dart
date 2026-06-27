import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// ✅ Navegación centralizada
import '../app_navigator.dart';

class SessionVerificationScreen extends StatefulWidget {
  const SessionVerificationScreen({super.key});

  @override
  State<SessionVerificationScreen> createState() =>
      _SessionVerificationScreenState();
}

class _SessionVerificationScreenState extends State<SessionVerificationScreen> {
  String pin = "";
  bool loading = false;
  String? error;

  static const Duration sessionDuration = Duration(minutes: 20);

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color deepBlue = Color(0xFF052B6F);
  static const Color darkBg = Color(0xFF02040A);
  static const Color cardBg = Color(0xFF090D16);
  static const Color borderSoft = Color(0xFF1D2A3D);

  // ================= HASH PIN =================
  String _hashPin(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  // ================= SANITIZE ROUTE =================
  String _sanitizeRoute(dynamic v) {
    var s = (v ?? '').toString();

    s = s.replaceAll(
      RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060]'),
      '',
    );

    s = s.trim();
    if (s.isEmpty) return '/home';

    if (!s.startsWith('/')) s = '/$s';

    while (s.length > 1 && s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }

    while (s.contains('//')) {
      s = s.replaceAll('//', '/');
    }

    return s;
  }

  // ================= VERIFICAR PIN =================
  Future<void> _verifyPin() async {
    if (pin.length != 6) {
      setState(() => error = "Ingresa tu PIN de 6 dígitos");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => error = "Sesión inválida. Vuelve a iniciar.");
        return;
      }

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await ref.get();
      final data = snap.data() ?? {};

      final bool blockedByAdmin = data['blocked_by_admin'] == true;
      final Timestamp? blockedUntil = data['blocked_until'];

      final bool isTemporarilyBlocked =
          blockedUntil != null && blockedUntil.toDate().isAfter(DateTime.now());

      if (blockedByAdmin || isTemporarilyBlocked) {
        if (!mounted) return;
        await skanoPushReplacementNamed(context, '/account_blocked');
        return;
      }

      final bool isAdmin = data['role'] == 'admin';
      final String verificationStatus =
          (data['verification_status'] ?? 'draft').toString();

      final bool isVerified =
          verificationStatus == 'approved' || verificationStatus == 'active';

      if (!isAdmin && !isVerified) {
        setState(() {
          error =
              "Tu identidad aún no ha sido validada. Tu cuenta está en revisión.";
        });
        return;
      }

      final storedHash = data['report_pin_hash'];
      final inputHash = _hashPin(pin);

      // ✅ FIX REAL (evita crash null/int)
      final attempts = data['pin_attempts'] is int
          ? data['pin_attempts'] as int
          : int.tryParse('${data['pin_attempts']}') ?? 0;

      if (storedHash == null || storedHash != inputHash) {
        final newAttempts = attempts + 1;

        if (newAttempts >= 3) {
          await ref.set({
            "blocked": true,
            "blocked_reason": "pin_failed_3_times",
            "blocked_until": Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 30)),
            ),
            "pin_attempts": 0,
          }, SetOptions(merge: true));

          if (!mounted) return;
          await skanoPushReplacementNamed(context, '/account_blocked');
          return;
        }

        await ref.set({
          "pin_attempts": newAttempts,
        }, SetOptions(merge: true));

        setState(() {
          error = "PIN incorrecto ($newAttempts de 3 intentos)";
        });
        return;
      }

      // ✅ PIN correcto
      await ref.set({
        "pin_attempts": 0,
        "session_verified_until": Timestamp.fromDate(
          DateTime.now().add(sessionDuration),
        ),
        "last_activity": Timestamp.now(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      final rawArgs =
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
              {};

      final nextRoute = _sanitizeRoute(rawArgs['nextRoute']);

      debugPrint(
          'NEXT_ROUTE raw="${rawArgs['nextRoute']}" units=${(rawArgs['nextRoute'] ?? '').toString().codeUnits}');
      debugPrint(
          'NEXT_ROUTE sanitized="$nextRoute" units=${nextRoute.codeUnits}');

      final forwardArgs = Map<String, dynamic>.from(rawArgs);
      forwardArgs.remove('nextRoute');

      await skanoPushReplacementNamed(
        context,
        nextRoute,
        arguments: forwardArgs.isEmpty ? null : forwardArgs,
      );
    } catch (e) {
      // ✅ FIX UX (mensaje limpio en español)
      debugPrint("ERROR PIN: $e");

      if (mounted) {
        setState(() {
          error = "No se pudo verificar el PIN. Intenta nuevamente.";
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _securityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: neonBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: neonBlue.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: neonBlue,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            "Sesión protegida • Expira en 20 min",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockHero() {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            neonBlue.withOpacity(0.28),
            neonBlue.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.34),
            blurRadius: 42,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF061127).withOpacity(0.78),
            border: Border.all(
              color: neonBlue.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 58,
            color: neonBlue,
          ),
        ),
      ),
    );
  }

  InputDecoration _pinDecoration() {
    return InputDecoration(
      counterText: "",
      hintText: "PIN de 6 dígitos",
      hintStyle: const TextStyle(
        color: Colors.white38,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        Icons.password_rounded,
        color: neonBlue.withOpacity(0.85),
      ),
      filled: true,
      fillColor: const Color(0xFF070B13),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.22),
          width: 1.15,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: neonBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: darkBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          "Verificación de sesión",
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.78),
                    radius: 1.08,
                    colors: [
                      deepBlue.withOpacity(0.24),
                      darkBg,
                      Colors.black,
                    ],
                    stops: const [0.0, 0.56, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: -60,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonBlue.withOpacity(0.08),
                  boxShadow: [
                    BoxShadow(
                      color: neonBlue.withOpacity(0.10),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -70,
              bottom: 80,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonBlue.withOpacity(0.06),
                  boxShadow: [
                    BoxShadow(
                      color: neonBlue.withOpacity(0.09),
                      blurRadius: 90,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    18,
                    22,
                    22 + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _lockHero(),
                          const SizedBox(height: 24),
                          const Text(
                            "Ingresa tu PIN",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Por seguridad, confirma tu identidad\nantes de continuar con acciones críticas.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _securityBadge(),
                          const SizedBox(height: 28),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: cardBg.withOpacity(0.72),
                              border: Border.all(
                                color: borderSoft.withOpacity(0.70),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: neonBlue.withOpacity(0.07),
                                  blurRadius: 28,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              obscureText: true,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.5,
                              ),
                              decoration: _pinDecoration(),
                              onChanged: (v) {
                                pin = v.trim();
                                if (error != null && mounted) {
                                  setState(() => error = null);
                                }
                              },
                              onSubmitted: (_) {
                                if (!loading) _verifyPin();
                              },
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: error == null
                                ? const SizedBox(height: 44)
                                : Padding(
                                    key: const ValueKey('pin-error'),
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              Colors.redAccent.withOpacity(0.35),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              error!,
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: neonBlue.withOpacity(0.38),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: neonBlue,
                                  disabledBackgroundColor:
                                      neonBlue.withOpacity(0.50),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: loading ? null : _verifyPin,
                                child: loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Verificar sesión",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "SKANO protege tu cuenta frente a reportes sensibles.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.38),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
