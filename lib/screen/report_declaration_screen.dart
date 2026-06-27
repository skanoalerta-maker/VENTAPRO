import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ NAV ÚNICO
import '../app_navigator.dart';

class ReportDeclarationScreen extends StatefulWidget {
  const ReportDeclarationScreen({super.key});

  @override
  State<ReportDeclarationScreen> createState() => _ReportDeclarationScreenState();
}

class _ReportDeclarationScreenState extends State<ReportDeclarationScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);

  // ✅ SIGUIENTE PASO REAL: PROTOCOLO
  static const String nextRoute = "/report_protocol";

  bool accepted = false;
  bool saving = false;
  bool checkingSession = true;

  Map<String, dynamic>? vehicle;
  String stolenId = "";

  bool _sessionChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    vehicle = (args["vehicle"] as Map?)?.cast<String, dynamic>();

    stolenId = (args["stolenId"] ??
            vehicle?["id"] ??
            vehicle?["stolenId"] ??
            vehicle?["stolen_id"] ??
            "")
        .toString()
        .trim();

    if (!_sessionChecked) {
      _sessionChecked = true;
      _checkSession();
    }
  }

  // ===================================================
  // 🔐 VALIDAR SESIÓN POR PIN
  // ===================================================
  Future<void> _checkSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final ts = data["session_verified_until"] as Timestamp?;
      final now = DateTime.now();

      // ❌ Sesión inexistente o vencida → pedir PIN
      if (ts == null || ts.toDate().isBefore(now)) {
        if (!mounted) return;

        await skanoPushReplacementNamed(
          context,
          "/session_verification",
          arguments: {
            "nextRoute": "/report_declaration",
            "vehicle": vehicle,
            "stolenId": stolenId,
          },
        );
        return;
      }

      // ✅ Sesión válida
      if (mounted) setState(() => checkingSession = false);
    } catch (_) {
      // fallback: si algo falla, pedimos PIN igual
      if (!mounted) return;

      await skanoPushReplacementNamed(
        context,
        "/session_verification",
        arguments: {
          "nextRoute": "/report_declaration",
          "vehicle": vehicle,
          "stolenId": stolenId,
        },
      );
    }
  }

  // ===================================================
  // ✅ Continuar al protocolo
  // 🔥 IMPORTANTE: NO se escribe en reports aquí
  // ===================================================
  Future<void> _acceptAndContinue() async {
    if (!accepted || saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      final v = vehicle ?? {};
      final String plate = (v["plate"] ?? "").toString().toUpperCase().trim();

      final declaration = {
        "accepted": true,
        "accepted_at": DateTime.now().toIso8601String(),
        "method": "checkbox",
        "version": "v1.0",
        "text_hash": "sha256:8d92f1a3...",
        "accepted_by_uid": user.uid,
        "app_version": "1.0.0+1",
        "plate": plate,
        "stolen_id": stolenId.isEmpty ? null : stolenId,
      };

      if (!mounted) return;

      await skanoPushReplacementNamed(
        context,
        nextRoute,
        arguments: {
          "vehicle": {
            ...?vehicle,
            "id": stolenId.isNotEmpty ? stolenId : (vehicle?["id"] ?? ""),
          },
          "plate": plate,
          "stolenId": stolenId,
          "declaration": declaration,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo continuar: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checkingSession) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: neonBlue),
        ),
      );
    }

    if (vehicle == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              "Error: no se recibió el vehículo para la declaración.",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final plate = (vehicle?["plate"] ?? "---").toString().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Declaración jurada"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: neonBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.gavel, color: neonBlue),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Declaración jurada de reporte",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Este paso protege a la comunidad y evita reportes falsos.",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                plate,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B2D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    "Declaro bajo juramento que:\n\n"
                    "• El vehículo reportado corresponde exactamente a la patente indicada.\n"
                    "• He observado personalmente el vehículo en la ubicación donde iniciaré el reporte.\n"
                    "• La información entregada es veraz y no ha sido manipulada.\n"
                    "• Comprendo que proporcionar información falsa puede implicar bloqueo definitivo de mi cuenta y eventuales acciones legales conforme a la legislación chilena.\n"
                    "• Entiendo que SKANO actúa únicamente como plataforma tecnológica de alerta ciudadana y no reemplaza a Carabineros de Chile ni al Ministerio Público.\n"
                    "• Me comprometo a no intervenir, confrontar ni poner en riesgo mi integridad ni la de terceros. Ante cualquier situación de riesgo, debo contactar a las autoridades.\n\n"
                    "Al continuar, autorizo a SKANO a registrar evidencia técnica del reporte (hora, datos del dispositivo y ubicación aproximada) únicamente con fines de seguridad, auditoría y prevención de abuso.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: accepted,
              onChanged: saving ? null : (v) => setState(() => accepted = v ?? false),
              activeColor: neonBlue,
              checkColor: Colors.black,
              title: const Text(
                "Acepto y declaro bajo juramento",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                "La información falsa puede generar bloqueo y acciones legales.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accepted ? neonBlue : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: (!accepted || saving) ? null : _acceptAndContinue,
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "CONTINUAR AL PROTOCOLO",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
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
