import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Registrar usuario
  Future<User?> register(String email, String password, String fullName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _db.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "email": email,
          "full_name": fullName,
          "created_at": FieldValue.serverTimestamp(),

          // 🔥 SISTEMA DE MEMBRESÍAS
          "membership": "reporter",
          "membership_plan": "free",
          "membership_active": false,

          // 🔥 VEHÍCULOS
          "vehicles_count": 0,

          // 🔥 RECOMPENSAS
          "rewards_balance": 0,

          // 🔥 SISTEMA DE BLOQUEOS
          "blocked": false,
          "blocked_date": null,

          // ⭐⭐⭐ NUEVOS CAMPOS SKANO (progreso del usuario) ⭐⭐⭐
          "reportes_enviados": 0,
          "reportes_acertados": 0,
          "xp_points": 0,
          "level": "bronce",
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Login
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // 🔹 Escuchar cambios de auth
  Stream<User?> authState() => _auth.authStateChanges();
}
