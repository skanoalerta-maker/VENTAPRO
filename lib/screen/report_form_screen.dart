import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ NAV ÚNICO
import '../app_navigator.dart';

// ✅ IMPORT DIRECTO AL SCANNER
import 'live_scanner_screen.dart';

class ReportFormScreen extends StatelessWidget {
  ReportFormScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bg = Color(0xFF050816);

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
         builder: (_) => const LiveScannerScreen(),
        ),
      );
      return result;
    }

    final result =
        await Navigator.of(context, rootNavigator: true).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LiveScannerScreen(),
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
      body: Stack(
        children: [
          const _RadarBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                        final reviewPending = data?["reviewPending"] == true;

                        final isApproved =
                            verificationStatus == "approved" && !reviewPending;

                        if (data == null || !isApproved) {
                          return const _AccountPendingView();
                        }

                        if (_isIdentityChangePending(data) ||
                            _isBlockedForIdentityChange(data)) {
                          return const _ReverificationRequiredView();
                        }

                        if (!_hasReportPin(data)) {
                          Future.microtask(() async {
                            await skanoPushNamed(
                              context,
                              "/session_verification",
                              arguments: {"nextRoute": "/report"},
                            );
                          });
                          return const SizedBox.shrink();
                        }

                        if (!_sessionIsValid(data)) {
                          Future.microtask(() async {
                            await skanoPushNamed(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _HeaderBar(
                                        onBack: () => Navigator.pop(context),
                                      ),
                                      const SizedBox(height: 18),
                                      const _HeroAlertCard(),
                                      const SizedBox(height: 16),
                                      const _DividerOr(),
                                      const SizedBox(height: 16),
                                      _ActionCard(
                                        title: "DIGITAR PATENTE",
                                        subtitle: "Consulta manual en segundos",
                                        accent: neonBlue,
                                        icon: Icons.keyboard_alt_rounded,
                                        badge: "MANUAL",
                                        child: Column(
                                          children: [
                                            _PlateInput(
                                              controller: plateCtrl,
                                              onSubmitted: () =>
                                                  _verifyPlateAndRoute(
                                                context: context,
                                                plateRaw: plateCtrl.text,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            _GradientButton(
                                              label: "BUSCAR",
                                              icon: Icons.search_rounded,
                                              colors: const [
                                                Color(0xFF0A84FF),
                                                Color(0xFF0057FF),
                                              ],
                                              shadowColor: neonBlue,
                                              onPressed: () =>
                                                  _verifyPlateAndRoute(
                                                context: context,
                                                plateRaw: plateCtrl.text,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _ActionCard(
                                        title: "ESCANEAR PATENTE",
                                        subtitle:
                                            "Abre la cámara y captura la placa",
                                        accent: const Color(0xFF22C55E),
                                        icon: Icons.center_focus_strong_rounded,
                                        badge: "CÁMARA",
                                        child: Column(
                                          children: [
                                            const _ScannerPreview(),
                                            const SizedBox(height: 14),
                                            _GradientButton(
                                              label: "ABRIR ESCÁNER",
                                              icon: Icons.camera_alt_rounded,
                                              colors: const [
                                                Color(0xFF22C55E),
                                                Color(0xFF16A34A),
                                              ],
                                              shadowColor:
                                                  const Color(0xFF22C55E),
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
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const _SafetyFooter(),
                                      const Spacer(),
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
        ],
      ),
    );
  }
}

class _RadarBackground extends StatelessWidget {
  const _RadarBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF0B1B3D),
              Color(0xFF050816),
              Colors.black,
            ],
            stops: [0.0, 0.46, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: _GlowCircle(
                size: 280,
                color: ReportFormScreen.neonBlue.withOpacity(0.34),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -90,
              child: _GlowCircle(
                size: 260,
                color: const Color(0xFF22C55E).withOpacity(0.18),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.10,
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 130,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.7;

    const spacing = 42.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onBack;

  const _HeaderBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220).withOpacity(0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: ReportFormScreen.neonBlue.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/skano_logo.png',
                  height: 34,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shield_rounded,
                    color: ReportFormScreen.neonBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Buscar vehículo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Consulta patente en tiempo real",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}

class _HeroAlertCard extends StatelessWidget {
  const _HeroAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF0B1220),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ReportFormScreen.neonBlue.withOpacity(0.34),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ReportFormScreen.neonBlue.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.32),
                  Colors.redAccent.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.28),
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verificación SKANO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Ingresa o escanea la patente para saber si tiene encargo por robo activo.",
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.28,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.16),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: const Text(
            "O",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlateInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const _PlateInput({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF061020),
            Color(0xFF0B1730),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ReportFormScreen.neonBlue.withOpacity(0.48),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: ReportFormScreen.neonBlue.withOpacity(0.20),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            left: 8,
            child: Container(
              width: 34,
              height: 5,
              decoration: BoxDecoration(
                color: ReportFormScreen.neonBlue.withOpacity(0.32),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 7,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "------",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.20),
                fontSize: 27,
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [
                    Colors.grey.shade700,
                    Colors.grey.shade800,
                  ]
                : colors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.40),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 21),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
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

class _ScannerPreview extends StatelessWidget {
  const _ScannerPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF061020),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.38),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerLinesPainter(),
            ),
          ),
          Center(
            child: Container(
              width: 138,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.80),
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "AB 12 CD",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.12)
      ..strokeWidth = 1;

    for (double y = 12; y < size.height; y += 14) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), line);
    }

    final corner = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const len = 18.0;
    const pad = 14.0;

    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), corner);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + len), corner);

    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad - len, pad),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad, pad + len),
      corner,
    );

    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad + len, size.height - pad),
      corner,
    );
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad, size.height - pad - len),
      corner,
    );

    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad - len, size.height - pad),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad, size.height - pad - len),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafetyFooter extends StatelessWidget {
  const _SafetyFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: Colors.white38,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Solo usuarios verificados pueden reportar. Esto protege el sistema, evita abusos y resguarda las recompensas.",
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Color(0x73FFFFFF),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
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
  final String badge;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.child,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111827),
            Color(0xFF0B1220),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.42), width: 1.25),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.25),
                      accent.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withOpacity(0.22)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
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