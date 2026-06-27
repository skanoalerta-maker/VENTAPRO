import 'package:cloud_firestore/cloud_firestore.dart';

/// MODELO PRO-MAX DE REPORTE SKANO
class ReportModel {
  final String id; // documentId
  final String vehicleId;
  final String reporterUid;

  /// Tipo de reporte:
  /// stolen_sighting / suspicious / plate_change / other
  final String type;

  /// TEXTO DEL REPORTE
  final String comment;

  /// URL de la foto del vehículo / evidencia
  final String imageUrl;

  /// UBICACIÓN
  final double? lat;
  final double? lng;
  final String city;
  final String address;

  /// ESTADO DEL REPORTE
  /// pending / reviewing / valid / invalid / closed
  final String status;

  /// Si fue validado por SKANO / policía
  final bool verified;

  /// RECOMPENSA ASOCIADA
  final num rewardAmount;
  final bool rewardPaid;

  /// Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const ReportModel({
    required this.id,
    required this.vehicleId,
    required this.reporterUid,
    required this.type,
    required this.comment,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.city,
    required this.address,
    required this.status,
    required this.verified,
    required this.rewardAmount,
    required this.rewardPaid,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReportModel(
      id: doc.id,
      vehicleId: (data['vehicle_id'] ?? '') as String,
      reporterUid: (data['reporter_uid'] ?? '') as String,
      type: (data['type'] ?? 'other') as String,
      comment: (data['comment'] ?? '') as String,
      imageUrl: (data['image_url'] ?? '') as String,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      city: (data['city'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      verified: (data['verified'] ?? false) as bool,
      rewardAmount: (data['reward_amount'] ?? 0) as num,
      rewardPaid: (data['reward_paid'] ?? false) as bool,
      createdAt: _fromTimestampOrNull(data['created_at']),
      updatedAt: _fromTimestampOrNull(data['updated_at']),
      resolvedAt: _fromTimestampOrNull(data['resolved_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'reporter_uid': reporterUid,
      'type': type,
      'comment': comment,
      'image_url': imageUrl,
      'lat': lat,
      'lng': lng,
      'city': city,
      'address': address,
      'status': status,
      'verified': verified,
      'reward_amount': rewardAmount,
      'reward_paid': rewardPaid,
      'created_at':
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolved_at':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  ReportModel copyWith({
    String? vehicleId,
    String? reporterUid,
    String? type,
    String? comment,
    String? imageUrl,
    double? lat,
    double? lng,
    String? city,
    String? address,
    String? status,
    bool? verified,
    num? rewardAmount,
    bool? rewardPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id,
      vehicleId: vehicleId ?? this.vehicleId,
      reporterUid: reporterUid ?? this.reporterUid,
      type: type ?? this.type,
      comment: comment ?? this.comment,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      city: city ?? this.city,
      address: address ?? this.address,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardPaid: rewardPaid ?? this.rewardPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

DateTime? _fromTimestampOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  return null;
}
