import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color bg = Color(0xFF080B12);
  static const Color card = Color(0xFF111722);
  static const Color card2 = Color(0xFF0C111A);
  static const Color neonBlue = Color(0xFF0A6CFF);

  final TextEditingController searchCtrl = TextEditingController();

  String search = "";
  String filter = "all";

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

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

  String _status(Map<String, dynamic> d) {
    final verification = _safe(d["verification_status"]);
    final documentStatus = _safe(d["documentStatus"]);

    if (verification.isNotEmpty) return verification;
    if (documentStatus.isNotEmpty) return documentStatus;
    return "draft";
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case "approved":
      case "verified":
        return "APROBADO";
      case "pending":
      case "pending_review":
        return "EN REVISIÓN";
      case "rejected":
        return "RECHAZADO";
      case "draft":
        return "BORRADOR";
      default:
        return "SIN ESTADO";
    }
  }

  Color _statusColor(String status, bool blocked) {
    if (blocked) return Colors.redAccent;

    switch (status.toLowerCase()) {
      case "approved":
      case "verified":
        return Colors.greenAccent;
      case "pending":
      case "pending_review":
        return Colors.orangeAccent;
      case "rejected":
        return Colors.redAccent;
      case "draft":
        return Colors.white54;
      default:
        return neonBlue;
    }
  }

  bool _matchesSearch(DocumentSnapshot doc) {
    if (search.trim().isEmpty) return true;

    final d = doc.data() as Map<String, dynamic>;
    final q = search.trim().toLowerCase();

    final values = [
      doc.id,
      d["full_name"],
      d["fullName"],
      d["email"],
      d["nationalId"],
      d["rut"],
      d["rut_normalized"],
      d["phone"],
      d["comuna"],
    ].map((e) => _safe(e).toLowerCase()).join(" ");

    return values.contains(q);
  }

  bool _matchesFilter(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final status = _status(d).toLowerCase();
    final blocked = d["blocked"] == true;

    switch (filter) {
      case "approved":
        return status == "approved" || status == "verified";
      case "pending":
        return status == "pending" ||
            status == "pending_review" ||
            d["reviewPending"] == true;
      case "blocked":
        return blocked;
      case "rejected":
        return status == "rejected";
      default:
        return true;
    }
  }

  int _countWhere(List<QueryDocumentSnapshot> docs, bool Function(Map<String, dynamic>) test) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return test(d);
    }).length;
  }

  Widget _header(List<QueryDocumentSnapshot> docs) {
    final approved = _countWhere(docs, (d) {
      final s = _status(d).toLowerCase();
      return s == "approved" || s == "verified";
    });

    final pending = _countWhere(docs, (d) {
      final s = _status(d).toLowerCase();
      return s == "pending" || s == "pending_review" || d["reviewPending"] == true;
    });

    final blocked = _countWhere(docs, (d) => d["blocked"] == true);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF151B26), Color(0xFF0C111A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: neonBlue.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: neonBlue.withOpacity(0.14),
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
                  color: neonBlue.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: neonBlue.withOpacity(0.65)),
                ),
                child: const Icon(Icons.groups_2_outlined, color: neonBlue, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Centro de usuarios SKANO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${docs.length} usuarios registrados en la app",
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _statCard("Aprobados", approved.toString(), Icons.verified_user_outlined, Colors.greenAccent),
            const SizedBox(width: 10),
            _statCard("Pendientes", pending.toString(), Icons.pending_actions_outlined, Colors.orangeAccent),
            const SizedBox(width: 10),
            _statCard("Bloqueados", blocked.toString(), Icons.block_outlined, Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [card, card2]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 9),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: (v) => setState(() => search = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Buscar nombre, correo, RUT o UID...",
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      searchCtrl.clear();
                      setState(() => search = "");
                    },
                  ),
            filled: true,
            fillColor: card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: neonBlue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _filterChip("all", "Todos"),
            const SizedBox(width: 8),
            _filterChip("approved", "Aprobados"),
            const SizedBox(width: 8),
            _filterChip("pending", "Pendientes"),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _filterChip("blocked", "Bloqueados"),
            const SizedBox(width: 8),
            _filterChip("rejected", "Rechazados"),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = filter == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => filter = value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? neonBlue.withOpacity(0.22) : card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? neonBlue : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
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

  Widget _userCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final name = _safe(d["full_name"] ?? d["fullName"]);
    final email = _safe(d["email"]);
    final rut = _safe(d["nationalId"] ?? d["rut"] ?? d["rut_normalized"]);
    final blocked = d["blocked"] == true;
    final membershipActive = d["membership_active"] == true;
    final status = _status(d);
    final color = _statusColor(status, blocked);

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
        border: Border.all(color: color.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.16),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Icon(Icons.person_outline, color: color, size: 32)
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
                        email,
                        style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "UID: ${_shortUid(doc.id)}",
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(_statusLabel(status), color),
                if (blocked) _badge("BLOQUEADO", Colors.redAccent),
                _badge(
                  membershipActive ? "MEMBRESÍA ACTIVA" : "SIN MEMBRESÍA",
                  membershipActive ? Colors.greenAccent : Colors.white38,
                ),
              ],
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
                  _miniInfo(Icons.calendar_today_outlined, "Creado", _formatDate(d["created_at"])),
                  _miniInfo(Icons.verified_outlined, "Verificación", status),
                  _miniInfo(Icons.description_outlined, "Documentos", _safe(d["documentStatus"])),
                ],
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/admin_review_user",
                    arguments: doc.id,
                  );
                },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text(
                  "REVISAR USUARIO",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.white,
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

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.groups_outlined, color: Colors.white.withOpacity(0.25), size: 62),
            const SizedBox(height: 14),
            Text(
              text,
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Usuarios",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .orderBy("created_at", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  "Error al cargar usuarios\n${snap.error}",
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

          final allDocs = snap.data!.docs;

          if (allDocs.isEmpty) {
            return _emptyState("No hay usuarios registrados");
          }

          final docs = allDocs.where((doc) {
            return _matchesSearch(doc) && _matchesFilter(doc);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(allDocs),
              const SizedBox(height: 16),
              _searchAndFilters(),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                _emptyState("No encontramos usuarios con ese filtro"),
              ...docs.map(_userCard),
            ],
          );
        },
      ),
    );
  }
}
