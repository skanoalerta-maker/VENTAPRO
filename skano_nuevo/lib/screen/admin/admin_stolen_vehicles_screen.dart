import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminStolenVehiclesScreen extends StatefulWidget {
  const AdminStolenVehiclesScreen({super.key});

  @override
  State<AdminStolenVehiclesScreen> createState() =>
      _AdminStolenVehiclesScreenState();
}

class _AdminStolenVehiclesScreenState extends State<AdminStolenVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String _search = '';
  String _statusFilter = 'all';

  static const Color _bg = Color(0xFF080B12);
  static const Color _card = Color(0xFF111722);
  static const Color _card2 = Color(0xFF0C111A);
  static const Color _blue = Color(0xFF0A6CFF);

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'stolen':
        return Colors.redAccent;
      case 'reported':
        return Colors.orangeAccent;
      case 'recovered':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'stolen':
        return 'ROBADO ACTIVO';
      case 'reported':
        return 'REPORTADO';
      case 'recovered':
        return 'RECUPERADO';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'Sin fecha';
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    }
    return 'Sin fecha';
  }

  bool _matchesSearch(Map<String, dynamic> d) {
    if (_search.trim().isEmpty) return true;

    final q = _search.toLowerCase().trim();

    final values = [
      d['plate'],
      d['brand'],
      d['model'],
      d['color'],
      d['ownerName'],
      d['ownerEmail'],
      d['ownerPhone'],
      d['comuna'],
      d['region'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return values.contains(q);
  }

  bool _matchesFilter(Map<String, dynamic> d) {
    if (_statusFilter == 'all') return true;
    return (d['status'] ?? '').toString() == _statusFilter;
  }

  int _countByStatus(List<QueryDocumentSnapshot> docs, String status) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return (d['status'] ?? '').toString() == status;
    }).length;
  }

  Future<void> _confirmRecovered({
    required BuildContext context,
    required String vehicleId,
    required String plate,
    required String previousStatus,
  }) async {
    _reasonController.clear();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101622),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.greenAccent.withOpacity(0.35)),
          ),
          title: const Text(
            'Confirmar recuperación',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vas a marcar la patente $plate como RECUPERADA.\n\nEsta acción cambiará el estado del vehículo y quedará registrada en auditoría.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Motivo / nota administrativa...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.greenAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    final reason = _reasonController.text.trim();

    final batch = FirebaseFirestore.instance.batch();

    final vehicleRef = FirebaseFirestore.instance
        .collection('stolen_vehicles')
        .doc(vehicleId);

    final logRef = FirebaseFirestore.instance.collection('admin_logs').doc();

    batch.update(vehicleRef, {
      'status': 'recovered',
      'active': false,
      'recoveredAt': FieldValue.serverTimestamp(),
      'recoveredBy': adminUid,
      'recoveredReason': reason.isEmpty ? 'Sin motivo informado' : reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(logRef, {
      'action': 'MARK_STOLEN_VEHICLE_RECOVERED',
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
      'targetCollection': 'stolen_vehicles',
      'targetId': vehicleId,
      'details': {
        'plate': plate,
        'previousStatus': previousStatus,
        'newStatus': 'recovered',
        'reason': reason.isEmpty ? 'Sin motivo informado' : reason,
      },
    });

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('Vehículo $plate marcado como recuperado'),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_card, _card2],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(List<QueryDocumentSnapshot> docs) {
    final stolen = _countByStatus(docs, 'stolen');
    final reported = _countByStatus(docs, 'reported');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF151A24),
                Color(0xFF090B10),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.12),
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
                  color: Colors.redAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.7)),
                ),
                child: const Icon(
                  Icons.local_police_outlined,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de monitoreo SKANO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vehículos robados activos y reportados por la comunidad',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
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
            _statCard(
              icon: Icons.car_crash_outlined,
              title: 'Robados',
              value: stolen.toString(),
              color: Colors.redAccent,
            ),
            const SizedBox(width: 10),
            _statCard(
              icon: Icons.report_problem_outlined,
              title: 'Reportados',
              value: reported.toString(),
              color: Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            _statCard(
              icon: Icons.security_outlined,
              title: 'Total activo',
              value: docs.length.toString(),
              color: _blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar patente, dueño, correo, marca o comuna...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                  ),
            filled: true,
            fillColor: _card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _blue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _filterChip('all', 'Todos'),
            const SizedBox(width: 8),
            _filterChip('stolen', 'Robados'),
            const SizedBox(width: 8),
            _filterChip('reported', 'Reportados'),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _statusFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _statusFilter = value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _blue.withOpacity(0.22) : _card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _blue : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'stolen'
                ? Icons.warning_amber_rounded
                : Icons.report_problem_outlined,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty || value == 'Sin fecha') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  TextSpan(
                    text: value,
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

  Widget _vehicleCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final status = (d['status'] ?? 'stolen').toString();
    final plate = (d['plate'] ?? 'SIN PATENTE').toString().toUpperCase();
    final brand = (d['brand'] ?? '').toString();
    final model = (d['model'] ?? '').toString();
    final year = (d['year'] ?? '').toString();
    final vehicleColor = (d['color'] ?? '').toString();
    final statusColor = _statusColor(status);

    final photoUrl =
        (d['vehicle_photo_url'] ?? d['photoUrl'] ?? d['imageUrl'] ?? '')
            .toString();

    final vehicleLine = [
      brand,
      model,
      year,
      vehicleColor,
    ].where((e) => e.trim().isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF171D29),
            Color(0xFF0D111A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.13),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    photoUrl,
                    width: double.infinity,
                    height: 178,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _statusBadge(status),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl.isEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _statusBadge(status),
                    ),
                  Text(
                    plate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                  if (vehicleLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      vehicleLine,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          Icons.person_outline,
                          'Dueño',
                          (d['ownerName'] ?? '').toString(),
                        ),
                        _infoRow(
                          Icons.email_outlined,
                          'Correo',
                          (d['ownerEmail'] ?? '').toString(),
                        ),
                        _infoRow(
                          Icons.phone_outlined,
                          'Teléfono',
                          (d['ownerPhone'] ?? '').toString(),
                        ),
                        _infoRow(
                          Icons.location_on_outlined,
                          'Comuna',
                          (d['comuna'] ?? '').toString(),
                        ),
                        _infoRow(
                          Icons.schedule,
                          'Creado',
                          _formatDate(d['createdAt']),
                        ),
                        _infoRow(
                          Icons.flag_outlined,
                          'Estado interno',
                          status,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmRecovered(
                        context: context,
                        vehicleId: doc.id,
                        plate: plate,
                        previousStatus: status,
                      ),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text(
                        'MARCAR COMO RECUPERADO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_filled_outlined,
              color: Colors.white.withOpacity(0.25),
              size: 60,
            ),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Vehículos robados',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stolen_vehicles')
            .where('status', whereIn: ['stolen', 'reported'])
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Error al cargar vehículos robados\n${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _blue),
            );
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState('No hay vehículos robados activos');
          }

          final allDocs = snap.data!.docs;

          final docs = allDocs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _matchesSearch(d) && _matchesFilter(d);
          }).toList();

          docs.sort((a, b) {
            final da = a.data() as Map<String, dynamic>;
            final db = b.data() as Map<String, dynamic>;
            final ta = da['createdAt'];
            final tb = db['createdAt'];

            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return 0;
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(allDocs),
              const SizedBox(height: 16),
              _searchAndFilters(),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                _emptyState('No encontramos vehículos con ese filtro'),
              ...docs.map(_vehicleCard),
            ],
          );
        },
      ),
    );
  }
}