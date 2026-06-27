import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCompanyRequestsScreen extends StatelessWidget {
  const AdminCompanyRequestsScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color neonGreen = Color(0xFF22C55E);
  static const Color neonRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        title: const Text('Solicitudes de Empresas'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('company_requests')
            .where('status', isEqualTo: 'pending') // 🔴 CLAVE
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: neonBlue),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay solicitudes pendientes',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF141821),
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(data['companyName']),
                      const SizedBox(height: 8),
                      _info('RUT', data['rut']),
                      _info('Correo', data['email']),
                      _info(
                        'Ubicación',
                        '${data['region'] ?? '-'} / ${data['comuna'] ?? '-'}',
                      ),
                      _info(
                        'Tipo empresa',
                        _mapSystemType(data['systemType']),
                      ),
                      _info('Flota estimada', '${data['fleetSize'] ?? '-'}'),
                      _info('Contacto', data['contactName']),
                      _info('Teléfono', data['contactPhone']),
                      _info('Uso declarado', data['useCase']),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: neonGreen,
                              ),
                              onPressed: () async {
                                await _approveAndCreateCompany(doc.id, data);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Empresa aprobada correctamente'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: const Text('APROBAR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: neonRed,
                              ),
                              onPressed: () async {
                                await _rejectRequest(doc.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Solicitud rechazada'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              child: const Text('RECHAZAR'),
                            ),
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

  // ================= UI HELPERS =================

  Widget _title(String? text) {
    return Text(
      text?.isNotEmpty == true ? text! : 'Empresa sin nombre',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value?.isNotEmpty == true ? value : '-'}',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  String _mapSystemType(String? type) {
    switch (type) {
      case 'fleet':
        return 'Flota privada';
      case 'security':
        return 'Empresa de seguridad';
      case 'municipality':
        return 'Municipalidad';
      default:
        return 'Otro';
    }
  }

  // ================= CORE LOGIC =================

  Future<void> _approveAndCreateCompany(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final firestore = FirebaseFirestore.instance;
    late String companyId;

    await firestore.runTransaction((tx) async {
      final companyRef = firestore.collection('companies').doc();
      companyId = companyRef.id;

      tx.set(companyRef, {
        'companyName': data['companyName'],
        'rut': data['rut'],
        'region': data['region'],
        'comuna': data['comuna'],
        'systemType': data['systemType'],
        'fleetSize': data['fleetSize'],
        'useCase': data['useCase'],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(
        firestore.collection('company_requests').doc(requestId),
        {
          'status': 'approved',
          'reviewed': true,
          'reviewedAt': FieldValue.serverTimestamp(),
          'companyId': companyId,
        },
      );
    });
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('company_requests')
        .doc(requestId)
        .update({
      'status': 'rejected',
      'reviewed': true,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
