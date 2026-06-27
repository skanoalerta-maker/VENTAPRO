import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLegalRiskUsersScreen extends StatelessWidget {
  const AdminLegalRiskUsersScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Riesgo legal",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ================= ALERTA SUPERIOR =================
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orangeAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Usuarios con membresía activa sin aceptación de términos.\n\n"
                    "Estos casos representan un riesgo legal y deben "
                    "regularizarse antes de permitir pagos, retiros o renovaciones.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= LISTADO =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("membership_active", isEqualTo: true)
                  .where("membership_terms_accepted", isEqualTo: false) // ✅ FIX
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: neonBlue),
                  );
                }

                if (snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "✅ No existen riesgos legales activos",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snap.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final fullName =
                        data["full_name"] ?? "Usuario sin nombre";
                    final email = data["email"] ?? "";
                    final plan = data["membership_plan"] ?? "—";
                    final uid = doc.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Plan: $plan",
                            style:
                                const TextStyle(color: Colors.orangeAccent),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "UID: $uid",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(uid)
                                        .update({
                                      "membership_terms_required": true, // ✅ Map correcto
                                    });

                                    await _logAdminAction(
                                      action: "force_terms_acceptance",
                                      targetUser: uid,
                                    );
                                  },
                                  child: const Text(
                                    "Forzar aceptación",
                                    style: TextStyle(
                                        color: Colors.orangeAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(uid)
                                        .update({
                                      "membership_active": false, // ✅ Map correcto
                                    });

                                    await _logAdminAction(
                                      action: "suspend_membership",
                                      targetUser: uid,
                                    );
                                  },
                                  child: const Text(
                                    "Suspender",
                                    style:
                                        TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.open_in_new,
                                    color: neonBlue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/admin_review_user",
                                    arguments: uid,
                                  );
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOG ADMIN =================
  static Future<void> _logAdminAction({
    required String action,
    required String targetUser,
  }) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    await FirebaseFirestore.instance.collection("admin_logs").add({
      "action": action,
      "targetId": targetUser,
      "targetCollection": "users",
      "adminUid": adminUid,
      "createdAt": FieldValue.serverTimestamp(),
      "details": "legal_risk_fix",
    });
  }
}
