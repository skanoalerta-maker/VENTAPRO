import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Obtener datos de usuario
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Actualizar datos
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection("users").doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Marcar usuario como bloqueado
  Future<void> blockUser(String uid) async {
    await _db.collection("users").doc(uid).update({
      "blocked": true,
      "blocked_date": DateTime.now(),
    });
  }

  // 🔹 Reactivar usuario (admin / manual)
  Future<void> unblockUser(String uid) async {
    await _db.collection("users").doc(uid).update({
      "blocked": false,
      "blocked_date": null,
    });
  }
}
