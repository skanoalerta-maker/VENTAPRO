import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_vehicle_step4_screen.dart';

class AddVehicleStep3Screen extends StatefulWidget {
  final String plate;
  final String brand;
  final String model;
  final String year;
  final String color;
  final String type;
  final Map<String, File> vehicleDocs;

  const AddVehicleStep3Screen({
    super.key,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
    required this.vehicleDocs,
  });

  @override
  State<AddVehicleStep3Screen> createState() => _AddVehicleStep3ScreenState();
}

class _AddVehicleStep3ScreenState extends State<AddVehicleStep3Screen> {
  static const Color neon = Color(0xFF0A6CFF);

  bool _loadingPay = false;
  bool _openingMp = false;

  bool _membershipActive = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _checkoutSub;

  DocumentReference<Map<String, dynamic>>? _checkoutRef;

  String? _checkoutUrl;
  String _checkoutStatus = "idle"; // idle | pending | ready | error

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    _userSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final active = data["membership_active"] == true;
      if (active != _membershipActive && mounted) {
        setState(() => _membershipActive = active);
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _checkoutSub?.cancel();
    super.dispose();
  }

  // ===============================
  // 🧾 Abrir URL MP (con fallback)
  // ===============================
  Future<void> _openMpUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No se pudo abrir automáticamente. Usa “Abrir Mercado Pago”.",
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Link inválido. Intenta nuevamente."),
        ),
      );
    }
  }

  // ===============================
  // 💳 CREAR CHECKOUT + ESPERAR URL + ABRIR MP
  // ===============================
  Future<void> _startPayment() async {
    if (_loadingPay || _openingMp) return;
    if (_membershipActive) return;

    setState(() {
      _loadingPay = true;
      _checkoutUrl = null;
      _checkoutStatus = "pending";
    });

    try {
      final ref =
          await FirebaseFirestore.instance.collection("mp_checkout").add({
        "uid": uid,
        "plan": "owner_monthly",
        "vehicles": 1,
        "status": "pending",
        "created_at": FieldValue.serverTimestamp(),
      });

      _checkoutRef = ref;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Generando link de pago… se abrirá Mercado Pago automáticamente.",
          ),
        ),
      );

      await _checkoutSub?.cancel();

      Timer? timeout;
      timeout = Timer(const Duration(seconds: 20), () async {
        if (!mounted) return;
        if (_checkoutUrl == null && _checkoutStatus == "pending") {
          await _checkoutSub?.cancel();
          setState(() => _checkoutStatus = "error");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No llegó el link de pago. Revisa Functions / Logs y reintenta.",
              ),
            ),
          );
        }
      });

      _checkoutSub = ref.snapshots().listen((snap) async {
        final data = snap.data();
        if (data == null) return;

        final status = (data["status"] ?? "pending").toString();
        final url = data["checkout_url"];

        if (status == "error") {
          timeout?.cancel();
          await _checkoutSub?.cancel();
          if (!mounted) return;
          setState(() => _checkoutStatus = "error");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se pudo generar el link de pago. Intenta nuevamente.",
              ),
            ),
          );
          return;
        }

        if (url is String && url.isNotEmpty) {
          timeout?.cancel();

          if (mounted) {
            setState(() {
              _checkoutUrl = url;
              _checkoutStatus = "ready";
            });
          }

          if (!_openingMp) {
            _openingMp = true;
            await _checkoutSub?.cancel();
            await _openMpUrl(url);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkoutStatus = "error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error iniciando pago: $e")),
      );
    } finally {
      if (mounted) setState(() => _loadingPay = false);
    }
  }

  // ===============================
  // 👉 CONTINUAR (SOLO SI PAGÓ)
  // ===============================
  void _continueToStep4() {
    if (!_membershipActive) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddVehicleStep4Screen(),
        settings: RouteSettings(
          arguments: {
            "vehicleDraft": {
              "plate": widget.plate,
              "brand": widget.brand,
              "model": widget.model,
              "year": widget.year,
              "color": widget.color,
              "type": widget.type,
              "membership_required": true,
              "membership_active": true,
              "membership_pending_activation": false,
            },
            "vehicleDocs": widget.vehicleDocs,
            if (_checkoutRef != null) "checkoutId": _checkoutRef!.id,
          },
        ),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final bool canPay = !_loadingPay && !_membershipActive;
    final bool canContinue = _membershipActive;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Agregar vehículo (3/4)",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _planCard(),
            const SizedBox(height: 18),
            _statusCard(membershipActive: _membershipActive),
            const SizedBox(height: 18),

            // ===============================
            // 💳 PAGAR
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPay ? _startPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loadingPay
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        _membershipActive
                            ? "Membresía activa"
                            : "Activar membresía (\$16.990)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _membershipActive
                              ? Colors.white70
                              : Colors.white,
                        ),
                      ),
              ),
            ),

            if (_checkoutUrl != null && !_membershipActive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openMpUrl(_checkoutUrl!),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: neon.withOpacity(0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Abrir Mercado Pago",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ===============================
            // 👉 CONTINUAR (POST-PAGO)
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canContinue ? _continueToStep4 : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canContinue ? const Color(0xFF19C37D) : Colors.white10,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continuar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _legalBox(membershipActive: _membershipActive),
          ],
        ),
      ),
    );
  }

  // ===============================
  // COMPONENTES UI
  // ===============================
  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Plan Dueño SKANO",
            style: TextStyle(
              color: neon,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Para continuar con el registro de tu vehículo robado, primero debes activar tu membresía. Una vez realizado el pago, volverás automáticamente a este paso para continuar.",
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      );

  Widget _planCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: neon.withOpacity(0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Membresía Dueño",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "\$16.990 por vehículo / mes",
              style: TextStyle(
                color: Color(0xFF19C37D),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Incluye:\n"
              "• Protección activa\n"
              "• Encargo por robo\n"
              "• Recepción de reportes\n"
              "• Soporte prioritario",
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      );

  Widget _statusCard({required bool membershipActive}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: membershipActive
              ? const Color(0xFF19C37D).withOpacity(0.12)
              : Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: membershipActive
                ? const Color(0xFF19C37D).withOpacity(0.35)
                : Colors.orange.withOpacity(0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              membershipActive ? Icons.verified_rounded : Icons.info_outline,
              color: membershipActive ? const Color(0xFF19C37D) : Colors.orange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                membershipActive
                    ? "Membresía activa: ya puedes continuar con el registro del vehículo."
                    : "Membresía pendiente: debes completar el pago para continuar con el registro.",
                style: TextStyle(
                  color: membershipActive
                      ? const Color(0xFF19C37D)
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _legalBox({required bool membershipActive}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          membershipActive
              ? "Membresía activa. Continúa para completar el registro del vehículo y enviarlo a revisión."
              : "El pago se procesa en Mercado Pago. Si completas el pago, tu membresía se activará automáticamente y podrás continuar desde este mismo paso. Si no completas el pago, la membresía no se activará y podrás intentarlo nuevamente más tarde.",
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
      );
}