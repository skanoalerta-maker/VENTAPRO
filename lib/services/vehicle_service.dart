import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Agregar vehículo
  Future<String> addVehicle(Map<String, dynamic> data) async {
    try {
      final ref = await _db.collection("vehicles").add(data);
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Obtener vehículos por usuario
  Stream<List<Map<String, dynamic>>> getUserVehicles(String uid) {
    return _db
        .collection("vehicles")
        .where("owner_uid", isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList());
  }

  // 🔹 Actualizar vehículo
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    await _db.collection("vehicles").doc(id).update(data);
  }

  // 🔹 Eliminar vehículo
  Future<void> deleteVehicle(String id) async {
    await _db.collection("vehicles").doc(id).delete();
  }

  // 🔹 Obtener vehículo por ID
  Future<Map<String, dynamic>?> getVehicle(String id) async {
    final doc = await _db.collection("vehicles").doc(id).get();
    return doc.data();
  }
}
