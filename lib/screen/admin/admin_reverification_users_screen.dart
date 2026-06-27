import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminReverificationUsersScreen extends StatelessWidget {
  const AdminReverificationUsersScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  // ================= ADMIN LOG =================
  Future<void> _logAdminAction({
    required String action,
    required String targetUser,
    Map<String, dynamic>? details,
  }) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": action,
      "adminUid": adminUid,
      "targetCollection": "users",
      "targetId": targetUser,
      "createdAt": FieldValue.serverTimestamp(),
      "details": details ?? {},
    });
  }

  // ================= CONFIRM =================
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.black,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content:
                Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirmar"),
              ),
            ],
          ),
        )) ??
        false;
  }

  // ================= ASK REASON =================
  Future<String?> _askReason(BuildContext context) async {
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Motivo de rechazo",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Describe el motivo…",
            hintStyle: TextStyle(color: Colors.white54),
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text("Rechazar"),
          ),
        ],
      ),
    );
  }

  // ================= APPROVE =================
  Future<void> _approveUser(BuildContext context, String uid) async {
    final ok = await _confirm(
      context,
      title: "Aprobar re-verificación",
      message:
          "El usuario volverá a operar normalmente.\n\n¿Confirmas?",
    );
    if (!ok) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "identity_change_pending": false,
      "blocked": false,
      "blocked_reason": "",
      "reverified_at": FieldValue.serverTimestamp(),
      "admin_comment": "RE-VERIFICACIÓN APROBADA",
      "updated_at": FieldValue.serverTimestamp(),
    });

    await _logAdminAction(
      action: "user_reverification_approved",
      targetUser: uid,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Re-verificación aprobada")),
      );
    }
  }

  // ================= REJECT =================
  Future<void> _rejectUser(BuildContext context, String uid) async {
    final reason = await _askReason(context);
    if (reason == null || reason.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "identity_change_pending": false,
      "blocked": false,
      "blocked_reason": "",
      "admin_comment": "RE-VERIFICACIÓN RECHAZADA: $reason",
      "updated_at": FieldValue.serverTimestamp(),
    });

    await _logAdminAction(
      action: "user_reverification_rejected",
      targetUser: uid,
      details: {"reason": reason},
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Re-verificación rechazada")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection("users")
        .where("identity_change_pending", isEqualTo: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Re-verificación de usuarios",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error Firestore:\n${snap.error}",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "✅ No hay usuarios en re-verificación",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final uid = doc.id;

              final fullName =
                  (d["full_name"] ?? "Usuario sin nombre").toString();
              final email = (d["email"] ?? "").toString();
              final reason = (d["reverification_reason"] ??
                      d["blocked_reason"] ??
                      "Cambio de datos / verificación requerida")
                  .toString();

              final date = _formatDate(
                  (d["updated_at"] ?? d["created_at"]) as Timestamp?);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(email,
                        style:
                            const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text("Motivo: $reason",
                        style: const TextStyle(
                            color: Colors.orangeAccent)),
                    Text("Última actualización: $date",
                        style:
                            const TextStyle(color: Colors.white38)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _approveUser(context, uid),
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            label: const Text("Aprobar",
                                style:
                                    TextStyle(color: Colors.green)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectUser(context, uid),
                            icon: const Icon(Icons.cancel,
                                color: Colors.redAccent),
                            label: const Text("Rechazar",
                                style: TextStyle(
                                    color: Colors.redAccent)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
