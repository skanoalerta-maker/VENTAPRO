import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  final user = FirebaseAuth.instance.currentUser;

  bool loading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ================= FIRESTORE =================
  Future<void> _loadUserData() async {
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (!snap.exists) return;

    userData = snap.data();
    if (userData == null) return;

    final role = userData?["role"];
    final documentStatus = userData?["documentStatus"];
    final verificationStatus = userData?["verification_status"];
    final reviewPending = userData?["reviewPending"] == true;

    // 🔥 BYPASS TOTAL PARA ADMIN
    if (role == "admin") {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
      return;
    }

    // ✅ USUARIO NORMAL APROBADO
    if (documentStatus == "approved" &&
        verificationStatus == "approved" &&
        !reviewPending) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
      return;
    }

    // ❌ SI NO → MOSTRAR PANTALLA DE REVISIÓN
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const Color neonBlue = Color(0xFF0A6CFF);

    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: neonBlue),
        ),
      );
    }

    final verificationStatus = userData?["verification_status"] ?? "pending";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Revisión en Proceso"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tu cuenta está en revisión",
              style: TextStyle(
                color: neonBlue,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Nuestro equipo está revisando tus documentos.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(color: neonBlue),
            ),
            const SizedBox(height: 30),

            // ❌ SOLO SI FUE RECHAZADO
            if (verificationStatus == "rejected") ...[
              const Text(
                "Tu verificación fue rechazada",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonBlue,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, "/document_upload");
                  },
                  child: const Text(
                    "Reenviar documentos",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
