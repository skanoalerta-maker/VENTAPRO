//============================================================================
// 📄 Archivo: report_protocol.dart
// ✅ FLUJO PROFESIONAL SKANO
// ✅ MISMA LÓGICA BASE / NO SE PIERDE NADA
// ✅ UX MEJORADA 100/100
// ✅ MODO “PATENTE CLONADA” (SIN COLECCIÓN NUEVA)
// ✅ ETAPA 5 OBLIGATORIA: COMISARÍA + DESTINO + FOTO CON CARABINEROS
// ✅ SIN DEPENDENCIA DE APROBACIÓN ADMIN PARA COMPLETAR EL PROTOCOLO
//============================================================================

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigator.dart';
import 'report_waiting_authority_screen.dart';


class SkanoSecurityContact {
  const SkanoSecurityContact({
    required this.city,
    required this.label,
    required this.phone,
    this.note = '',
  });

  final String city;
  final String label;
  final String phone;
  final String note;
}

// Central comunal usada por SKANO para apoyo preventivo.
// IMPORTANTE: Seguridad Ciudadana no reemplaza a Carabineros ni PDI.
// Estos números son editables y se pueden ampliar comuna por comuna.
const List<SkanoSecurityContact> skanoSecurityContacts = [
  SkanoSecurityContact(
    city: 'Talcahuano',
    label: 'Seguridad Municipal Talcahuano',
    phone: '1521',
    note: 'Número único municipal',
  ),
  SkanoSecurityContact(
    city: 'Concepción',
    label: 'Seguridad Pública Concepción',
    phone: '1485',
    note: 'Central municipal',
  ),
  SkanoSecurityContact(
    city: 'Santiago',
    label: 'Seguridad 24 hrs Santiago',
    phone: '1406',
    note: 'Seguridad municipal 24 hrs',
  ),
  SkanoSecurityContact(
    city: 'San Bernardo',
    label: 'Central de Cámaras San Bernardo',
    phone: '1523',
    note: 'Atención 24 hrs',
  ),
  SkanoSecurityContact(
    city: 'La Reina',
    label: 'Seguridad y Emergencias La Reina',
    phone: '1419',
    note: 'Unidad municipal',
  ),
  SkanoSecurityContact(
    city: 'Melipilla',
    label: 'Seguridad Pública Melipilla',
    phone: '1449',
    note: 'Central municipal',
  ),
  SkanoSecurityContact(
    city: 'San Joaquín',
    label: 'Seguridad Comunitaria San Joaquín',
    phone: '229223490',
    note: 'Contacto municipal',
  ),
];

class ReportProtocol extends StatefulWidget {
  const ReportProtocol({super.key});

  @override
  State<ReportProtocol> createState() => _ReportProtocolState();
}

class _ReportProtocolState extends State<ReportProtocol> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bgBlack = Color(0xFF05070B);
  static const Color cardDark = Color(0xFF0B1220);
  static const Color panelDark = Color(0xFF101827);

  static const bool disableMapForDebug = false;

  File? vehiclePhoto;
  LocationData? userLocation;

  bool uploadingPhoto = false;
  bool photoUploaded = false;
  String? reporterPhotoUrl;
  String? reporterSelfieUrl;

  String? currentReportId;

  File? recoveredPhoto;
  bool uploadingRecoveredPhoto = false;
  bool recoveredPhotoUploaded = false;
  String? recoveredPhotoUrl;

  bool finalizing = false;
  bool finalized = false;
  bool closingVehicleNotFound = false;
  bool initialProtocolSent = false;

  final TextEditingController policeStationCtrl = TextEditingController();
  final TextEditingController policeCaseCtrl = TextEditingController();
  final TextEditingController policeTransferDestinationCtrl =
      TextEditingController();

  bool loadingLocation = true;
  bool sending = false;
  bool calledPolice = false;
  bool calledPdi = false;
  bool calledSecurity = false;
  bool locationShared = false;

  SkanoSecurityContact selectedSecurityContact = skanoSecurityContacts.first;

  bool ackSeenVehicle = false;
  bool ackNoConfront = false;
  bool ackCallIfSafe = false;

  bool suspectedClone = false;

  final ImagePicker picker = ImagePicker();

  Map<String, dynamic>? vehicle;
  Map<String, dynamic>? stolenDocData;
  Map<String, dynamic>? declaration;
  bool checkingStolen = true;

  String? lastSendError;

  GoogleMapController? _mapController;

  @override
  void dispose() {
    policeStationCtrl.dispose();
    policeCaseCtrl.dispose();
    policeTransferDestinationCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (vehicle != null) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    reporterSelfieUrl = args?['reportSelfieUrl'];

    final argStolenId = (args?['stolenId'] ?? '').toString().trim();

    vehicle = (args?['vehicle'] as Map?)?.cast<String, dynamic>();
    declaration = (args?['declaration'] as Map?)?.cast<String, dynamic>();

    if (vehicle != null && argStolenId.isNotEmpty) {
      vehicle!['id'] = argStolenId;
    }

    _validateStolenThenInit();
  }

  Future<void> _validateStolenThenInit() async {
    try {
      if (vehicle == null) {
        if (mounted) setState(() => checkingStolen = false);
        return;
      }

      final String stolenId = (vehicle!['id'] ?? '').toString().trim();
      final String plate = (vehicle!['plate'] ?? '').toString().toUpperCase();

      if (stolenId.isEmpty || plate.isEmpty) {
        if (mounted) setState(() => checkingStolen = false);
        return;
      }

      final docSnap = await FirebaseFirestore.instance
          .collection('stolen_vehicles')
          .doc(stolenId)
          .get();

      final data = docSnap.data();

      final dbPlate = (data?['plate'] ?? '').toString().toUpperCase();
      final dbStatus = (data?['status'] ?? '').toString();
      final dbVerified = data?['verified'];
      final dbActive = data?['active'];

      final ok = docSnap.exists &&
          data != null &&
          dbPlate == plate &&
          dbStatus == 'stolen' &&
          dbVerified == true &&
          dbActive == true;

      if (!ok) {
        if (!mounted) return;

        final reason = 'VALIDACIÓN FALLÓ\n'
            'exists=${docSnap.exists}\n'
            'plate(app)=$plate\n'
            'plate(db)=$dbPlate\n'
            'status=$dbStatus\n'
            'verified=$dbVerified\n'
            'active=$dbActive\n'
            'stolenId=$stolenId';

        debugPrint(reason);
        _snack(
          'No se pudo validar este vehículo como activo para reporte.',
          isError: true,
        );

        await skanoPushNamedAndRemoveUntil(
          context,
          '/report_result',
          arguments: {'plate': plate, 'isStolen': false},
        );
        return;
      }

      stolenDocData = data;

      if (mounted) setState(() => checkingStolen = false);

      await _getLocation();
    } catch (e) {
      debugPrint('ERROR _validateStolenThenInit: $e');
      if (mounted) setState(() => checkingStolen = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() => loadingLocation = true);
    final location = Location();

    if (!await location.serviceEnabled()) {
      final enabled = await location.requestService();
      if (!enabled) {
        if (mounted) {
          setState(() => loadingLocation = false);
          _snack('Activa el GPS para continuar.', isError: true);
        }
        return;
      }
    }

    var perm = await location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await location.requestPermission();
    }

    if (perm == PermissionStatus.deniedForever ||
        perm == PermissionStatus.denied) {
      if (mounted) {
        setState(() => loadingLocation = false);
        _snack(
          'Permiso de ubicación denegado. Actívalo en Ajustes.',
          isError: true,
        );
      }
      return;
    }

    try {
      userLocation = await location.getLocation();
    } catch (e) {
      debugPrint('ERROR getLocation: $e');
    }

    if (mounted) {
      setState(() => loadingLocation = false);

      if (!disableMapForDebug &&
          userLocation?.latitude != null &&
          userLocation?.longitude != null &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(userLocation!.latitude!, userLocation!.longitude!),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 72,
    );

    if (file != null) {
      setState(() {
        vehiclePhoto = File(file.path);
        photoUploaded = false;
        reporterPhotoUrl = null;
      });
    }
  }

  Future<void> _takeRecoveredPhoto() async {
    if (currentReportId == null || currentReportId!.isEmpty) {
      _snack(
        'Primero debes enviar el reporte inicial para habilitar la etapa final.',
        isError: true,
      );
      return;
    }

    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 72,
    );

    if (file != null) {
      setState(() {
        recoveredPhoto = File(file.path);
        recoveredPhotoUploaded = false;
        recoveredPhotoUrl = null;
        finalized = false;
      });
    }
  }

  Future<void> _callNumber({
    required String phone,
    required String label,
    VoidCallback? afterCall,
  }) async {
    if (!photoUploaded) {
      _snack(
        'Primero envía la foto del vehículo.',
        isError: true,
      );
      return;
    }

    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedPhone.isEmpty) {
      _snack('Número no disponible para $label.', isError: true);
      return;
    }

    await launchUrl(Uri.parse('tel:$cleanedPhone'));

    if (mounted) {
      setState(() {
        afterCall?.call();
      });
    }
  }

  Future<void> _callPolice() async {
    await _callNumber(
      phone: '133',
      label: 'Carabineros',
      afterCall: () => calledPolice = true,
    );
  }

  Future<void> _callPdi() async {
    await _callNumber(
      phone: '134',
      label: 'PDI',
      afterCall: () => calledPdi = true,
    );
  }

  Future<void> _callSecurityContact() async {
    await _callNumber(
      phone: selectedSecurityContact.phone,
      label: selectedSecurityContact.label,
      afterCall: () => calledSecurity = true,
    );
  }

  Future<void> _shareMyLocation() async {
    final lat = userLocation?.latitude;
    final lng = userLocation?.longitude;

    if (lat == null || lng == null) {
      _snack('Primero confirma tu ubicación GPS.', isError: true);
      await _getLocation();
      return;
    }

    final plate = (vehicle?['plate'] ?? '').toString().toUpperCase();
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    final msg = 'SKANO - Ubicación de reporte seguro\n'
        'Patente: $plate\n'
        'Estoy en esta ubicación:\n$mapsUrl\n\n'
        'No confrontar. Contactar autoridad competente.';

    await Share.share(msg, subject: 'Ubicación SKANO - $plate');

    if (mounted) setState(() => locationShared = true);
  }


  Future<LocationData?> _captureFinalClosureLocation() async {
    final location = Location();

    try {
      if (!await location.serviceEnabled()) {
        final enabled = await location.requestService();
        if (!enabled) return userLocation;
      }

      var perm = await location.hasPermission();
      if (perm == PermissionStatus.denied) {
        perm = await location.requestPermission();
      }

      if (perm == PermissionStatus.deniedForever ||
          perm == PermissionStatus.denied) {
        return userLocation;
      }

      final latest = await location.getLocation();

      if (mounted) {
        setState(() => userLocation = latest);
      } else {
        userLocation = latest;
      }

      return latest;
    } catch (e) {
      debugPrint('ERROR _captureFinalClosureLocation: $e');
      return userLocation;
    }
  }

Map<String, dynamic> _finalClosureLocationPayload(
  LocationData? latestLocation, {
  required String reason,
}) {
  final lat = latestLocation?.latitude;
  final lng = latestLocation?.longitude;

  return {
    'final_user_location':
        lat != null && lng != null ? GeoPoint(lat, lng) : null,

    'final_user_location_maps':
        lat != null && lng != null
            ? 'https://www.google.com/maps?q=$lat,$lng'
            : null,

    'final_user_location_captured_at':
        FieldValue.serverTimestamp(),

    'final_user_location_reason': reason,

    'final_user_location_note':
        'Registro final de seguridad. No incentiva seguimiento ni persecución del vehículo.',
  };
}
  Future<String> _uploadReporterPhoto({
    required File file,
    required String reportId,
  }) async {
    final ref = FirebaseStorage.instance.ref(
      'reports/$reportId/reporter_vehicle_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> _uploadRecoveredPhoto({
    required File file,
    required String reportId,
  }) async {
    final ref = FirebaseStorage.instance.ref(
      'reports/$reportId/carabineros_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  bool get _canSendPhoto {
    final hasPhoto = vehiclePhoto != null;
    final hasLoc =
        userLocation?.latitude != null && userLocation?.longitude != null;

    return hasPhoto &&
        hasLoc &&
        !uploadingPhoto &&
        !checkingStolen &&
        !sending;
  }

  bool get _canSendReport {
    final hasLoc =
        userLocation?.latitude != null && userLocation?.longitude != null;
    final checklistOk = ackSeenVehicle && ackNoConfront && ackCallIfSafe;
    final hasPhotoUploaded = reporterPhotoUrl != null && photoUploaded == true;

    return hasLoc &&
        checklistOk &&
        hasPhotoUploaded &&
        !sending &&
        !checkingStolen;
  }

  bool get _canUploadRecoveryPhoto {
    final hasReport = currentReportId != null &&
        currentReportId!.isNotEmpty &&
        initialProtocolSent;
    final hasPhoto = recoveredPhoto != null;

    final stationOk = policeStationCtrl.text.trim().isNotEmpty;
    final caseOk = policeCaseCtrl.text.trim().isNotEmpty;
    final destinationOk =
        policeTransferDestinationCtrl.text.trim().isNotEmpty;

    return hasReport &&
        hasPhoto &&
        stationOk &&
        caseOk &&
        destinationOk &&
        !uploadingRecoveredPhoto &&
        !finalizing &&
        !sending;
  }

  bool get _canFinalizeRecovery {
    final hasReport = currentReportId != null &&
        currentReportId!.isNotEmpty &&
        initialProtocolSent;
    final hasRecoveryUploaded =
        recoveredPhotoUploaded && (recoveredPhotoUrl?.isNotEmpty ?? false);

    final stationOk = policeStationCtrl.text.trim().isNotEmpty;
    final caseOk = policeCaseCtrl.text.trim().isNotEmpty;
    final destinationOk =
        policeTransferDestinationCtrl.text.trim().isNotEmpty;

    return hasReport &&
        hasRecoveryUploaded &&
        stationOk &&
        caseOk &&
        destinationOk &&
        !finalizing &&
        !sending;
  }

  int get _completedSteps {
    int steps = 0;

    if (userLocation?.latitude != null && userLocation?.longitude != null) {
      steps++;
    }

    if (photoUploaded) steps++;

    if (ackSeenVehicle && ackNoConfront && ackCallIfSafe) steps++;

    if (initialProtocolSent) steps++;

    if (recoveredPhotoUploaded) steps++;

    if (finalized) steps++;

    return steps;
  }

  double get _progressValue => (_completedSteps / 6).clamp(0.0, 1.0);

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1F2937),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _cancelAndBackToReport() {
    skanoPushNamedAndRemoveUntil(context, '/report');
  }

  Future<void> _sendPhotoOnly() async {
    if (!_canSendPhoto) {
      _snack(
        'Toma una foto del vehículo y confirma ubicación antes de enviar.',
        isError: true,
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final v = vehicle ?? {};

    setState(() => uploadingPhoto = true);

    try {
      final reportRef = (currentReportId != null && currentReportId!.isNotEmpty)
          ? FirebaseFirestore.instance.collection('reports').doc(currentReportId)
          : FirebaseFirestore.instance.collection('reports').doc();

      final reportId = reportRef.id;

      final url = await _uploadReporterPhoto(
        file: vehiclePhoto!,
        reportId: reportId,
      );

      final ownerVehiclePhotoUrl = (v['vehicle_photo_url'] ??
              v['vehiclePhotoUrl'] ??
              v['photoUrl'] ??
              stolenDocData?['vehicle_photo_url'] ??
              stolenDocData?['vehiclePhotoUrl'] ??
              stolenDocData?['photoUrl'] ??
              '')
          .toString()
          .trim();

      final ownerUid =
          (v['owner_uid'] ?? stolenDocData?['owner_uid'] ?? '').toString().trim();

      declaration ??= {
        'accepted': true,
        'accepted_at': DateTime.now().toIso8601String(),
        'method': 'fallback',
        'version': 'v1.0',
        'accepted_by_uid': uid,
      };

      final reportSnap = await reportRef.get();

      if (!reportSnap.exists) {
        await reportRef.set({
          'reportId': reportId,
          'reporter_selfie_url': reporterSelfieUrl,
          'uid': uid,
          'reporter_uid': uid,
          'plate': (v['plate'] ?? '').toString().toUpperCase(),
          'plate_normalized': (v['plate'] ?? '').toString().toUpperCase(),
          'vehicle_id': (v['id'] ?? '').toString(),
          'owner_uid': ownerUid.isEmpty ? null : ownerUid,
          'declaration': declaration,
          'declaration_accepted': true,
          'vehicle_photo_url':
              ownerVehiclePhotoUrl.isEmpty ? null : ownerVehiclePhotoUrl,
          'reporter_photo_url': url,
          'location': GeoPoint(userLocation!.latitude!, userLocation!.longitude!),
          'status': 'active_report',
          'authority_confirmed': false,
          'called_police': calledPolice,
          'called_pdi': calledPdi,
          'called_security': calledSecurity,
          'security_city': selectedSecurityContact.city,
          'security_contact_label': selectedSecurityContact.label,
          'security_contact_phone': selectedSecurityContact.phone,
          'location_shared': locationShared,
          'ack_seen_vehicle': ackSeenVehicle,
          'ack_no_confront': ackNoConfront,
          'ack_call_if_safe': ackCallIfSafe,
          'admin_status': 'auto_logged',
          'admin_review_pending': false,
          'admin_reviewed_at': null,
          'admin_reviewed_by': null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': null,
          'source': 'stolen_vehicles',
          'is_retry': false,
          'report_type': suspectedClone ? 'cloned_plate' : 'stolen_sighting',
          'suspected_clone': suspectedClone,
          'reward_type': suspectedClone ? 'bonus' : 'normal',
          'reward_amount_clp': null,
          'reward_counted': false,
          'reward_status': 'not_completed_yet',
          'recovery_photo_uploaded': false,
          'recovery_photo_uploaded_at': null,
          'recovery_stage_completed': false,
          'recovered_photo_url': null,
          'recovery_finalized_at': null,
          'recovered': false,
          'police_station': null,
          'police_case_number': null,
          'police_transfer_destination': null,
          'manual_eta_business_days': null,
          'owner_recovery_email_pending': false,
          'owner_recovery_email_sent': false,
          'owner_recovery_email_sent_at': null,
          'initial_report_email_pending': true,
          'initial_report_email_sent': false,
          'initial_report_email_sent_at': null,
          'vehicle_not_found': false,
          'vehicle_not_found_at': null,
          'vehicle_not_found_note': null,
          'vehicle_not_found_email_pending': false,
          'vehicle_not_found_email_sent': false,
          'vehicle_not_found_email_sent_at': null,
        });

        final stolenId = (v['id'] ?? '').toString().trim();

        if (stolenId.isNotEmpty) {
          if (suspectedClone) {
            await FirebaseFirestore.instance
                .collection('stolen_vehicles')
                .doc(stolenId)
                .update({
              'last_clone_report_id': reportId,
              'clone_reports_count': FieldValue.increment(1),
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else {
            await FirebaseFirestore.instance
                .collection('stolen_vehicles')
                .doc(stolenId)
                .update({
              'active': false,
              'status': 'reported',
              'reported_at': FieldValue.serverTimestamp(),
              'last_report_id': reportId,
            });
          }
        }
      } else {
        await reportRef.set({
          'reporter_photo_url': url,
          'location': GeoPoint(userLocation!.latitude!, userLocation!.longitude!),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      setState(() {
        currentReportId = reportId;
        reporterPhotoUrl = url;
        photoUploaded = true;
      });

      _snack('Foto del vehículo enviada correctamente ✅');
    } catch (e) {
      debugPrint('ERROR _sendPhotoOnly: $e');
      _snack('No se pudo enviar la foto. Reintenta.', isError: true);
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> _sendReport({bool isRetry = false}) async {
    if (!_canSendReport) {
      _snack(
        'Antes de reportar: envía la foto del vehículo, acepta el checklist y mantén la ubicación activa.',
        isError: true,
      );
      return;
    }

    final v = vehicle ?? {};
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    declaration ??= {
      'accepted': true,
      'accepted_at': DateTime.now().toIso8601String(),
      'method': 'fallback',
      'version': 'v1.0',
      'accepted_by_uid': uid,
    };

    setState(() {
      sending = true;
      lastSendError = null;
    });

    try {
      final reportRef = (currentReportId != null && currentReportId!.isNotEmpty)
          ? FirebaseFirestore.instance.collection('reports').doc(currentReportId)
          : FirebaseFirestore.instance.collection('reports').doc();

      final ownerVehiclePhotoUrl = (v['vehicle_photo_url'] ??
              v['vehiclePhotoUrl'] ??
              v['photoUrl'] ??
              stolenDocData?['vehicle_photo_url'] ??
              stolenDocData?['vehiclePhotoUrl'] ??
              stolenDocData?['photoUrl'] ??
              '')
          .toString()
          .trim();

      final ownerUid =
          (v['owner_uid'] ?? stolenDocData?['owner_uid'] ?? '').toString().trim();

      final String finalReporterPhotoUrl = reporterPhotoUrl!;
      final String? finalReporterSelfieUrl = reporterSelfieUrl;

      final reportSnap = await reportRef.get();

      if (reportSnap.exists) {
        await reportRef.set({
          'reporter_selfie_url': finalReporterSelfieUrl,
          'declaration': declaration,
          'declaration_accepted': true,
          'called_police': calledPolice,
          'called_pdi': calledPdi,
          'called_security': calledSecurity,
          'security_city': selectedSecurityContact.city,
          'security_contact_label': selectedSecurityContact.label,
          'security_contact_phone': selectedSecurityContact.phone,
          'location_shared': locationShared,
          'ack_seen_vehicle': true,
          'ack_no_confront': true,
          'ack_call_if_safe': true,
          'admin_status': 'auto_logged',
          'admin_review_pending': false,
          'is_retry': isRetry,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await reportRef.set({
          'reportId': reportRef.id,
          'reporter_selfie_url': finalReporterSelfieUrl,
          'uid': uid,
          'reporter_uid': uid,
          'plate': (v['plate'] ?? '').toString().toUpperCase(),
          'plate_normalized': (v['plate'] ?? '').toString().toUpperCase(),
          'vehicle_id': (v['id'] ?? '').toString(),
          'owner_uid': ownerUid.isEmpty ? null : ownerUid,
          'declaration': declaration,
          'declaration_accepted': true,
          'vehicle_photo_url':
              ownerVehiclePhotoUrl.isEmpty ? null : ownerVehiclePhotoUrl,
          'reporter_photo_url': finalReporterPhotoUrl,
          'location': GeoPoint(userLocation!.latitude!, userLocation!.longitude!),
          'status': 'active_report',
          'authority_confirmed': false,
          'called_police': calledPolice,
          'called_pdi': calledPdi,
          'called_security': calledSecurity,
          'security_city': selectedSecurityContact.city,
          'security_contact_label': selectedSecurityContact.label,
          'security_contact_phone': selectedSecurityContact.phone,
          'location_shared': locationShared,
          'ack_seen_vehicle': true,
          'ack_no_confront': true,
          'ack_call_if_safe': true,
          'admin_status': 'auto_logged',
          'admin_review_pending': false,
          'admin_reviewed_at': null,
          'admin_reviewed_by': null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': null,
          'source': 'stolen_vehicles',
          'is_retry': isRetry,
          'report_type': suspectedClone ? 'cloned_plate' : 'stolen_sighting',
          'suspected_clone': suspectedClone,
          'reward_type': suspectedClone ? 'bonus' : 'normal',
          'reward_amount_clp': null,
          'reward_counted': false,
          'reward_status': 'not_completed_yet',
          'recovery_photo_uploaded': false,
          'recovery_photo_uploaded_at': null,
          'recovery_stage_completed': false,
          'recovered_photo_url': null,
          'recovery_finalized_at': null,
          'recovered': false,
          'police_station': null,
          'police_case_number': null,
          'police_transfer_destination': null,
          'manual_eta_business_days': null,
          'owner_recovery_email_pending': false,
          'owner_recovery_email_sent': false,
          'owner_recovery_email_sent_at': null,
          'initial_report_email_pending': true,
          'initial_report_email_sent': false,
          'initial_report_email_sent_at': null,
          'vehicle_not_found': false,
          'vehicle_not_found_at': null,
          'vehicle_not_found_note': null,
          'vehicle_not_found_email_pending': false,
          'vehicle_not_found_email_sent': false,
          'vehicle_not_found_email_sent_at': null,
        });
      }

      final stolenId = (v['id'] ?? '').toString().trim();

      if (stolenId.isNotEmpty && !reportSnap.exists) {
        if (suspectedClone) {
          await FirebaseFirestore.instance
              .collection('stolen_vehicles')
              .doc(stolenId)
              .update({
            'last_clone_report_id': reportRef.id,
            'clone_reports_count': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance
              .collection('stolen_vehicles')
              .doc(stolenId)
              .update({
            'active': false,
            'status': 'reported',
            'reported_at': FieldValue.serverTimestamp(),
            'last_report_id': reportRef.id,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        currentReportId = reportRef.id;
        initialProtocolSent = true;
      });

      await skanoPushReplacementRoute(
        context,
        MaterialPageRoute(
          builder: (_) => ReportWaitingAuthorityScreen(reportId: reportRef.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => lastSendError = e.toString());
        _snack(
          'No se pudo enviar el reporte. Puedes reintentar.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _uploadRecoveryPhotoOnly() async {
    if (!_canUploadRecoveryPhoto) {
      _snack(
        'Completa comisaría, Nº parte, destino y toma la foto con Carabineros.',
        isError: true,
      );
      return;
    }

    setState(() => uploadingRecoveredPhoto = true);

    try {
      final reportId = currentReportId!;
      final url = await _uploadRecoveredPhoto(
        file: recoveredPhoto!,
        reportId: reportId,
      );

      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'recovery_photo_uploaded': true,
        'recovered_photo_url': url,
        'recovery_photo_uploaded_at': FieldValue.serverTimestamp(),
        'police_station': policeStationCtrl.text.trim(),
        'police_case_number': policeCaseCtrl.text.trim(),
        'police_transfer_destination': policeTransferDestinationCtrl.text.trim(),
        'owner_recovery_email_pending': false,
        'owner_recovery_email_sent': false,
        'owner_recovery_email_sent_at': null,
      });

      if (!mounted) return;

      setState(() {
        recoveredPhotoUrl = url;
        recoveredPhotoUploaded = true;
      });

      _snack('Foto con Carabineros enviada correctamente ✅');
    } catch (e) {
      debugPrint('ERROR _uploadRecoveryPhotoOnly: $e');
      _snack('No se pudo enviar la foto final. Reintenta.', isError: true);
    } finally {
      if (mounted) setState(() => uploadingRecoveredPhoto = false);
    }
  }

  Future<void> _finalizeRecoveryCycle() async {
    if (!_canFinalizeRecovery) {
      _snack(
        'Falta completar datos policiales y enviar la foto con Carabineros.',
        isError: true,
      );
      return;
    }

    setState(() => finalizing = true);

    try {
      final reportId = currentReportId!;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final v = vehicle ?? {};
      final stolenId = (v['id'] ?? '').toString().trim();
      final policeDestination = policeTransferDestinationCtrl.text.trim();
      final finalLocation = await _captureFinalClosureLocation();

      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': 'recovery_completed',
        'admin_review_pending': false,
        'admin_status': 'auto_completed',
        'manual_eta_business_days': null,
        'reward_status': 'pending_payment_review',
        'recovery_finalized_at': FieldValue.serverTimestamp(),
        'police_station': policeStationCtrl.text.trim(),
        'police_case_number': policeCaseCtrl.text.trim(),
        'police_transfer_destination': policeDestination,
        'recovered': true,
        'recovered_photo_url': recoveredPhotoUrl,
        'recovery_stage_completed': true,
        'owner_recovery_email_pending': true,
        ..._finalClosureLocationPayload(
          finalLocation,
          reason: 'recovery_completed',
        ),
      });

      if (stolenId.isNotEmpty) {
        if (!suspectedClone) {
          await FirebaseFirestore.instance
              .collection('stolen_vehicles')
              .doc(stolenId)
              .update({
            'status': 'recovered',
            'active': false,
            'recovered_at': FieldValue.serverTimestamp(),
            'last_report_id': reportId,
            'recovered_to': policeDestination,
          });
        } else {
          await FirebaseFirestore.instance
              .collection('stolen_vehicles')
              .doc(stolenId)
              .update({
            'last_clone_finalized_report_id': reportId,
            'clone_finalized_count': FieldValue.increment(1),
            'updated_at': FieldValue.serverTimestamp(),
            'last_known_police_destination': policeDestination,
          });
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'reports_pending_verification': FieldValue.increment(1),
        'rewards_pending_count': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reward_pending')
          .doc(reportId)
          .set({
        'reportId': reportId,
        'plate': (v['plate'] ?? '').toString().toUpperCase(),
        'status': 'pending_payment_review',
        'created_at': FieldValue.serverTimestamp(),
        'type': suspectedClone ? 'clone_bonus' : 'recovery',
        'reward_type': suspectedClone ? 'bonus' : 'normal',
        'police_transfer_destination': policeDestination,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => finalized = true);

      _snack(
        'Reporte final completado ✅ El procedimiento quedó registrado correctamente.',
      );

      await skanoPushNamedAndRemoveUntil(context, '/report');
    } catch (e) {
      debugPrint('ERROR _finalizeRecoveryCycle: $e');
      _snack('No se pudo finalizar. Reintenta.', isError: true);
    } finally {
      if (mounted) setState(() => finalizing = false);
    }
  }

  Future<void> _markVehicleNotFound() async {
    if (currentReportId == null || currentReportId!.isEmpty) {
      _snack(
        'Primero debes enviar el reporte inicial.',
        isError: true,
      );
      return;
    }

    if (closingVehicleNotFound || finalizing || sending) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '¿Estás seguro?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          '¿Estás seguro que el vehículo ya no se encuentra en el lugar?\n\n'
          'Si presionas CONTINUAR, este reporte quedará sin efecto de recuperación y se cerrará como “vehículo no encontrado”.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Continuar',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => closingVehicleNotFound = true);

    try {
      final reportId = currentReportId!;
      final v = vehicle ?? {};
      final stolenId = (v['id'] ?? '').toString().trim();
      final finalLocation = await _captureFinalClosureLocation();

      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': 'vehicle_not_found',
        'vehicle_not_found': true,
        'vehicle_not_found_at': FieldValue.serverTimestamp(),
        'vehicle_not_found_note':
            'Vehículo ya no se encontraba en el lugar al momento del seguimiento.',
        'recovered': false,
        'recovery_stage_completed': true,
        'reward_status': 'no_reward_vehicle_not_found',
        'admin_status': 'auto_closed',
        'admin_review_pending': false,
        'vehicle_not_found_email_pending': true,
        'vehicle_not_found_email_sent': false,
        'vehicle_not_found_email_sent_at': null,
        'updated_at': FieldValue.serverTimestamp(),
        ..._finalClosureLocationPayload(
          finalLocation,
          reason: 'vehicle_not_found',
        ),
      });

      if (stolenId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('stolen_vehicles')
            .doc(stolenId)
            .update({
          'active': true,
          'status': 'stolen',
          'last_not_found_report_id': reportId,
          'last_not_found_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      _snack(
        'Reporte cerrado: el vehículo ya no se encontraba en el lugar.',
      );

      await skanoPushNamedAndRemoveUntil(context, '/report');
    } catch (e) {
      debugPrint('ERROR _markVehicleNotFound: $e');
      _snack(
        'No se pudo cerrar el reporte. Reintenta.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => closingVehicleNotFound = false);
    }
  }

  Widget _sectionHeader({
    required String step,
    required String title,
    required IconData icon,
    Color color = neonBlue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatus(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: ok ? Colors.greenAccent : Colors.white38,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: ok ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(15),
    Color borderColor = Colors.white12,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String text,
    Color color = Colors.orangeAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
    Color color = neonBlue,
    IconData? icon,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade700 : color,
          foregroundColor: Colors.black,
          elevation: onPressed == null ? 0 : 6,
          shadowColor: color.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(
          loading ? 'Procesando...' : label,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleCloneMode() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿No coincide con la foto del dueño?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Si la patente coincide pero el vehículo NO es el mismo, puede tratarse de una patente clonada.\n\n'
          'Se creará un reporte especial. Este reporte también requiere evidencia, ubicación y protocolo completo.',
          style: TextStyle(color: Colors.white70, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Activar modo clonada',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!mounted) return;

      setState(() => suspectedClone = true);

      _snack('Modo patente clonada activado ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checkingStolen) {
      return const Scaffold(
        backgroundColor: bgBlack,
        body: Center(
          child: CircularProgressIndicator(color: neonBlue),
        ),
      );
    }

    if (vehicle == null) {
      return const Scaffold(
        backgroundColor: bgBlack,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Error: reporte inválido.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final plate = (vehicle!['plate'] ?? '').toString().toUpperCase();

    final ownerPhotoUrl = (vehicle!['vehicle_photo_url'] ??
            vehicle!['vehiclePhotoUrl'] ??
            vehicle!['photoUrl'] ??
            stolenDocData?['vehicle_photo_url'] ??
            stolenDocData?['vehiclePhotoUrl'] ??
            stolenDocData?['photoUrl'] ??
            '')
        .toString()
        .trim();

    final latOk = userLocation?.latitude != null;
    final lngOk = userLocation?.longitude != null;

    final LatLng? myLatLng = (latOk && lngOk)
        ? LatLng(userLocation!.latitude!, userLocation!.longitude!)
        : null;

    final hasReport = currentReportId != null &&
        currentReportId!.isNotEmpty &&
        initialProtocolSent;

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        title: Text(
          'Protocolo SKANO',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: sending || finalizing ? null : _cancelAndBackToReport,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                Positioned.fill(
                  child: (loadingLocation || userLocation == null)
                      ? Container(
                          color: bgBlack,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: neonBlue),
                                const SizedBox(height: 12),
                                const Text(
                                  'Confirmando ubicación...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _getLocation,
                                  child: const Text(
                                    'Reintentar ubicación',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (disableMapForDebug
                          ? const Center(
                              child: Text(
                                'MAPA DESACTIVADO (DEBUG)\nActívalo cuando tengas la API OK.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: myLatLng!,
                                zoom: 17,
                              ),
                              onMapCreated: (c) => _mapController = c,
                              markers: {
                                Marker(
                                  markerId: const MarkerId('me'),
                                  position: myLatLng,
                                  infoWindow:
                                      const InfoWindow(title: 'Tu ubicación'),
                                ),
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              zoomControlsEnabled: false,
                            )),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.76),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: suspectedClone
                                ? Colors.orangeAccent.withOpacity(0.16)
                                : neonBlue.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: suspectedClone
                                  ? Colors.orangeAccent.withOpacity(0.5)
                                  : neonBlue.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            suspectedClone
                                ? Icons.copy_rounded
                                : Icons.directions_car_filled_rounded,
                            color: suspectedClone ? Colors.orangeAccent : neonBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suspectedClone
                                    ? 'Posible patente clonada'
                                    : 'Vehículo con encargo activo',
                                style: TextStyle(
                                  color: suspectedClone
                                      ? Colors.orangeAccent
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          userLocation != null
                              ? Icons.gps_fixed_rounded
                              : Icons.gps_off_rounded,
                          color: userLocation != null
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F18),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.60),
                    blurRadius: 34,
                    offset: const Offset(0, -12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      borderColor: neonBlue.withOpacity(0.22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suspectedClone
                                ? 'Protocolo especial de patente clonada'
                                : 'Protocolo de reporte seguro',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              minHeight: 8,
                              color: suspectedClone
                                  ? Colors.orangeAccent
                                  : neonBlue,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Avance del protocolo: $_completedSteps/6 etapas',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tu seguridad es lo más importante. No enfrentes a terceros ni intentes recuperar el vehículo. SKANO guía el reporte, pero no reemplaza a Carabineros ni realiza llamadas por ti.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            step: 'Etapa 1',
                            title: 'Confirmación visual',
                            icon: Icons.visibility_rounded,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Foto del vehículo registrada por el dueño',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 184,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: ownerPhotoUrl.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay foto del dueño disponible',
                                      style: TextStyle(color: Colors.white38),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      ownerPhotoUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, w, p) {
                                        if (p == null) return w;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: neonBlue,
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Text(
                                          'No se pudo cargar la foto',
                                          style: TextStyle(color: Colors.white38),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _infoBox(
                            icon: Icons.compare_rounded,
                            color: Colors.orangeAccent,
                            text:
                                'Compara visualmente antes de reportar. Si la patente coincide, pero el vehículo no corresponde a la foto del dueño, activa modo patente clonada.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: BorderSide(
                                color: Colors.orangeAccent.withOpacity(0.55),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: suspectedClone ? null : _toggleCloneMode,
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(
                              suspectedClone
                                  ? 'PATENTE CLONADA ACTIVADA ✅'
                                  : 'NO COINCIDE — POSIBLE PATENTE CLONADA',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _checkTile(
                      value: ackSeenVehicle,
                      onChanged: (v) => setState(() => ackSeenVehicle = v),
                      title: 'Confirmo que vi el vehículo personalmente',
                      subtitle: 'No reportes si no estás seguro.',
                    ),
                    _checkTile(
                      value: ackNoConfront,
                      onChanged: (v) => setState(() => ackNoConfront = v),
                      title: 'No confrontaré a terceros',
                      subtitle: 'No te acerques ni intentes recuperar el vehículo.',
                    ),
                    _checkTile(
                      value: ackCallIfSafe,
                      onChanged: (v) => setState(() => ackCallIfSafe = v),
                      title: 'Contactaré a una autoridad solo si es seguro',
                      subtitle:
                          'Puedes llamar a Carabineros, PDI o Seguridad Ciudadana según el caso.',
                    ),
                    const SizedBox(height: 14),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            step: 'Etapa 2',
                            title: 'Evidencia inicial',
                            icon: Icons.photo_camera_rounded,
                          ),
                          const SizedBox(height: 12),
                          _infoBox(
                            icon: Icons.gps_fixed_rounded,
                            color: Colors.greenAccent,
                            text:
                                'Esta foto corresponde al vehículo observado en terreno y se guarda junto a tu ubicación de seguridad.',
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              height: 184,
                              decoration: BoxDecoration(
                                border: Border.all(color: neonBlue),
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white10,
                              ),
                              child: vehiclePhoto == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            size: 56,
                                            color: Colors.white38,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Toca para tomar foto del vehículo',
                                            style: TextStyle(color: Colors.white60),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        vehiclePhoto!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _primaryButton(
                            label: photoUploaded
                                ? 'FOTO DEL VEHÍCULO ENVIADA ✅'
                                : 'ENVIAR FOTO DEL VEHÍCULO',
                            icon: Icons.cloud_upload_rounded,
                            loading: uploadingPhoto,
                            onPressed: _canSendPhoto ? _sendPhotoOnly : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            step: 'Etapa 3',
                            title: 'Contacto con autoridades',
                            icon: Icons.local_police_rounded,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          _infoBox(
                            icon: Icons.security_rounded,
                            color: Colors.redAccent,
                            text:
                                'Si hay riesgo inmediato, prioriza Carabineros (133). PDI (134) puede recibir denuncias o antecedentes. Seguridad Ciudadana es apoyo municipal preventivo y no reemplaza a policías.',
                          ),
                          const SizedBox(height: 12),
                          _primaryButton(
                            label: calledPolice
                                ? 'CARABINEROS CONTACTADO (133)'
                                : 'LLAMAR A CARABINEROS (133)',
                            icon: Icons.call_rounded,
                            color: Colors.redAccent,
                            loading: false,
                            onPressed: photoUploaded ? _callPolice : null,
                          ),
                          const SizedBox(height: 10),
                          _primaryButton(
                            label:
                                calledPdi ? 'PDI CONTACTADA (134)' : 'LLAMAR A PDI (134)',
                            icon: Icons.local_police_outlined,
                            color: Colors.deepPurpleAccent,
                            loading: false,
                            onPressed: photoUploaded ? _callPdi : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<SkanoSecurityContact>(
                            value: selectedSecurityContact,
                            dropdownColor: panelDark,
                            iconEnabledColor: Colors.white70,
                            decoration: InputDecoration(
                              labelText: 'Central de Seguridad Ciudadana',
                              labelStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.55),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: neonBlue),
                              ),
                            ),
                            items: skanoSecurityContacts
                                .map(
                                  (contact) => DropdownMenuItem(
                                    value: contact,
                                    child: Text(
                                      '${contact.city} · ${contact.phone}',
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (contact) {
                              if (contact == null) return;
                              setState(() {
                                selectedSecurityContact = contact;
                                calledSecurity = false;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${selectedSecurityContact.label} · ${selectedSecurityContact.note}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _primaryButton(
                            label: calledSecurity
                                ? 'SEGURIDAD CIUDADANA CONTACTADA'
                                : 'LLAMAR A SEGURIDAD CIUDADANA',
                            icon: Icons.shield_rounded,
                            color: Colors.orangeAccent,
                            loading: false,
                            onPressed: photoUploaded ? _callSecurityContact : null,
                          ),
                          const SizedBox(height: 10),
                          _primaryButton(
                            label: locationShared
                                ? 'UBICACIÓN COMPARTIDA ✅'
                                : 'COMPARTIR MI UBICACIÓN',
                            icon: Icons.share_location_rounded,
                            color: Colors.greenAccent,
                            loading: false,
                            onPressed: userLocation != null ? _shareMyLocation : null,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Las llamadas y el envío de ubicación se realizan desde tu teléfono. SKANO no contacta automáticamente a policías ni servicios municipales.',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (lastSendError != null) ...[
                      _card(
                        borderColor: Colors.redAccent.withOpacity(0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No se pudo enviar el reporte',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lastSendError!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed:
                                    sending ? null : () => _sendReport(isRetry: true),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text(
                                  'REINTENTAR ENVÍO',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            step: 'Etapa 4',
                            title: 'Enviar reporte inicial',
                            icon: Icons.assignment_turned_in_rounded,
                          ),
                          const SizedBox(height: 12),
                          _miniStatus('Ubicación registrada', userLocation != null),
                          _miniStatus('Foto del vehículo enviada', photoUploaded),
                          _miniStatus(
                            'Checklist de seguridad aceptado',
                            ackSeenVehicle && ackNoConfront && ackCallIfSafe,
                          ),
                          const SizedBox(height: 12),
                          _primaryButton(
                            label: suspectedClone
                                ? 'REPORTAR PATENTE CLONADA'
                                : 'ENVIAR REPORTE INICIAL',
                            icon: Icons.send_rounded,
                            loading: sending,
                            onPressed: _canSendReport ? () => _sendReport() : null,
                          ),
                        ],
                      ),
                    ),
                    if (hasReport) ...[
                      const SizedBox(height: 16),
                      _card(
                        borderColor: Colors.greenAccent.withOpacity(0.22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              step: 'Etapa 5',
                              title: 'Cierre con Carabineros',
                              icon: Icons.verified_rounded,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(height: 12),
                            _infoBox(
                              icon: Icons.local_police_outlined,
                              color: Colors.greenAccent,
                              text:
                                  'Completa estos datos solo cuando Carabineros esté presente o haya informado el procedimiento. El destino del vehículo es obligatorio.',
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: policeStationCtrl,
                              label: 'Comisaría / Unidad (obligatorio)',
                              hint: 'Ejemplo: Segunda Comisaría de Talcahuano',
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: policeCaseCtrl,
                              label: 'Nº Parte / Denuncia (obligatorio)',
                              hint: 'Ejemplo: 123456',
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: policeTransferDestinationCtrl,
                              label:
                                  '¿A dónde se llevan el vehículo? (obligatorio)',
                              hint:
                                  'Ejemplo: Segunda Comisaría de Talcahuano',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            _infoBox(
                              icon: Icons.location_on_rounded,
                              color: Colors.orangeAccent,
                              text:
                                  'Al cerrar el ciclo, SKANO registrará automáticamente tu última ubicación como respaldo de seguridad. Si el vehículo se mueve o ya no está, no lo sigas ni lo persigas.',
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _takeRecoveredPhoto,
                              child: Container(
                                height: 176,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white10,
                                ),
                                child: recoveredPhoto == null
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_camera_back_rounded,
                                              size: 48,
                                              color: Colors.white38,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Toca para tomar foto\ncon Carabineros',
                                              textAlign: TextAlign.center,
                                              style:
                                                  TextStyle(color: Colors.white60),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.file(
                                          recoveredPhoto!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _primaryButton(
                              label: recoveredPhotoUploaded
                                  ? 'FOTO CON CARABINEROS ENVIADA ✅'
                                  : 'ENVIAR FOTO CON CARABINEROS',
                              icon: Icons.cloud_upload_rounded,
                              loading: uploadingRecoveredPhoto,
                              onPressed: _canUploadRecoveryPhoto
                                  ? _uploadRecoveryPhotoOnly
                                  : null,
                              color: neonBlue,
                            ),
                            const SizedBox(height: 10),
                            _primaryButton(
                              label: finalized
                                  ? 'REPORTE FINALIZADO ✅'
                                  : 'FINALIZAR REPORTE',
                              icon: Icons.check_circle_rounded,
                              loading: finalizing,
                              onPressed: _canFinalizeRecovery
                                  ? _finalizeRecoveryCycle
                                  : null,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(height: 10),
                            _primaryButton(
                              label: 'EL VEHÍCULO SE MOVIÓ / YA NO ESTÁ',
                              icon: Icons.warning_amber_rounded,
                              loading: closingVehicleNotFound,
                              onPressed: hasReport && !finalized
                                  ? _markVehicleNotFound
                                  : null,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Si FINALIZAR REPORTE está deshabilitado, falta completar datos obligatorios o enviar la foto con Carabineros.',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                            sending || finalizing ? null : _cancelAndBackToReport,
                        child: const Text(
                          'CANCELAR Y VOLVER',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.black.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: neonBlue),
        ),
      ),
    );
  }

  Widget _checkTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? neonBlue.withOpacity(0.45) : Colors.white12,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: neonBlue,
        checkColor: Colors.black,
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}