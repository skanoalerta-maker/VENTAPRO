import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReviewBankVerificationScreen extends StatefulWidget {
  final String userId;
  const AdminReviewBankVerificationScreen({super.key, required this.userId});

  @override
  State<AdminReviewBankVerificationScreen> createState() =>
      _AdminReviewBankVerificationScreenState();
}

class _AdminReviewBankVerificationScreenState
    extends State<AdminReviewBankVerificationScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);

  bool processing = false;
  final TextEditingController commentCtrl = TextEditingController();

  Future<void> _approve(Map<String, dynamic> d) async {
    if (processing) return;
    setState(() => processing = true);

    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .update({
      "payout_verification_status": "approved",
      "bank_verified": true,
      "payout_admin_comment": commentCtrl.text.trim(),
      "payout_verified_at": now,
      "updated_at": now,
    });

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "BANK_VERIFICATION_APPROVED",
      "adminUid": adminUid,
      "targetCollection": "users",
      "targetId": widget.userId,
      "createdAt": now,
      "details": {
        "email": d["email"],
        "bank_name": d["bank_name"],
        "account_type": d["account_type"],
        "account_number": d["account_number"],
      },
    });

    if (!mounted) return;
    setState(() => processing = false);
    Navigator.pop(context);
  }

  Future<void> _reject(Map<String, dynamic> d) async {
    final comment = commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes indicar el motivo del rechazo"),
        ),
      );
      return;
    }

    if (processing) return;
    setState(() => processing = true);

    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .update({
      "payout_verification_status": "rejected",
      "bank_verified": false,
      "payout_admin_comment": comment,
      "updated_at": now,
    });

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "BANK_VERIFICATION_REJECTED",
      "adminUid": adminUid,
      "targetCollection": "users",
      "targetId": widget.userId,
      "createdAt": now,
      "details": {
        "email": d["email"],
        "bank_name": d["bank_name"],
        "account_type": d["account_type"],
        "account_number": d["account_number"],
        "reason": comment,
      },
    });

    if (!mounted) return;
    setState(() => processing = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: neonBlue),
            ),
          );
        }

        final d = snapshot.data!.data();
        if (d == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Usuario no encontrado",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text("Revisión bancaria"),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Nombre", d["full_name"]),
                _info("RUT", d["nationalId"]),
                _info("Email", d["email"]),
                _info("Banco", d["bank_name"]),
                _info("Tipo de cuenta", d["account_type"]),
                _info("Número de cuenta", d["account_number"]),
                _info(
                  "Estado bancario",
                  d["payout_verification_status"] ?? "pending",
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white24),

                const Text(
                  "Documentos bancarios",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                _docImage("Cédula frontal", d["payout_id_front_url"]),
                _docImage("Cédula reverso", d["payout_id_back_url"]),
                _docImage("Cartola / documento bancario", d["bankDocumentUrl"]),

                const SizedBox(height: 20),

                TextField(
                  controller: commentCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Comentario administrador",
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),

                const SizedBox(height: 30),

                if (!processing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _approve(d),
                          child: const Text("APROBAR"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _reject(d),
                          child: const Text("RECHAZAR"),
                        ),
                      ),
                    ],
                  ),

                if (processing)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: neonBlue),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label: ${value ?? "-"}",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _docImage(String title, String? url) {
    if (url == null || url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          "$title: no enviado",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}