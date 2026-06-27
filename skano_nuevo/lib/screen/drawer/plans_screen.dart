import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  Future<void> _openCheckout() async {
    const url = 'https://www.mercadopago.cl'; // luego va tu checkout real
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint("No se pudo abrir Mercado Pago");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Planes SKANO"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Activa tu protección",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Elige el plan que mejor se adapte a tu necesidad",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              _planCard(
                title: "Plan Premium (Dueños)",
                price: "CLP 16.990 / por vehículo",
                benefits: const [
                  "Protección activa 24/7",
                  "Alertas en tiempo real",
                  "Publicación en red SKANO",
                  "Historial de reportes",
                ],
                color: neonBlue,
                onTap: _openCheckout,
              ),

              const SizedBox(height: 25),

              _planCard(
                title: "Plan Empresa",
                price: "Desde CLP 12.990 por vehículo",
                benefits: const [
                  "Para flotas y empresas",
                  "Descuentos por volumen",
                  "Gestión avanzada",
                ],
                color: Colors.greenAccent,
                onTap: _openCheckout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required List<String> benefits,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              child: const Text(
                "Suscribirme",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
