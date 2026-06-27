import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalPaymentScreen extends StatefulWidget {
  const ExternalPaymentScreen({super.key});

  @override
  State<ExternalPaymentScreen> createState() => _ExternalPaymentScreenState();
}

class _ExternalPaymentScreenState extends State<ExternalPaymentScreen> {
  bool _opened = false;
  String? _url;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _url = args?["url"]?.toString();
  }

  @override
  void didUpdateWidget(covariant ExternalPaymentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openPayment();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPayment();
    });
  }

  Future<void> _openPayment() async {
    if (_opened) return;
    if (_url == null || _url!.isEmpty) return;

    _opened = true;

    final uri = Uri.parse(_url!);
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text("Pago en proceso"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              "Te estamos redirigiendo a Mercado Pago.\n\n"
              "Cuando finalices el pago, vuelve a la app.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/my_vehicles",
                  (_) => false,
                ),
                child: const Text("Volver a la app"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
