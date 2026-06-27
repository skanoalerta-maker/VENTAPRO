import 'package:cloud_firestore/cloud_firestore.dart';

/// MODELO PRO-MAX DE USUARIO SKANO
class UserModel {
  final String uid;
  final String email;
  final String fullName;

  /// reporter / owner / admin
  final String membership;

  /// free / owner_basic / owner_premium / empresa
  final String membershipPlan;
  final bool membershipActive;

  /// Saldo acumulado por recompensas
  final num rewardsBalance;

  /// Cantidad de vehículos registrados por este usuario
  final int vehiclesCount;

  /// Cuenta bloqueada por seguridad
  final bool blocked;

  /// Motivo de bloqueo que ve el admin
  final String adminComment;

  /// Fecha en que fue bloqueado (puede ser null)
  final DateTime? blockedAt;

  /// Intentos fallidos de login / verificación
  final int failedAttempts;

  /// DATOS BANCARIOS (para pagar recompensa)
  final String bankName;
  final String accountType; // vista / corriente / rut
  final String accountNumber;
  final String bankDocumentUrl;

  /// DATOS DE IDENTIDAD
  final String nationalId; // RUN/RUT
  final String phone;
  final String idFrontUrl;
  final String idBackUrl;

  /// Selfie y verificación manual
  final String selfieUrl;
  final String verificationStatus; // pending / approved / rejected
  final String verificationLocation; // loc_revision

  /// Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.membership,
    required this.membershipPlan,
    required this.membershipActive,
    required this.rewardsBalance,
    required this.vehiclesCount,
    required this.blocked,
    required this.adminComment,
    required this.blockedAt,
    required this.failedAttempts,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.bankDocumentUrl,
    required this.nationalId,
    required this.phone,
    required this.idFrontUrl,
    required this.idBackUrl,
    required this.selfieUrl,
    required this.verificationStatus,
    required this.verificationLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  /// FACTORY para crear desde Firestore
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      fullName: (data['full_name'] ?? '') as String,
      membership: (data['membership'] ?? 'reporter') as String,
      membershipPlan: (data['membership_plan'] ?? 'free') as String,
      membershipActive: (data['membership_active'] ?? false) as bool,
      rewardsBalance: (data['rewards_balance'] ?? 0) as num,
      vehiclesCount: (data['vehicles_count'] ?? 0) as int,
      blocked: (data['blocked'] ?? false) as bool,
      adminComment: (data['adminComment'] ?? '') as String,
      blockedAt: _fromTimestampOrNull(data['bloqueado_fecha']),
      failedAttempts: (data['intentos_fallidos'] ?? 0) as int,
      bankName: (data['bank_name'] ?? '') as String,
      accountType: (data['account_type'] ?? '') as String,
      accountNumber: (data['account_number'] ?? '') as String,
      bankDocumentUrl: (data['bankDocumentUrl'] ?? '') as String,
      nationalId: (data['nationalId'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      idFrontUrl: (data['idFrontUrl'] ?? '') as String,
      idBackUrl: (data['idBackUrl'] ?? '') as String,
      selfieUrl: (data['selfieUrl'] ?? '') as String,
      verificationStatus:
          (data['verification_status'] ?? 'pending') as String,
      verificationLocation: (data['loc_revision'] ?? '') as String,
      createdAt: _fromTimestampOrNull(data['created_at']),
      updatedAt: _fromTimestampOrNull(data['updated_at']),
    );
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'membership': membership,
      'membership_plan': membershipPlan,
      'membership_active': membershipActive,
      'rewards_balance': rewardsBalance,
      'vehicles_count': vehiclesCount,
      'blocked': blocked,
      'adminComment': adminComment,
      'bloqueado_fecha': blockedAt != null
          ? Timestamp.fromDate(blockedAt!)
          : null,
      'intentos_fallidos': failedAttempts,
      'bank_name': bankName,
      'account_type': accountType,
      'account_number': accountNumber,
      'bankDocumentUrl': bankDocumentUrl,
      'nationalId': nationalId,
      'phone': phone,
      'idFrontUrl': idFrontUrl,
      'idBackUrl': idBackUrl,
      'selfieUrl': selfieUrl,
      'verification_status': verificationStatus,
      'loc_revision': verificationLocation,
      'created_at':
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Crear una copia modificada
  UserModel copyWith({
    String? email,
    String? fullName,
    String? membership,
    String? membershipPlan,
    bool? membershipActive,
    num? rewardsBalance,
    int? vehiclesCount,
    bool? blocked,
    String? adminComment,
    DateTime? blockedAt,
    int? failedAttempts,
    String? bankName,
    String? accountType,
    String? accountNumber,
    String? bankDocumentUrl,
    String? nationalId,
    String? phone,
    String? idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
    String? verificationStatus,
    String? verificationLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      membership: membership ?? this.membership,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      membershipActive: membershipActive ?? this.membershipActive,
      rewardsBalance: rewardsBalance ?? this.rewardsBalance,
      vehiclesCount: vehiclesCount ?? this.vehiclesCount,
      blocked: blocked ?? this.blocked,
      adminComment: adminComment ?? this.adminComment,
      blockedAt: blockedAt ?? this.blockedAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      bankDocumentUrl: bankDocumentUrl ?? this.bankDocumentUrl,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      verificationStatus:
          verificationStatus ?? this.verificationStatus,
      verificationLocation:
          verificationLocation ?? this.verificationLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _fromTimestampOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  return null;
}
