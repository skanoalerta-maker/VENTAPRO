import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final user = FirebaseAuth.instance.currentUser;

  bool loading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (snap.exists) {
      userData = snap.data();

      // Si no tiene fecha de bloqueo → asignarla AHORA
      if (userData?["bloqueado_fecha"] == null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .update({
          "bloqueado_fecha": FieldValue.serverTimestamp(),
        });

        // Recargar datos
        final newSnap = await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get();
        userData = newSnap.data();
      }

      setState(() {
        loading = false;
      });
    }
  }

  String calculateDaysLeft(Timestamp bloqueadoFecha) {
    final fecha = bloqueadoFecha.toDate();
    final now = DateTime.now();

    final difference = now.difference(fecha).inDays;

    if (difference <= 1) return "3 días hábiles restantes";
    if (difference == 2) return "2 días hábiles restantes";
    if (difference >= 3) return "1 día hábil restante";

    return "En evaluación";
  }

  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final bloqueadoFecha = userData?["bloqueado_fecha"];
    final diasRestantes = bloqueadoFecha == null
        ? "En evaluación"
        : calculateDaysLeft(bloqueadoFecha);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cuenta Bloqueada"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Icon(Icons.lock_outline, color: neonBlue, size: 90),

            const SizedBox(height: 20),

            const Text(
              "Tu cuenta ha sido bloqueada por motivos de seguridad.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Esto puede ocurrir por múltiples intentos fallidos de verificación, documentos inválidos o actividad sospechosa.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: neonBlue),
              ),
              child: Column(
                children: [
                  const Text(
                    "⏳ Tiempo de desbloqueo:",
                    style: TextStyle(
                      color: neonBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    diasRestantes,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Un agente revisará tu caso manualmente.\n"
              "Recibirás un correo cuando tu cuenta sea desbloqueada.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),

            const Spacer(),

            TextButton(
              onPressed: () {},
              child: const Text(
                "Soporte: soporte@skano.app",
                style: TextStyle(color: neonBlue),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
