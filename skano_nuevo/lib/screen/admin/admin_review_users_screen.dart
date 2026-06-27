import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'admin_review_user_screen.dart';

class AdminReviewUsersScreen extends StatelessWidget {
  const AdminReviewUsersScreen({super.key});

  static const Color bg = Color(0xFF080B12);
  static const Color card = Color(0xFF111722);
  static const Color card2 = Color(0xFF0C111A);
  static const Color neonBlue = Color(0xFF0A6CFF);

  String _safe(dynamic v) => (v ?? "").toString();

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    }
    return "Sin fecha";
  }

  String _shortUid(String uid) {
    if (uid.length <= 10) return uid;
    return "${uid.substring(0, 8)}...";
  }

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171D29), Color(0xFF0D111A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.65)),
            ),
            child: const Icon(
              Icons.pending_actions_outlined,
              color: Colors.orangeAccent,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Usuarios pendientes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$total usuarios requieren revisión manual",
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(color: Colors.white38, fontSize: 12.5),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final name = _safe(d["full_name"] ?? d["fullName"]);
    final email = _safe(d["email"]);
    final rut = _safe(d["nationalId"] ?? d["rut"] ?? d["rut_normalized"]);
    final phone = _safe(d["phone"]);
    final comuna = _safe(d["comuna"]);
    final documentStatus = _safe(d["documentStatus"]);
    final verificationStatus = _safe(d["verification_status"]);
    final photoUrl = _safe(
      d["faceUrl"] ?? d["identityPhotoUrl"] ?? d["identity_photo_url"],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171D29), Color(0xFF0D111A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminReviewUserScreen(userId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orangeAccent.withOpacity(0.16),
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline,
                            color: Colors.orangeAccent,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? "Usuario sin nombre" : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email.isEmpty ? "Sin correo registrado" : email,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "UID: ${_shortUid(doc.id)}",
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge("EN REVISIÓN", Colors.orangeAccent),
                    if (documentStatus.isNotEmpty)
                      _badge("DOC: ${documentStatus.toUpperCase()}", neonBlue),
                    if (verificationStatus.isNotEmpty)
                      _badge(verificationStatus.toUpperCase(), Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniInfo(Icons.badge_outlined, "RUT", rut),
                    _miniInfo(Icons.phone_outlined, "Teléfono", phone),
                    _miniInfo(Icons.location_on_outlined, "Comuna", comuna),
                    _miniInfo(
                      Icons.calendar_today_outlined,
                      "Creado",
                      _formatDate(d["created_at"]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminReviewUserScreen(userId: doc.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text(
                    "REVISAR Y VALIDAR USUARIO",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Colors.greenAccent.withOpacity(0.75),
              size: 66,
            ),
            const SizedBox(height: 16),
            const Text(
              "No hay usuarios pendientes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Cuando un usuario solicite revisión manual, aparecerá automáticamente en esta sección.",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingUsersStream = FirebaseFirestore.instance
        .collection("users")
        .where("verification_status", isEqualTo: "pending")
        .snapshots();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Usuarios pendientes",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pendingUsersStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error al cargar usuarios pendientes\n${snap.error}",
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
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
            return _emptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(docs.length),
              const SizedBox(height: 16),
              ...docs.map((doc) => _userCard(context, doc)),
            ],
          );
        },
      ),
    );
  }
}