import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear reporte
  Future<void> createReport(String uid, Map<String, dynamic> data) async {
    String rid = _db.collection('reports').doc().id;

    await _db.collection('reports').doc(rid).set({
      'report_id': rid,
      'reporter_uid': uid,
      ...data,
      'created_at': DateTime.now(),
      'verified': false,
    });
  }

  // Obtener reportes del usuario
  Stream<QuerySnapshot> getUserReports(String uid) {
    return _db
        .collection('reports')
        .where('reporter_uid', isEqualTo: uid)
        .snapshots();
  }

  // Verificar reporte (solo admins)
  Future<void> verifyReport(String rid) async {
    await _db.collection('reports').doc(rid).update({
      'verified': true,
      'verified_at': DateTime.now(),
    });
  }
}
