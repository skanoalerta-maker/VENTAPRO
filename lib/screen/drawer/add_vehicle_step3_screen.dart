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
  static const Color cyan = Color(0xFF00D5FF);
  static const Color green = Color(0xFF19C37D);
  static const Color bg = Color(0xFF020617);
  static const Color card = Color(0xFF0B1220);

  final TextEditingController _pinCtrl = TextEditingController();

  bool _pinValid = false;
  bool _loadingPay = false;
  bool _loadingRequest = false;
  bool _openingMp = false;
  bool _membershipActive = false;
  bool _vehicleUploadAuthorized = false;
  bool _hasPendingRequest = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _checkoutSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _requestSub;

  DocumentReference<Map<String, dynamic>>? _checkoutRef;

  String? _checkoutUrl;
  String _checkoutStatus = "idle";

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  bool get _canContinueByAdmin =>
      _membershipActive || _vehicleUploadAuthorized;

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
      final authorized = data["vehicle_upload_authorized"] == true;

      if (mounted) {
        setState(() {
          _membershipActive = active;
          _vehicleUploadAuthorized = authorized;
        });
      }
    });

    _requestSub = FirebaseFirestore.instance
        .collection("vehicle_upload_requests")
        .where("uid", isEqualTo: uid)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _hasPendingRequest = snap.docs.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _userSub?.cancel();
    _checkoutSub?.cancel();
    _requestSub?.cancel();
    super.dispose();
  }

  void _validatePin(String value) {
    final clean = value.trim();
    final validNow = RegExp(r'^\d{6}$').hasMatch(clean);

    if (validNow != _pinValid && mounted) {
      setState(() => _pinValid = validNow);
    }
  }

  Future<void> _requestAdminAuthorization() async {
    if (_loadingRequest || _hasPendingRequest || _canContinueByAdmin) return;

    setState(() => _loadingRequest = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance.collection("vehicle_upload_requests").add({
        "uid": uid,
        "email": user?.email ?? userData["email"] ?? "",
        "full_name": userData["full_name"] ?? "",
        "phone": userData["phone"] ?? "",
        "status": "pending",
        "type": "vehicle_upload_without_payment",
        "reason": "Usuario solicita autorización para subir vehículo sin pago",
        "plate": widget.plate,
        "brand": widget.brand,
        "model": widget.model,
        "year": widget.year,
        "color": widget.color,
        "vehicle_type": widget.type,
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Solicitud enviada a SKANO. Cuando sea aprobada podrás continuar.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error enviando solicitud: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => _loadingRequest = false);
  }

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

  Future<void> _startPayment() async {
    if (!_pinValid || _loadingPay || _openingMp) return;
    if (_canContinueByAdmin) return;

    setState(() {
      _loadingPay = true;
      _checkoutUrl = null;
      _checkoutStatus = "pending";
    });

    try {
      final ref = await FirebaseFirestore.instance.collection("mp_checkout").add({
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

  void _continueToStep4() {
    if (!_canContinueByAdmin) return;

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
              "membership_required": !_vehicleUploadAuthorized,
              "membership_active": _membershipActive,
              "vehicle_upload_authorized": _vehicleUploadAuthorized,
              "membership_pending_activation": false,
            },
            "vehicleDocs": widget.vehicleDocs,
            if (_checkoutRef != null) "checkoutId": _checkoutRef!.id,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canPay = _pinValid && !_loadingPay && !_canContinueByAdmin;
    final bool canContinue = _canContinueByAdmin;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Agregar vehículo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.18,
            colors: [
              Color(0xFF102D5A),
              Color(0xFF07111F),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(
                  membershipActive: _membershipActive,
                  vehicleUploadAuthorized: _vehicleUploadAuthorized,
                  plate: widget.plate,
                ),
                const SizedBox(height: 20),
                _planCard(),
                const SizedBox(height: 18),
                _statusCard(),
                const SizedBox(height: 18),
                if (!canContinue) ...[
                  _pinSection(),
                  const SizedBox(height: 22),
                  _paymentButton(canPay: canPay),
                  const SizedBox(height: 12),
                  _adminRequestButton(),
                ],
                if (_checkoutUrl != null && !canContinue) ...[
                  const SizedBox(height: 10),
                  _openMpButton(),
                ],
                const SizedBox(height: 12),
                _continueButton(canContinue: canContinue),
                const SizedBox(height: 16),
                _legalBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cyan.withOpacity(0.16)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Membresía Dueño",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "\$16.990",
              style: TextStyle(
                color: green,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              "por vehículo / mes",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            _BenefitRow(text: "Protección activa en SKANO"),
            _BenefitRow(text: "Vehículo registrado con encargo por robo"),
            _BenefitRow(text: "Recepción de reportes ciudadanos"),
            _BenefitRow(text: "Soporte y revisión prioritaria"),
          ],
        ),
      );

  Widget _statusCard() {
    final bool ok = _canContinueByAdmin;

    String text;
    Color color;
    IconData icon;

    if (_membershipActive) {
      text = "Membresía activa. Ya puedes continuar con el registro.";
      color = green;
      icon = Icons.check_circle_rounded;
    } else if (_vehicleUploadAuthorized) {
      text = "Autorización SKANO activa. Puedes continuar sin pago.";
      color = cyan;
      icon = Icons.verified_user_rounded;
    } else if (_hasPendingRequest) {
      text = "Solicitud enviada. Esperando aprobación del administrador.";
      color = Colors.orange;
      icon = Icons.hourglass_top_rounded;
    } else {
      text = "Puedes pagar la membresía o solicitar autorización a SKANO.";
      color = Colors.orange;
      icon = Icons.access_time_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          if (ok)
            const Icon(Icons.lock_open_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _pinSection() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cyan.withOpacity(0.14)),
        ),
        child: TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: cyan),
            hintText: "PIN de 6 dígitos",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.32)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.055),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: cyan, width: 1.3),
            ),
          ),
          onChanged: _validatePin,
        ),
      );

  Widget _paymentButton({required bool canPay}) => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: canPay ? _startPayment : null,
          child: _loadingPay
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Activar membresía \$16.990"),
        ),
      );

  Widget _adminRequestButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: (!_loadingRequest && !_hasPendingRequest)
              ? _requestAdminAuthorization
              : null,
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: Text(
            _hasPendingRequest
                ? "Solicitud enviada a SKANO"
                : "Solicitar autorización a SKANO",
          ),
        ),
      );

  Widget _openMpButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: () => _openMpUrl(_checkoutUrl!),
          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
          label: const Text("Abrir Mercado Pago"),
        ),
      );

  Widget _continueButton({required bool canContinue}) => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: canContinue ? _continueToStep4 : null,
          child: const Text("Continuar"),
        ),
      );

  Widget _legalBox() => Text(
        _membershipActive
            ? "Membresía activa. Continúa para completar el registro del vehículo."
            : _vehicleUploadAuthorized
                ? "Autorización SKANO activa. Continúa para completar el registro del vehículo."
                : "Puedes activar la membresía por Mercado Pago o solicitar autorización manual a SKANO.",
        style: TextStyle(
          color: Colors.white.withOpacity(0.66),
          height: 1.38,
          fontWeight: FontWeight.w600,
          fontSize: 13.2,
        ),
      );
}

class _StepHeader extends StatelessWidget {
  final bool membershipActive;
  final bool vehicleUploadAuthorized;
  final String plate;

  const _StepHeader({
    required this.membershipActive,
    required this.vehicleUploadAuthorized,
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = membershipActive || vehicleUploadAuthorized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Activación de membresía",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          active
              ? "Ya puedes continuar con el registro del vehículo $plate."
              : "Activa la protección o solicita autorización para continuar con el vehículo $plate.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _AddVehicleStep3ScreenState.green,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}