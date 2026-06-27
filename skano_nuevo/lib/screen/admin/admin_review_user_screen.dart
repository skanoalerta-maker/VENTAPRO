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

  Color _statusColor(String value) {
    switch (value.toString().toLowerCase()) {
      case "approved":
        return Colors.greenAccent;
      case "rejected":
        return Colors.redAccent;
      case "pending":
      case "pending_review":
      case "draft":
        return Colors.orangeAccent;
      default:
        return neonBlue;
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required Color color,
    String okText = "Confirmar",
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101622),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: color.withOpacity(0.45)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(okText),
          ),
        ],
      ),
    );

    return res == true;
  }

  Future<void> _approveUser(Map<String, dynamic> d) async {
    if (processing) return;

    final ok = await _confirm(
      title: "Aprobar usuario",
      body: "¿Confirmas que deseas aprobar esta identidad?\n\nEl usuario quedará habilitado para funciones críticas de SKANO.",
      color: Colors.green,
      okText: "Aprobar",
    );

    if (!ok) return;

    setState(() => processing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("No hay administrador autenticado.");
      }

      final adminUid = currentUser.uid;
      final comment = commentCtrl.text.trim().isEmpty
          ? "Usuario aprobado"
          : commentCtrl.text.trim();

      await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
        "verification_status": "approved",
        "documentStatus": "approved",
        "documentsCompleted": true,
        "reviewPending": false,
        "blocked": false,
        "blocked_reason": null,
        "blocked_until": null,
        "blocked_by_admin": false,
        "identity_change_pending": false,
        "identityChangePending": false,
        "adminComment": comment,
        "approved_at": FieldValue.serverTimestamp(),
        "approved_by": adminUid,
        "updated_at": FieldValue.serverTimestamp(),
        "approval_email_pending": true,
        "approval_email_sent": false,
        "approval_email_error": null,
      });

      FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "USER_APPROVED",
        "adminUid": adminUid,
        "targetCollection": "users",
        "targetId": widget.userId,
        "createdAt": FieldValue.serverTimestamp(),
        "details": {
          "email": d["email"],
          "nationalId": d["nationalId"],
          "full_name": d["full_name"],
          "comment": comment,
        },
      }).catchError((e) {
        debugPrint("ERROR ADMIN LOG USER_APPROVED: $e");
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Usuario aprobado correctamente"),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("ERROR APPROVE USER: $e");

      if (!mounted) return;

      setState(() => processing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Error al aprobar usuario: $e"),
        ),
      );
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> d) async {
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

    final ok = await _confirm(
      title: "Rechazar usuario",
      body: "¿Confirmas el rechazo de esta identidad?\n\nEl usuario quedará bloqueado administrativamente.",
      color: Colors.redAccent,
      okText: "Rechazar",
    );

    if (!ok) return;

    setState(() => processing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception("No hay administrador autenticado.");
      }

      final adminUid = currentUser.uid;

      await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
        "verification_status": "rejected",
        "documentStatus": "rejected",
        "documentsCompleted": false,
        "reviewPending": false,
        "blocked": true,
        "blocked_by_admin": true,
        "blocked_reason": "verification_rejected",
        "adminComment": comment,
        "rejected_at": FieldValue.serverTimestamp(),
        "rejected_by": adminUid,
        "updated_at": FieldValue.serverTimestamp(),
        "rejection_email_pending": true,
        "rejection_email_sent": false,
        "rejection_email_error": null,
      });

      FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "USER_REJECTED",
        "adminUid": adminUid,
        "targetCollection": "users",
        "targetId": widget.userId,
        "createdAt": FieldValue.serverTimestamp(),
        "details": {
          "email": d["email"],
          "nationalId": d["nationalId"],
          "full_name": d["full_name"],
          "reason": comment,
        },
      }).catchError((e) {
        debugPrint("ERROR ADMIN LOG USER_REJECTED: $e");
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Usuario rechazado"),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("ERROR REJECT USER: $e");

      if (!mounted) return;

      setState(() => processing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Error al rechazar usuario: $e"),
        ),
      );
    }
  }

  Widget _header(Map<String, dynamic> d) {
    final name = _safe(d["full_name"]);
    final email = _safe(d["email"]);
    final status = _safe(d["verification_status"]);
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF151B26), Color(0xFF0C111A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(Icons.person_search_outlined, color: color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == "-" ? "Usuario sin nombre" : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _badge("Estado", status, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        "$label: ${value == "-" ? "—" : value.toUpperCase()}",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoPanel(Map<String, dynamic> d) {
    final rut = d["nationalId"] ??
        d["rut"] ??
        d["national_id"] ??
        d["rut_normalized"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos de identidad",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.badge_outlined, "RUT", rut),
          _infoRow(Icons.email_outlined, "Email", d["email"]),
          _infoRow(Icons.verified_user_outlined, "Estado principal", d["verification_status"]),
          _infoRow(Icons.description_outlined, "Estado documento", d["documentStatus"]),
          _infoRow(Icons.pending_actions_outlined, "Pendiente revisión", d["reviewPending"]),
          _infoRow(Icons.task_alt_outlined, "Documentos completos", d["documentsCompleted"]),
          _infoRow(Icons.block_outlined, "Bloqueado", d["blocked"]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  TextSpan(
                    text: _safe(value),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsPanel(Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Documentos enviados",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _docImage(
            "Selfie facial",
            d["faceUrl"] ?? d["identityPhotoUrl"] ?? d["identity_photo_url"],
            Icons.face_retouching_natural,
            neonBlue,
          ),
          _docImage("Cédula frontal", d["idFrontUrl"], Icons.credit_card, Colors.greenAccent),
          _docImage("Cédula reverso", d["idBackUrl"], Icons.credit_card_outlined, Colors.orangeAccent),
          _docImage("Comprobante de domicilio", d["addressProofUrl"], Icons.home_outlined, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _docImage(String title, dynamic urlValue, IconData icon, Color color) {
    final String url = (urlValue ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C111A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: url.isEmpty ? Colors.white12 : color.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: url.isEmpty ? Colors.white10 : color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: url.isEmpty ? Colors.white30 : color),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              url.isEmpty ? "No enviado" : "Documento disponible",
              style: TextStyle(
                color: url.isEmpty ? Colors.redAccent : Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          if (url.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: Image.network(
                  url,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: const Text(
                        "No se pudo cargar la imagen",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _commentBox() {
    return TextField(
      controller: commentCtrl,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Comentario administrador...",
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: neonBlue.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: neonBlue.withOpacity(0.22)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: neonBlue),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: processing ? null : onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
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
            backgroundColor: bg,
            body: Center(
              child: CircularProgressIndicator(color: neonBlue),
            ),
          );
        }

        final d = snapshot.data!.data();

        if (d == null) {
          return const Scaffold(
            backgroundColor: bg,
            body: Center(
              child: Text(
                "Usuario no encontrado",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              "Revisión de usuario",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _header(d),
                const SizedBox(height: 16),
                _infoPanel(d),
                const SizedBox(height: 16),
                _documentsPanel(d),
                const SizedBox(height: 16),
                _commentBox(),
                const SizedBox(height: 18),
                if (!processing)
                  Row(
                    children: [
                      _actionButton(
                        text: "APROBAR",
                        icon: Icons.verified_outlined,
                        color: Colors.green.shade700,
                        onTap: () => _approveUser(d),
                      ),
                      const SizedBox(width: 12),
                      _actionButton(
                        text: "RECHAZAR",
                        icon: Icons.cancel_outlined,
                        color: Colors.red.shade700,
                        onTap: () => _rejectUser(d),
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}