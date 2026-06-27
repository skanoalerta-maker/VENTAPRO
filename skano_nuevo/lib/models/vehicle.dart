class Vehicle {
  // =============================
  // Identidad
  // =============================
  final String id;
  final String ownerUid;

  // =============================
  // Datos del vehículo
  // =============================
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String type;
  final String? photoUrl;

  // =============================
  // Estado operativo
  // =============================
  final String status;
  final bool verified;
  final bool active;

  // =============================
  // Membresía
  // =============================
  final bool membershipRequired;
  final bool membershipActive;
  final DateTime? membershipUntil;

  Vehicle({
    required this.id,
    required this.ownerUid,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
    this.photoUrl,
    required this.status,
    required this.verified,
    required this.active,
    required this.membershipRequired,
    required this.membershipActive,
    this.membershipUntil,
  });

  // =================================================
  // 🔁 copyWith (usado por VehicleDetailScreen)
  // =================================================
  Vehicle copyWith({
    String? id,
    String? ownerUid,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? type,
    String? photoUrl,
    String? status,
    bool? verified,
    bool? active,
    bool? membershipRequired,
    bool? membershipActive,
    DateTime? membershipUntil,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      type: type ?? this.type,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      active: active ?? this.active,
      membershipRequired:
          membershipRequired ?? this.membershipRequired,
      membershipActive:
          membershipActive ?? this.membershipActive,
      membershipUntil:
          membershipUntil ?? this.membershipUntil,
    );
  }

  // =================================================
  // 🔄 Firestore → Vehicle
  // =================================================
  factory Vehicle.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Vehicle(
      id: id,
      ownerUid: data['owner_uid'] ?? '',
      plate: data['plate'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      year: (data['year'] ?? 0) is int
          ? data['year']
          : int.tryParse('${data['year']}') ?? 0,
      color: data['color'] ?? '',
      type: data['type'] ?? '',
      photoUrl: data['vehicle_photo_url'],
      status: data['status'] ?? 'draft',
      verified: data['verified'] ?? false,
      active: data['active'] ?? false,
      membershipRequired:
          data['membership_required'] ?? true,
      membershipActive:
          data['membership_active'] ?? false,
      membershipUntil: data['membership_until'] != null
          ? (data['membership_until'] as dynamic).toDate()
          : null,
    );
  }

  // =================================================
  // 🔁 COMPATIBILIDAD (tu error actual)
  // =================================================
  /// Vehicle.fromMap() ES USADO EN vehicle_detail_screen.dart
  /// Este método es solo un alias limpio
  factory Vehicle.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return Vehicle.fromFirestore(id, data);
  }

  // =================================================
  // 🔄 Vehicle → Firestore
  // =================================================
  Map<String, dynamic> toFirestore() {
    return {
      'owner_uid': ownerUid,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'type': type,
      'vehicle_photo_url': photoUrl,
      'status': status,
      'verified': verified,
      'active': active,
      'membership_required': membershipRequired,
      'membership_active': membershipActive,
      'membership_until': membershipUntil,
    };
  }
}
