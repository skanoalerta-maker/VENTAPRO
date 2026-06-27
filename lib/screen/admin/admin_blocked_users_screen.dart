import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminBlockedUsersScreen extends StatefulWidget {
  const AdminBlockedUsersScreen({super.key});

  @override
  State<AdminBlockedUsersScreen> createState() =>
      _AdminBlockedUsersScreenState();
}

class _AdminBlockedUsersScreenState extends State<AdminBlockedUsersScreen> {
  String _formatDate(Timestamp ts) {
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  final Set<String> _processing = {};

  Future<void> _unlockUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Desbloquear usuario",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Seguro que deseas desbloquear a:\n\n"
          "${data['full_name'] ?? 'Usuario'}\n"
          "${data['email'] ?? ''}\n\n"
          "Motivo actual:\n${data['blocked_reason'] ?? '-'}",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Desbloquear"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _processing.add(userId));

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? "";

      // ✅ DESBLOQUEO CORRECTO SKANO
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "blocked": false,
        "blocked_reason": null,
        "blocked_until": null,

        // 🔁 limpieza mínima (no forzamos verificación)
        "identity_change_pending": false,

        "updated_at": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "user_unblocked",
        "adminUid": adminUid,
        "targetCollection": "users",
        "targetId": userId,
        "createdAt": FieldValue.serverTimestamp(),
        "details": {
          "email": data["email"] ?? "",
          "previous_reason": data["blocked_reason"] ?? "",
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario desbloqueado")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error desbloqueando: $e")),
      );
    } finally {
      if (mounted) setState(() => _processing.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Usuarios bloqueados",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('blocked', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay usuarios bloqueados",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white24),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final isBusy = _processing.contains(doc.id);

              return ListTile(
                leading: const Icon(Icons.lock, color: Colors.redAccent),
                title: Text(
                  data['full_name'] ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  data['email'] ?? '',
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: isBusy
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : OutlinedButton(
                        onPressed: () => _unlockUser(
                          userId: doc.id,
                          data: data,
                        ),
                        child: const Text("Desbloquear"),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
