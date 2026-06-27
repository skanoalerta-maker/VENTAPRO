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

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Verificación de sesión",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.lock_outline, size: 90, color: neonBlue),
            const SizedBox(height: 20),
            const Text(
              "Ingresa tu PIN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Por seguridad, ingresa tu PIN.\n"
              "La sesión será válida por 20 minutos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                counterText: "",
                hintText: "PIN de 6 dígitos",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (v) => pin = v.trim(),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: loading ? null : _verifyPin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verificar sesión",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}