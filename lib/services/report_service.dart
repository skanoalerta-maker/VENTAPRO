import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createReport(String uid, Map<String, dynamic> data) async {
    final ref = _db.collection('reports').doc();
    final now = FieldValue.serverTimestamp();

    await ref.set({
      'report_id': ref.id,
      'uid': uid,               // ✅ obligatorio
      'reporter_uid': uid,      // ✅ compatibilidad

      'status': 'draft',
      'admin_review_pending': true,
      'admin_status': 'pending',

      'created_at': now,
      ...data,
    });
  }

  Stream<QuerySnapshot> getUserReports(String uid) {
    return _db.collection('reports').where('uid', isEqualTo: uid).snapshots();
  }
}