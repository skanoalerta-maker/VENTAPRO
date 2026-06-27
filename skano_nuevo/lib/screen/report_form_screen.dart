import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ NAV ÚNICO
import '../app_navigator.dart';

// ✅ IMPORT DIRECTO AL SCANNER
import 'plate_scanner_screen.dart';

class ReportFormScreen extends StatelessWidget {
  ReportFormScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bg = Colors.black;

  String _normalizePlate(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  bool _sessionIsValid(Map<String, dynamic> data) {
    final ts = data["session_verified_until"];
    if (ts == null) return false;
    return ts.toDate().isAfter(DateTime.now());
  }

  bool _isIdentityChangePending(Map<String, dynamic> data) {
    return data["identity_change_pending"] == true;
  }

  bool _isBlockedForIdentityChange(Map<String, dynamic> data) {
    if (data["blocked"] != true) return false;
    final reason = (data["blocked_reason"] ?? "").toString();
    return reason == "identity_change_pending";
  }

  bool _hasReportPin(Map<String, dynamic> data) {
    final v = data["report_pin_hash"];
    return v != null && v.toString().trim().isNotEmpty;
  }

  Future<void> _verifyPlateAndRoute({
    required BuildContext context,
    required String plateRaw,
  }) async {
    final raw = plateRaw.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa una patente válida")),
      );
      return;
    }

    final plate = _normalizePlate(raw);
    if (plate.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La patente debe tener 6 caracteres")),
      );
      return;
    }

    final hit = await FirebaseFirestore.instance
        .collection("stolen_vehicles")
        .where("plate", isEqualTo: plate)
        .where("status", isEqualTo: "stolen")
        .where("verified", isEqualTo: true)
        .where("active", isEqualTo: true)
        .limit(1)
        .get();

    if (!context.mounted) return;

    if (hit.docs.isNotEmpty) {
      final doc = hit.docs.first;
      final data = doc.data();

      final String vehiclePhotoUrl = (data["vehicle_photo_url"] ??
              data["vehiclePhotoUrl"] ??
              data["photoUrl"] ??
              "")
          .toString()
          .trim();

      await skanoPushReplacementNamed(
        context,
        '/report_result',
        arguments: {
          "plate": plate,
          "isStolen": true,
          "vehicleId": doc.id,
          "source": "stolen_vehicles",
          "vehiclePhotoUrl": vehiclePhotoUrl,
        },
      );
      return;
    } else {
      await skanoPushReplacementNamed(
        context,
        '/report_result',
        arguments: {"plate": plate, "isStolen": false},
      );
    }
  }

  Future<String?> _openScanner(BuildContext context) async {
    final nav = skanoNavigatorKey.currentState;
    if (nav != null) {
      final result = await nav.push<String?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PlateScannerScreen(),
        ),
      );
      return result;
    }

    final result =
        await Navigator.of(context, rootNavigator: true).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PlateScannerScreen(),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController plateCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: user == null
              ? _NotLoggedView()
              : FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: neonBlue),
                      );
                    }

                    final data = snap.data!.data() as Map<String, dynamic>?;

                    final verificationStatus =
                        (data?["verification_status"] ?? "draft").toString();
                    final docStatus =
                        (data?["documentStatus"] ?? "draft").toString();
                    final reviewPending = data?["reviewPending"] == true;
                    final documentsCompleted =
                        data?["documentsCompleted"] == true;

                    final isApproved =
                        (verificationStatus == "approved" ||
                                docStatus == "approved") &&
                            !reviewPending &&
                            documentsCompleted;

                    if (data == null || !isApproved) {
                      return const _AccountPendingView();
                    }

                    if (_isIdentityChangePending(data) ||
                        _isBlockedForIdentityChange(data)) {
                      return const _ReverificationRequiredView();
                    }

                    if (!_hasReportPin(data)) {
                      Future.microtask(() async {
                        await skanoPushReplacementNamed(
                          context,
                          "/session_verification",
                          arguments: {"nextRoute": "/report"},
                        );
                      });
                      return const SizedBox.shrink();
                    }

                    if (!_sessionIsValid(data)) {
                      Future.microtask(() async {
                        await skanoPushReplacementNamed(
                          context,
                          "/session_verification",
                          arguments: {"nextRoute": "/report"},
                        );
                      });
                      return const SizedBox.shrink();
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bottomInset =
                            MediaQuery.of(context).viewInsets.bottom;

                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/skano_logo.png',
                                              height: 34,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Buscar",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0x33FF3B30),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFFF3B30),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            "Ingresa o escanea la patente para verificar\nsi tiene encargo por robo en SKANO.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white10,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "O",
                                        style: TextStyle(color: Colors.white38),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _ActionCard(
                                    title: "DIGITAR PATENTE",
                                    subtitle:
                                        "Escribe la patente y presiona buscar",
                                    accent: neonBlue,
                                    icon: Icons.keyboard_alt_rounded,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B1220),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color:
                                                  neonBlue.withOpacity(0.25),
                                            ),
                                          ),
                                          child: TextField(
                                            controller: plateCtrl,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            keyboardType: TextInputType.text,
                                            textInputAction:
                                                TextInputAction.search,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[A-Z0-9]'),
                                              ),
                                            ],
                                            maxLength: 6,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 4,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: "",
                                              hintText: "— — — — —",
                                              hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.22),
                                                fontSize: 22,
                                                letterSpacing: 6,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) =>
                                                _verifyPlateAndRoute(
                                              context: context,
                                              plateRaw: plateCtrl.text,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: neonBlue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.search,
                                              color: Colors.black,
                                            ),
                                            label: const Text(
                                              "BUSCAR",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _verifyPlateAndRoute(
                                              context: context,
                                              plateRaw: plateCtrl.text,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _ActionCard(
                                    title: "ESCANEAR PATENTE",
                                    subtitle:
                                        "Abre la cámara y captura la patente",
                                    accent: const Color(0xFF22C55E),
                                    icon: Icons.center_focus_strong_rounded,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF22C55E),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                        ),
                                        label: const Text(
                                          "ABRIR ESCÁNER",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final result =
                                              await _openScanner(context);

                                          if (result is String) {
                                            final cleaned =
                                                _normalizePlate(result);
                                            if (cleaned.length == 6) {
                                              plateCtrl.text = cleaned;

                                              await _verifyPlateAndRoute(
                                                context: context,
                                                plateRaw: cleaned,
                                              );
                                            } else {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "No se detectó una patente válida",
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Spacer(),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Solo usuarios verificados pueden reportar.\nEsto protege el sistema y las recompensas.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final Widget child;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NotLoggedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Inicia sesión para reportar",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class _AccountPendingView extends StatelessWidget {
  const _AccountPendingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, color: Colors.orangeAccent, size: 64),
            SizedBox(height: 20),
            Text(
              "Cuenta en revisión",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Tus documentos están siendo revisados.\n"
              "Cuando tu cuenta sea aprobada podrás reportar vehículos.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReverificationRequiredView extends StatelessWidget {
  const _ReverificationRequiredView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: Colors.orangeAccent, size: 64),
            SizedBox(height: 20),
            Text(
              "Re-verificación requerida",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Solicitaste modificar datos verificados.\n"
              "Mientras se revisa tu solicitud, no podrás reportar.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}