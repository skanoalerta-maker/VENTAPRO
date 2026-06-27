import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_review_report_screen.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  // ===================================================
  // APROBAR REPORTE (CON LÓGICA COMPLETA)
  // ===================================================
  Future<void> _approveReport(
    BuildContext context,
    QueryDocumentSnapshot r,
  ) async {
    final ok = await _confirm(
      context,
      title: "Aprobar reporte",
      message:
          "El reporte será aprobado. El pago se realiza desde la revisión completa.",
    );
    if (!ok) return;

    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    final reportRef =
        FirebaseFirestore.instance.collection("reports").doc(r.id);

    final reportSnap = await reportRef.get();
    final report = reportSnap.data() as Map<String, dynamic>;

    // 🔒 EVITAR DUPLICADOS
    if (report["reward_counted"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este reporte ya fue contado")),
      );
      return;
    }

    final reporterUid = report["reporter_uid"];

    // 1. APROBAR REPORTE
    await reportRef.update({
      "status": "approved",
      "reviewedAt": now,
      "reviewedBy": adminUid,
      "reward_status": "pending",
      "reward_counted": true,
    });

    // 2. BUSCAR USUARIO QUE REPORTÓ
    final reporterRef =
        FirebaseFirestore.instance.collection("users").doc(reporterUid);

    final reporterSnap = await reporterRef.get();
    final reporterData = reporterSnap.data();

    final invitedByUid = reporterData?["invitedByUid"];

    // 3. SUMAR AL INVITADOR
    if (invitedByUid != null && invitedByUid != "") {
      final inviterRef =
          FirebaseFirestore.instance.collection("users").doc(invitedByUid);

      final inviterSnap = await inviterRef.get();
      final inviterData = inviterSnap.data();

      int currentReports =
          (inviterData?["referralStats"]?["validReports"] ?? 0);

      int goal = (inviterData?["referralStats"]?["goal"] ?? 5);

      int newTotal = currentReports + 1;

      Map<String, dynamic> updateData = {
        "referralStats.validReports": FieldValue.increment(1),
      };

      // 🎯 SI CUMPLE META
      if (newTotal >= goal) {
        updateData.addAll({
          "referralStats.rewardEnabled": true,
          "referralStats.cycleCompleted": true,
          "cycleCount": FieldValue.increment(1),
          "lastRewardAt": FieldValue.serverTimestamp(),
        });
      }

      await inviterRef.update(updateData);
    }

    // LOG ADMIN
    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "report_approved",
      "adminUid": adminUid,
      "targetCollection": "reports",
      "targetId": r.id,
      "createdAt": now,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte aprobado y contabilizado")),
      );
    }
  }

  // ===================================================
  // RECHAZAR REPORTE
  // ===================================================
  Future<void> _rejectReport(
    BuildContext context,
    QueryDocumentSnapshot r,
  ) async {
    final reason = await _askReason(context);
    if (reason == null || reason.isEmpty) return;

    final adminUid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    final data = (r.data() as Map<String, dynamic>? ?? {});
    final plate = (data["plate"] ?? "-").toString();

    await FirebaseFirestore.instance.collection("reports").doc(r.id).update({
      "status": "rejected",
      "reviewedAt": now,
      "reviewedBy": adminUid,
      "admin_comment": reason,
    });

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": "report_rejected",
      "adminUid": adminUid,
      "targetCollection": "reports",
      "targetId": r.id,
      "createdAt": now,
      "details": {
        "plate": plate,
        "reason": reason,
      },
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte rechazado")),
      );
    }
  }

  // ===================================================
  // UI
  // ===================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Reportes pendientes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .where("status", isEqualTo: "pending")
            .orderBy("created_at", descending: true)
            .snapshots(),
        builder: (_, snap) {
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

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay reportes pendientes",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = docs[i];
              final d = (r.data() as Map<String, dynamic>? ?? {});

              final plate = (d["plate"] ?? "-").toString();
              final uid = (d["uid"] ?? "-").toString();

              final Timestamp? ts = d["created_at"] as Timestamp?;
              final date = ts?.toDate();

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminReviewReportScreen(reportId: r.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Reportado por: $uid",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Fecha: ${date ?? "-"}",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: "Aprobar",
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => _approveReport(context, r),
                          ),
                          IconButton(
                            tooltip: "Rechazar",
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _rejectReport(context, r),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===================================================
  // HELPERS
  // ===================================================
  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.black,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message,
                style: const TextStyle(color: Colors.white70)),
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

  static Future<String?> _askReason(BuildContext context) async {
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
}