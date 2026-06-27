import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminReviewReportScreen extends StatefulWidget {
  final String reportId;
  const AdminReviewReportScreen({super.key, required this.reportId});

  @override
  State<AdminReviewReportScreen> createState() =>
      _AdminReviewReportScreenState();
}

class _AdminReviewReportScreenState extends State<AdminReviewReportScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);

  bool working = false;

  Future<void> _approve() async {
    if (working) return;
    setState(() => working = true);

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      if (mounted) setState(() => working = false);
      return;
    }

    final now = FieldValue.serverTimestamp();

    try {
      final ref = FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId);

      final snap = await ref.get();
      final report = snap.data() as Map<String, dynamic>? ?? {};

      if (report["reward_counted"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este reporte ya fue contado")),
        );
        return;
      }

      final reporterUid = (report["reporter_uid"] ?? report["uid"] ?? "")
          .toString()
          .trim();

      await ref.update({
        "admin_status": "approved",
        "admin_review_pending": false,
        "admin_reviewed_at": now,
        "admin_reviewed_by": adminUid,
        "status": "approved",
        "reviewedAt": now,
        "reviewedBy": adminUid,
        "reward_status": "pending",
        "reward_counted": true,
      });

      if (reporterUid.isNotEmpty) {
        final reporterRef =
            FirebaseFirestore.instance.collection("users").doc(reporterUid);

        final reporterSnap = await reporterRef.get();
        final reporterData = reporterSnap.data();

        final invitedByUid =
            (reporterData?["invitedByUid"] ?? "").toString().trim();

        if (invitedByUid.isNotEmpty) {
          final inviterRef =
              FirebaseFirestore.instance.collection("users").doc(invitedByUid);

          final inviterSnap = await inviterRef.get();
          final inviterData = inviterSnap.data();

          final referralStats =
              inviterData?["referralStats"] as Map<String, dynamic>? ?? {};

          final int currentReports =
              (referralStats["validReports"] as num?)?.toInt() ?? 0;

          final int goal = (referralStats["goal"] as num?)?.toInt() ?? 5;

          final int newTotal = currentReports + 1;

          final Map<String, dynamic> updateData = {
            "referralStats.validReports": FieldValue.increment(1),
          };

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
      }

      await FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "report_approved",
        "adminUid": adminUid,
        "targetCollection": "reports",
        "targetId": widget.reportId,
        "createdAt": now,
        "details": {
          "reporterUid": reporterUid,
          "reward_counted": true,
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte aprobado y contabilizado")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _reject(String reason) async {
    if (working) return;
    setState(() => working = true);

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) {
      if (mounted) setState(() => working = false);
      return;
    }

    final now = FieldValue.serverTimestamp();

    try {
      final ref = FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId);

      await ref.update({
        "admin_status": "rejected",
        "admin_review_pending": false,
        "admin_reviewed_at": now,
        "admin_reviewed_by": adminUid,
        "status": "rejected",
        "reviewedAt": now,
        "reviewedBy": adminUid,
        "admin_comment": reason.trim(),
      });

      await FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "report_rejected",
        "adminUid": adminUid,
        "targetCollection": "reports",
        "targetId": widget.reportId,
        "createdAt": now,
        "details": {"reason": reason.trim()},
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte rechazado")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<String?> _askReason() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Revisión de reporte",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .doc(widget.reportId)
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

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text(
                "Reporte no encontrado",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final d = (snap.data!.data() as Map<String, dynamic>?) ?? {};
          final plate = (d["plate"] ?? "-").toString();
          final uid = (d["uid"] ?? d["reporter_uid"] ?? "-").toString();
          final status = (d["status"] ?? "-").toString();
          final adminStatus = (d["admin_status"] ?? "-").toString();
          final rewardCounted = d["reward_counted"] == true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Reportado por: $uid",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Estado: $status",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Admin: $adminStatus",
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Recompensa contada: ${rewardCounted ? "Sí" : "No"}",
                      style: TextStyle(
                        color: rewardCounted
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: working ? null : _approve,
                        icon: const Icon(Icons.check_circle),
                        label: Text(working ? "..." : "APROBAR"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: working
                            ? null
                            : () async {
                                final reason = await _askReason();
                                if (reason == null ||
                                    reason.trim().isEmpty) {
                                  return;
                                }
                                await _reject(reason.trim());
                              },
                        icon: const Icon(Icons.cancel),
                        label: Text(working ? "..." : "RECHAZAR"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}