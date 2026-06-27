import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReviewUserScreen extends StatefulWidget {
  final String userId;

  const AdminReviewUserScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminReviewUserScreen> createState() => _AdminReviewUserScreenState();
}

class _AdminReviewUserScreenState extends State<AdminReviewUserScreen> {
  static const Color bg = Color(0xFF080B12);
  static const Color card = Color(0xFF111722);
  static const Color neonBlue = Color(0xFF0A6CFF);

  bool processing = false;
  final TextEditingController commentCtrl = TextEditingController();

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  String _safe(dynamic v) => (v ?? "-").toString();

  Future<void> _approveUser(Map<String, dynamic> d) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    setState(() => processing = true);

    await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
      "verification_status": "approved",
      "documentStatus": "approved",
      "documentsCompleted": true,
      "reviewPending": false,
      "blocked": false,
      "blocked_reason": null,
      "blocked_until": null,
      "blocked_by_admin": false,
      "adminComment": commentCtrl.text.trim(),
      "approved_at": FieldValue.serverTimestamp(),
      "approved_by": adminUid,
      "updated_at": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "USER_APPROVED",
      "adminUid": adminUid,
      "targetCollection": "users",
      "targetId": widget.userId,
      "createdAt": FieldValue.serverTimestamp(),
      "details": {
        "email": d["email"],
        "nationalId": d["nationalId"],
      },
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _rejectUser(Map<String, dynamic> d) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    setState(() => processing = true);

    await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
      "verification_status": "rejected",
      "documentStatus": "rejected",
      "documentsCompleted": false,
      "reviewPending": false,
      "blocked": true,
      "blocked_by_admin": true,
      "blocked_reason": "verification_rejected",
      "adminComment": commentCtrl.text.trim(),
      "rejected_at": FieldValue.serverTimestamp(),
      "rejected_by": adminUid,
      "updated_at": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "USER_REJECTED",
      "adminUid": adminUid,
      "targetCollection": "users",
      "targetId": widget.userId,
      "createdAt": FieldValue.serverTimestamp(),
      "details": {
        "email": d["email"],
        "nationalId": d["nationalId"],
        "reason": commentCtrl.text.trim(),
      },
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label: ${_safe(value)}",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _imageBox(String title, dynamic urlValue) {
    final url = (urlValue ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (url.isEmpty)
            const Text("No enviado", style: TextStyle(color: Colors.redAccent))
          else
            Image.network(url, height: 220, width: double.infinity, fit: BoxFit.contain),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("users").doc(widget.userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: bg,
            body: Center(child: CircularProgressIndicator(color: neonBlue)),
          );
        }

        final d = snap.data!.data();

        if (d == null) {
          return const Scaffold(
            backgroundColor: bg,
            body: Center(
              child: Text("Usuario no encontrado", style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text("Revisión de usuario"),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _safe(d["full_name"]),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(_safe(d["email"]), style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 18),

                _info("RUT", d["nationalId"] ?? d["rut"] ?? d["rut_normalized"]),
                _info("Teléfono", d["phone"]),
                _info("Estado", d["verification_status"]),
                _info("Documentos", d["documentStatus"]),
                _info("Pendiente", d["reviewPending"]),
                _info("Bloqueado", d["blocked"]),

                const SizedBox(height: 18),

                _imageBox("Selfie facial", d["faceUrl"] ?? d["identityPhotoUrl"] ?? d["identity_photo_url"]),
                _imageBox("Cédula frontal", d["idFrontUrl"]),
                _imageBox("Cédula reverso", d["idBackUrl"]),
                _imageBox("Comprobante domicilio", d["addressProofUrl"]),

                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Comentario administrador...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                const SizedBox(height: 18),

                if (processing)
                  const Center(child: CircularProgressIndicator(color: neonBlue))
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveUser(d),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("APROBAR"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rejectUser(d),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text("RECHAZAR"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}