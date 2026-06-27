import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class PayMembershipScreen extends StatefulWidget {
  const PayMembershipScreen({super.key});

  @override
  State<PayMembershipScreen> createState() => _PayMembershipScreenState();
}

class _PayMembershipScreenState extends State<PayMembershipScreen> {
  static const Color neon = Color(0xFF0A6CFF);

  bool loading = false;
  String? error;

  late String vehicleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final vid = args?["vehicleId"]?.toString();
    if (vid == null || vid.isEmpty) {
      error = "No se pudo determinar el vehículo a activar.";
      return;
    }

    vehicleId = vid;
  }

  Future<void> _openMpUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No se pudo abrir automáticamente Mercado Pago.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo abrir el link de pago: $e"),
        ),
      );
    }
  }

  Future<void> _payMembership() async {
    if (loading) return;

    try {
      setState(() {
        loading = true;
        error = null;
      });

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createVehiclePreference');

      final result = await callable.call({
        'vehicleId': vehicleId,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      final String? url = data['initPoint'] as String?;

      if (url == null || url.isEmpty) {
        throw Exception('No se recibió link de pago');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Redirigiendo a Mercado Pago..."),
        ),
      );

      await _openMpUrl(url);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Activar membresía"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Plan Dueño SKANO",
              style: TextStyle(
                color: neon,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "La membresía es obligatoria para activar la protección del vehículo.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _planCard(),
            const Spacer(),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _payMembership,
                icon: const Icon(Icons.payment, color: Colors.white),
                label: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        "Pagar y activar membresía",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              neon.withOpacity(.25),
              neon.withOpacity(.05),
            ],
          ),
          border: Border.all(color: neon),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "\$16.990 / mes por vehículo",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "✔ Activación de protección",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "✔ Encargo por robo",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "✔ Recepción de reportes",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "✔ Soporte prioritario",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
}