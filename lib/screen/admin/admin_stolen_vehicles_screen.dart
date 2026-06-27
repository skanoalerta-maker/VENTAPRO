import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  bool _sendingRecoveryCheckEmails = false;

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

  int _countRecoveryEmails(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return d['recovery_check_email_sent_at'] is Timestamp ||
          d['last_recovery_check_email_sent_at'] is Timestamp;
    }).length;
  }

  String _lastRecoveryEmailDate(List<QueryDocumentSnapshot> docs) {
    final dates = <Timestamp>[];

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;

      final a = d['recovery_check_email_sent_at'];
      final b = d['last_recovery_check_email_sent_at'];

      if (a is Timestamp) dates.add(a);
      if (b is Timestamp) dates.add(b);
    }

    if (dates.isEmpty) return 'Sin envíos';

    dates.sort((a, b) => b.compareTo(a));

    return _formatDate(dates.first);
  }

  Future<void> _generateExternalAsStolen({
    required String externalId,
    required Map<String, dynamic> data,
  }) async {
    final plate = (data['plate'] ?? externalId).toString().toUpperCase();
    final adminUid = FirebaseAuth.instance.currentUser?.uid;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final stolenRef = db.collection('stolen_vehicles').doc(plate);
    final externalRef = db.collection('external_stolen_vehicles').doc(externalId);
    final logRef = db.collection('admin_logs').doc();

    batch.set(stolenRef, {
      'plate': plate,
      'plate_normalized': plate,
      'status': 'stolen',
      'active': true,

      'brand': data['brand'] ?? '',
      'model': data['model'] ?? '',
      'year': data['year'],
      'color': data['color'] ?? '',

      'ownerName': data['ownerName'] ?? data['owner_name'] ?? '',
      'ownerEmail': data['ownerEmail'] ?? data['owner_email'] ?? '',
      'ownerPhone': data['ownerPhone'] ?? data['owner_phone'] ?? '',

      'comuna': data['comuna'] ?? data['stolen_city'] ?? data['city'] ?? '',
      'region': data['region'] ?? data['stolen_region'] ?? '',
      'stolen_address': data['stolen_address'] ?? '',

      'photoUrl': data['photoUrl'] ?? data['photo_url'] ?? '',
      'photo_url': data['photo_url'] ?? data['photoUrl'] ?? '',

      'source': data['source'] ?? 'EXTERNAL',
      'source_link': data['source_link'] ?? '',
      'case_number': data['case_number'] ?? '',

      'createdAt': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      'external_vehicle': true,
      'external_vehicle_id': externalId,
      'created_from': 'external_stolen_vehicles',
      'generated_by_admin': true,
      'generated_by_admin_uid': adminUid,

      'uploaded_by_skano': true,
      'uploaded_source': 'admin_external_panel',

      'verified': true,
      'verified_vehicle': true,
      'recovered': false,
      'reports_count': 0,
      'views_count': 0,
      'reward_amount': data['reward_amount'] ?? 50000,
    }, SetOptions(merge: true));

    batch.update(externalRef, {
      'published_to_stolen_vehicles': true,
      'published_stolen_vehicle_id': plate,
      'published_at': FieldValue.serverTimestamp(),
      'published_by': adminUid,
      'status': 'published',
      'active': true,
    });

    batch.set(logRef, {
      'action': 'GENERATE_EXTERNAL_AS_STOLEN',
      'adminUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
      'targetCollection': 'stolen_vehicles',
      'targetId': plate,
      'details': {
        'externalId': externalId,
        'plate': plate,
      },
    });

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('Vehículo $plate generado como vehículo con encargo'),
      ),
    );
  }

  Widget _externalPendingSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('external_stolen_vehicles')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final pendingDocs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['published_to_stolen_vehicles'] != true;
        }).toList();

        if (pendingDocs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.35)),
            ),
            child: const Text(
              'No hay vehículos externos pendientes por generar como vehículo con encargo.',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienes ${pendingDocs.length} vehículo(s) externo(s) no publicado(s) como vehículo con encargo.',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ...pendingDocs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final plate = (d['plate'] ?? doc.id).toString().toUpperCase();
                final brand = (d['brand'] ?? '').toString();
                final model = (d['model'] ?? '').toString();
                final photoUrl =
                    (d['photo_url'] ?? d['photoUrl'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photoUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photoUrl,
                            width: double.infinity,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        '$plate · $brand $model',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dueño: ${(d['owner_name'] ?? d['ownerName'] ?? '').toString()}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _generateExternalAsStolen(
                            externalId: doc.id,
                            data: d,
                          ),
                          icon: const Icon(Icons.local_police_outlined),
                          label: const Text(
                            'GENERAR VEHÍCULO CON ENCARGO',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendRecoveryCheckEmails() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101622),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.35)),
        ),
        title: const Text(
          'Enviar correos de seguimiento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Se enviará un correo a los dueños de vehículos robados activos para consultar si el vehículo ya fue recuperado.\n\n¿Deseas continuar?',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.outgoing_mail),
            label: const Text('Enviar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _sendingRecoveryCheckEmails = true);

      final result = await FirebaseFunctions.instance
          .httpsCallable('sendActiveStolenVehicleCheckEmails')
          .call({'limit': 50});

      final data = result.data as Map?;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Correos enviados: ${data?['sent'] ?? 0} | '
            'Errores: ${data?['failed'] ?? 0} | '
            'Revisados: ${data?['checked'] ?? 0}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error enviando correos: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingRecoveryCheckEmails = false);
    }
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent),
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

    final vehicleRef =
        FirebaseFirestore.instance.collection('stolen_vehicles').doc(vehicleId);

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
          gradient: const LinearGradient(colors: [_card, _card2]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
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
    final recoveryEmails = _countRecoveryEmails(docs);
    final lastEmailDate = _lastRecoveryEmailDate(docs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF151A24), Color(0xFF090B10)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_police_outlined,
                  color: Colors.redAccent, size: 38),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Centro de monitoreo SKANO\nVehículos robados activos y reportados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
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
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blue.withOpacity(0.35)),
          ),
          child: Text(
            'Correos de seguimiento enviados: $recoveryEmails | Último envío: $lastEmailDate',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                _sendingRecoveryCheckEmails ? null : _sendRecoveryCheckEmails,
            icon: _sendingRecoveryCheckEmails
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.outgoing_mail),
            label: Text(
              _sendingRecoveryCheckEmails
                  ? 'Enviando correos...'
                  : 'ENVIAR CORREO: ¿FUE RECUPERADO?',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
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
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
        children: [
          Icon(icon, color: Colors.white38, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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

final photoUrl = (
  d['vehicle_photo_url'] ??
  d['photoUrl'] ??
  d['photo_url'] ??
  d['imageUrl'] ??
  ''
).toString();

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
          colors: [Color(0xFF171D29), Color(0xFF0D111A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.42)),
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
                    errorBuilder: (_, error, stack) {
                      debugPrint('ERROR FOTO VEHICULO ROBADO: $photoUrl');
                      debugPrint(error.toString());

                      return Container(
                        height: 178,
                        width: double.infinity,
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.redAccent,
                            size: 42,
                          ),
                        ),
                      );
                    },
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
                        _infoRow(
                          Icons.email_outlined,
                          'Último correo consulta',
                          _formatDate(
                            d['recovery_check_email_sent_at'] ??
                                d['last_recovery_check_email_sent_at'],
                          ),
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
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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

  Widget _stolenVehiclesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stolen_vehicles')
          .where('status', whereIn: ['stolen', 'reported']).snapshots(),
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

        final allDocs = snap.data?.docs ?? [];

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
            _externalPendingSection(),
            const SizedBox(height: 16),
            _searchAndFilters(),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              _emptyState('No encontramos vehículos con ese filtro'),
            ...docs.map(_vehicleCard),
          ],
        );
      },
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
      body: _stolenVehiclesList(),
    );
  }
}