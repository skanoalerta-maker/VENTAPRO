import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_update_required_screen.dart';

class StartGateScreen extends StatefulWidget {
  const StartGateScreen({super.key});

  @override
  State<StartGateScreen> createState() => _StartGateScreenState();
}

class _StartGateScreenState extends State<StartGateScreen> {
  bool _alreadyValidated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_alreadyValidated) return;
    _alreadyValidated = true;
    _validateStartGate();
  }

  void _safeNavigate(String route, {Object? arguments}) {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (r) => false,
      arguments: arguments,
    );
  }

  void _goToUpdateRequired() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AppUpdateRequiredScreen(),
      ),
      (route) => false,
    );
  }

  Future<bool> _requiresForceUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final configSnap = await FirebaseFirestore.instance
          .collection("app_config")
          .doc("version_control")
          .get()
          .timeout(const Duration(seconds: 5));

      if (!configSnap.exists) return false;

      final data = configSnap.data() ?? {};

      final bool forceUpdate = data["force_update"] == true;

      final rawMinimumBuild = data["minimum_build"];
      final int minimumBuild = rawMinimumBuild is int
          ? rawMinimumBuild
          : int.tryParse(rawMinimumBuild.toString()) ?? 0;

      debugPrint("SKANO BUILD ACTUAL: $currentBuild");
      debugPrint("SKANO BUILD MÍNIMO: $minimumBuild");
      debugPrint("SKANO FORCE UPDATE: $forceUpdate");

      return forceUpdate && currentBuild < minimumBuild;
    } catch (e) {
      debugPrint("Version control error: $e");
      return false;
    }
  }

  Future<void> _validateStartGate() async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // 0️⃣ Actualización obligatoria ANTES de todo
      final mustUpdate = await _requiresForceUpdate();
      if (mustUpdate) {
        _goToUpdateRequired();
        return;
      }

      final user = auth.currentUser;

      // 1️⃣ No logueado
      if (user == null) {
        _safeNavigate("/welcome");
        return;
      }

      // 2️⃣ Email verificado
      await user.reload();
      final refreshedUser = auth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        _safeNavigate("/verify_email");
        return;
      }

      final uid = refreshedUser.uid;

      // 3️⃣ Usuario existe en Firestore
      final snap = await firestore
          .collection("users")
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!snap.exists) {
        await auth.signOut();
        _safeNavigate("/welcome");
        return;
      }

      final data = snap.data()!;

      // 4️⃣ Términos
      if (data["termsAccepted"] != true) {
        _safeNavigate("/terms_accept");
        return;
      }

      // 5️⃣ Bloqueo real
      final blocked = data["blocked"] == true;
      final verificationStatus =
          (data["verification_status"] ?? "draft").toString();
      final identityChangePending = data["identity_change_pending"] == true;

      final isVerificationFlow =
          verificationStatus == "pending" || identityChangePending;

      if (blocked && !isVerificationFlow) {
        _safeNavigate(
          "/account_blocked",
          arguments: {
            "reason": data["blocked_reason"] ?? "Bloqueo por seguridad",
            "blockedUntil": data["blocked_until"]?.toDate(),
          },
        );
        return;
      }

      // 6️⃣ Registrar actividad
      try {
        await firestore.collection("users").doc(uid).update({
          "last_activity": FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      // 7️⃣ Entrada normal
      _safeNavigate("/home");
    } catch (e) {
      debugPrint("StartGate error: $e");
      _safeNavigate("/welcome");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 120, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "SKANO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Seguridad Inteligente",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}