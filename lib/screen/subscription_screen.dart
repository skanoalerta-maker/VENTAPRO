import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  String currentPlan = "free";
  bool planActive = false;
  int vehiclesLimit = 0;
  String renewalDate = "";

  bool isLoading = false;

  late AnimationController controller;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();
    loadSubscription();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    fade = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.forward();
  }

  // ================================
  //  CARGAR PLAN ACTUAL DEL USUARIO
  // ================================
  Future<void> loadSubscription() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = doc.data() ?? {};

      setState(() {
        currentPlan = data["membership_plan"] ?? "free";
        planActive = data["membership_active"] ?? false;
        vehiclesLimit = data["membership_limit"] ?? 1;
        renewalDate = data["membership_renewal"] ?? "No definida";
      });
    } catch (e) {
      debugPrint("Error cargando suscripción: $e");
    }
  }

  // ================================
  //  REDIRECCIÓN A MERCADO PAGO
  // ================================
  Future<void> _openMercadoPago() async {
    setState(() => isLoading = true);

    const url = "https://www.mercadopago.cl";

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Mi Suscripción"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: fade,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------
              //     TÍTULO DEL PLAN
              // ------------------------------------------
              Text(
                planActive
                    ? "Plan actual: ${currentPlan.toUpperCase()}"
                    : "No tienes un plan activo",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------
              //     DETALLES DEL PLAN ACTIVO
              // ------------------------------------------
              if (planActive) ...[
                _infoRow("Vehículos permitidos", "$vehiclesLimit"),
                _infoRow("Renovación", renewalDate),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openMercadoPago,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Gestionar suscripción",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              // ------------------------------------------
              //  SI NO TIENE PLAN
              // ------------------------------------------
              if (!planActive) ...[
                const Text(
                  "Activa SKANO Premium para proteger tus vehículos y recibir reportes verificados.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openMercadoPago,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Activar suscripción",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
