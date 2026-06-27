//============================================================================
// 📄 Archivo: home_screen.dart
// 📱 Pantalla principal de SKANO (Home) - Responsive para todos los teléfonos
//============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';

import 'speed_block_screen.dart';
import '../widgets/drawer_items.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  String fullName = "Cargando...";
  int reportesEnviados = 0;
  int reportesAcertados = 0;
  String level = "BRONCE";
  String role = "user";

  bool blocked = false;
  String identityStatus = "none";
  Timestamp? sessionVerifiedUntil;

  bool faceRegistered = false;
  bool pinCreated = false;
  bool documentsCompleted = false;

  bool panelExpanded = false;

  late AnimationController _panelPulseController;
  late Animation<double> _panelPulse;

  final Location location = Location();
  LatLng? userPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _userMarker;
  bool _didIntroAnimation = false;

  StreamSubscription? _stolenSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStatsSub;
  StreamSubscription<LocationData>? _locationSub;
  StreamSubscription<StepCount>? _stepSub;

  DateTime? _lastStatsSaveAt;
  int? _baseStepsToday;
  LatLng? _lastDistancePoint;

  final int comunidadUsuarios = 304;
  int revisionPatenteHoy = 0;
  int pasosHoy = 0;
  double kilometrosHoy = 0.0;
  double currentSpeedKmh = 0.0;

  bool get registrationCompleted => faceRegistered && pinCreated;

  bool get pendingButIncomplete =>
      identityStatus == "pending" && !registrationCompleted;

  bool get showPendingBanner =>
      identityStatus == "pending" && registrationCompleted;

  bool get showAnyTopBanner =>
      identityStatus == "rejected" ||
      showPendingBanner ||
      pendingButIncomplete ||
      identityStatus == "draft" ||
      identityStatus == "none";

  bool _isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 370;
  }

  bool _isVerySmallHeight(BuildContext context) {
    return MediaQuery.of(context).size.height < 680;
  }

  double _safeBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _listenUserStats();
    _initLocation();
    _listenStolenVehiclesRealtime();
    _initStepCounter();
    _loadUserMarker();

    _panelPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _panelPulse = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _panelPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _panelPulseController.dispose();
    _stolenSub?.cancel();
    _userStatsSub?.cancel();
    _locationSub?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  void _listenUserStats() {
    if (user == null) return;

    _userStatsSub?.cancel();

    _userStatsSub = FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;

      final data = doc.data() ?? {};

      setState(() {
        revisionPatenteHoy = data["plate_reads_count"] is num
            ? (data["plate_reads_count"] as num).toInt()
            : 0;

        pasosHoy = data["steps_count"] is num
            ? (data["steps_count"] as num).toInt()
            : pasosHoy;

        kilometrosHoy = data["distance_km"] is num
            ? (data["distance_km"] as num).toDouble()
            : kilometrosHoy;
      });
    });
  }

  Future<void> _saveUserMovementStats() async {
    if (user == null) return;

    final now = DateTime.now();

    if (_lastStatsSaveAt != null &&
        now.difference(_lastStatsSaveAt!).inSeconds < 15) {
      return;
    }

    _lastStatsSaveAt = now;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "steps_count": pasosHoy,
        "distance_km": kilometrosHoy,
        "distance_meters": (kilometrosHoy * 1000).round(),
        "last_tracking_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ SAVE USER MOVEMENT STATS ERROR: $e");
    }
  }

  void _initStepCounter() {
    _stepSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (!mounted) return;

        _baseStepsToday ??= event.steps;

        final calculatedSteps = event.steps - _baseStepsToday!;

        setState(() {
          pasosHoy = calculatedSteps < 0 ? 0 : calculatedSteps;
        });

        _saveUserMovementStats();
      },
      onError: (error) {
        debugPrint("❌ STEP COUNTER ERROR: $error");
      },
      cancelOnError: false,
    );
  }

  double _distanceInKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLng = _degreesToRadians(b.longitude - a.longitude);

    final lat1 = _degreesToRadians(a.latitude);
    final lat2 = _degreesToRadians(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  Future<void> _loadUserMarker() async {
    try {
      final data = await rootBundle.load('assets/images/marker_user.png');

      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 180,
      );

      final frame = await codec.getNextFrame();
      final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);

      if (!mounted || bytes == null) return;

      setState(() {
        _userMarker = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    } catch (e) {
      debugPrint("❌ USER MARKER ERROR: $e");
    }
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data() ?? {};
    int i(v) => v is num ? v.toInt() : int.tryParse("$v") ?? 0;

    if (!mounted) return;

    final String userRole = (data["role"] ?? "user").toString();

    final rawStatus = (data["verification_status"] ?? "draft").toString();
    String normalizedStatus = rawStatus == "active" ? "approved" : rawStatus;

    if (userRole == "admin") {
      normalizedStatus = "approved";
    }

    final bool faceDone = data["faceRegistered"] == true;

    final bool hasPin =
        (data["report_pin_hash"] ?? "").toString().isNotEmpty ||
            data["pin_created_at"] != null;

    final bool docsDone = data["documentsCompleted"] == true ||
        ((data["idFrontUrl"] ?? "").toString().isNotEmpty &&
            (data["idBackUrl"] ?? "").toString().isNotEmpty &&
            (data["addressProofUrl"] ?? "").toString().isNotEmpty);

    setState(() {
      role = userRole;
      fullName = (data["full_name"] ??
              user?.displayName ??
              user?.email ??
              "Usuario SKANO")
          .toString();

      reportesEnviados = i(data["reportes_enviados"]);
      reportesAcertados = i(data["reportes_acertados"]);
      level = (data["level"] ?? "bronce").toUpperCase();

      blocked = data["blocked"] == true;
      identityStatus = normalizedStatus;
      sessionVerifiedUntil = data["session_verified_until"];

      faceRegistered = faceDone;
      pinCreated = hasPin;
      documentsCompleted = docsDone;
    });
  }

  Future<void> _initLocation() async {
    if (Platform.isWindows) return;

    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
      if (!enabled) return;
    }

    PermissionStatus perm = await location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await location.requestPermission();
    }

    if (perm != PermissionStatus.granted &&
        perm != PermissionStatus.grantedLimited) {
      return;
    }

    final loc = await location.getLocation();
    if (!mounted || loc.latitude == null || loc.longitude == null) return;

    final firstPoint = LatLng(loc.latitude!, loc.longitude!);

    setState(() {
      userPosition = firstPoint;
      _lastDistancePoint = firstPoint;
      currentSpeedKmh = ((loc.speed ?? 0) * 3.6).clamp(0, 220).toDouble();
    });

    _listenLiveSpeed();
    _runIntroCameraIfReady();
  }

  void _listenLiveSpeed() {
    _locationSub?.cancel();

    _locationSub = location.onLocationChanged.listen((loc) {
      if (!mounted) return;
      if (loc.latitude == null || loc.longitude == null) return;

      final newPoint = LatLng(loc.latitude!, loc.longitude!);
      double extraKm = 0.0;

      if (_lastDistancePoint != null) {
        final distance = _distanceInKm(_lastDistancePoint!, newPoint);

        if (distance > 0.005 && distance < 0.5) {
          extraKm = distance;
        }
      }

      setState(() {
        userPosition = newPoint;
        currentSpeedKmh = ((loc.speed ?? 0) * 3.6).clamp(0, 220).toDouble();
        kilometrosHoy += extraKm;
        _lastDistancePoint = newPoint;
      });

      if (extraKm > 0) {
        _saveUserMovementStats();
      }
    });
  }

  Future<bool> _checkGPSBeforeReport() async {
    if (Platform.isWindows) return true;

    bool enabled = await location.serviceEnabled();

    if (!enabled) {
      enabled = await location.requestService();

      if (!enabled) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Debes mantener el GPS activado para reportar."),
          ),
        );
        return false;
      }
    }

    PermissionStatus perm = await location.hasPermission();

    if (perm == PermissionStatus.denied) {
      perm = await location.requestPermission();
    }

    if (perm != PermissionStatus.granted &&
        perm != PermissionStatus.grantedLimited) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "SKANO necesita permiso de ubicación para iniciar un reporte.",
          ),
        ),
      );
      return false;
    }

    try {
      final loc = await location.getLocation();

      if (loc.latitude == null || loc.longitude == null) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("No se pudo confirmar tu ubicación."),
          ),
        );
        return false;
      }

      if (!mounted) return false;

      setState(() {
        userPosition = LatLng(loc.latitude!, loc.longitude!);
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("No se pudo obtener tu ubicación actual."),
        ),
      );

      return false;
    }
  }

  Future<void> _applyMapStyle() async {
    if (_mapController == null) return;

    try {
      final style = await rootBundle.loadString('assets/map_style_dark.json');
      await _mapController!.setMapStyle(style);
    } catch (e) {
      debugPrint("❌ MAP STYLE ERROR: $e");
    }
  }

  void _runIntroCameraIfReady() {
    if (_didIntroAnimation) return;
    if (_mapController == null || userPosition == null) return;

    _didIntroAnimation = true;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _mapController == null || userPosition == null) return;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(userPosition!, 16),
      );
    });
  }

  void _listenStolenVehiclesRealtime() {
    _stolenSub?.cancel();

    _stolenSub = FirebaseFirestore.instance
        .collection('stolen_vehicles')
        .where('active', isEqualTo: true)
        .where('verified', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      final Set<Marker> live = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final loc = data['location'];

        if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
          live.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(
                (loc['lat'] as num).toDouble(),
                (loc['lng'] as num).toDouble(),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() => _markers = live);
    });
  }

  Future<void> _centerMap() async {
    if (_mapController == null || userPosition == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userPosition!,
          zoom: 16,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 350));

    await _mapController!.animateCamera(
      CameraUpdate.scrollBy(0, -160),
    );
  }

  Future<void> _tryOpenAdmin(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.data()?['role'] == 'admin') {
      Navigator.pushNamed(context, '/admin_dashboard');
    }
  }

  Future<void> _handleReport(BuildContext context) async {
    final gpsOk = await _checkGPSBeforeReport();
    if (!gpsOk) return;

    if (currentSpeedKmh > 15) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpeedBlockScreen(
            currentSpeedKmh: currentSpeedKmh,
            limitKmh: 15,
          ),
        ),
      );
      return;
    }

    if (blocked) {
      Navigator.pushNamed(context, '/account_blocked', arguments: {
        'reason': 'selfie_fast_failed',
        'blocked_until': sessionVerifiedUntil?.toDate(),
        'adminComment': null,
      });
      return;
    }

    if (identityStatus == "none" ||
        identityStatus == "draft" ||
        pendingButIncomplete) {
      Navigator.pushNamed(context, "/my_account");
      return;
    }

    if (identityStatus == "rejected") {
      Navigator.pushNamed(context, "/my_account");
      return;
    }

    if (showPendingBanner && role != "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("⏳ Tu identidad está en revisión."),
        ),
      );
      return;
    }

    if (sessionVerifiedUntil == null ||
        sessionVerifiedUntil!.toDate().isBefore(DateTime.now())) {
      Navigator.pushNamed(context, "/session_verification");
      return;
    }

    Navigator.pushNamed(context, "/report");
  }

  Color _levelColor() {
    switch (level) {
      case "PLATA":
        return Colors.blueGrey;
      case "ORO":
        return Colors.amber;
      case "ELITE":
        return Colors.deepPurpleAccent;
      default:
        return const Color(0xFF0A6CFF);
    }
  }

  Color _levelGlow() => _levelColor().withOpacity(0.55);

  IconData _levelIcon() {
    switch (level) {
      case "PLATA":
        return Icons.verified;
      case "ORO":
        return Icons.workspace_premium;
      case "ELITE":
        return Icons.shield;
      default:
        return Icons.emoji_events;
    }
  }

  int _nextLevelGoal() {
    switch (level) {
      case "PLATA":
        return 10;
      case "ORO":
        return 30;
      case "ELITE":
        return 50;
      default:
        return 5;
    }
  }

  String _motivationalText() {
    if (reportesAcertados == 0) {
      return "Tu primer reporte puede marcar la diferencia 💙";
    }
    if (reportesAcertados < _nextLevelGoal()) {
      return "Vas excelente, sigue ayudando 🚀";
    }
    return "Eres parte clave de la comunidad 🛡️";
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);
    final small = _isSmallPhone(context);
    final verySmallHeight = _isVerySmallHeight(context);
    final safeBottom = _safeBottom(context);

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: SkanoDrawer(
        userName: fullName,
        correctReports: reportesAcertados,
        totalReports: reportesEnviados,
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: InkWell(
          onLongPress: () => _tryOpenAdmin(context),
          child: const Text(
            "SKANO",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (!Platform.isWindows)
            IconButton(
              onPressed: _centerMap,
              icon: const Icon(Icons.my_location),
            ),
        ],
      ),
      body: Platform.isWindows
          ? _windowsPlaceholder()
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: userPosition ?? const LatLng(-33.4489, -70.6693),
                      zoom: 15,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    markers: {
                      ..._markers,
                      if (userPosition != null)
                        Marker(
                          markerId: const MarkerId("user"),
                          position: userPosition!,
                          icon: _userMarker ??
                              BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                          anchor: const Offset(0.5, 1.5),
                        ),
                    },
                    onMapCreated: (controller) async {
                      _mapController = controller;

                      Future.delayed(const Duration(milliseconds: 350),
                          () async {
                        if (!mounted) return;
                        await _applyMapStyle();
                      });

                      _runIntroCameraIfReady();
                    },
                  ),
                ),

                if (userPosition == null)
                  const Center(child: CircularProgressIndicator()),

                if (identityStatus == "rejected")
                  _buildTopBanner(
                    Colors.redAccent,
                    Icons.block,
                    "❌ Verificación rechazada: revisa Mi Cuenta.",
                  )
                else if (showPendingBanner)
                  _buildTopBanner(
                    Colors.orange,
                    Icons.hourglass_top,
                    "⏳ Tu identidad está en revisión.",
                  )
                else if (pendingButIncomplete ||
                    identityStatus == "draft" ||
                    identityStatus == "none")
                  _buildTopBanner(
                    Colors.amber,
                    Icons.info_outline,
                    "⚠️ Termina tu cuenta para activar SKANO.",
                  ),

                _buildTopPanel(),

                if (!panelExpanded && !verySmallHeight) _buildSkanoHud(),

                if (!panelExpanded && !verySmallHeight) _buildEmergencyPanel(),

                _buildSpeedControl(),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: small ? 145 : 170,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.88),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: small ? 12 : 18,
                  right: small ? 12 : 18,
                  bottom: 14 + safeBottom,
                  child: _buildReportButton(neonBlue),
                ),
              ],
            ),
    );
  }

  Widget _buildTopBanner(Color color, IconData icon, String text) {
    final small = _isSmallPhone(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 10 : 13,
          ),
          color: color.withOpacity(0.95),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: small ? 19 : 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: small ? 12 : 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    final small = _isSmallPhone(context);
    final double topOffset = showAnyTopBanner ? (small ? 68.0 : 78.0) : 10.0;

    return Positioned(
      top: topOffset,
      left: small ? 12 : 16,
      right: small ? 12 : 16,
      child: GestureDetector(
        onTap: () => setState(() => panelExpanded = !panelExpanded),
        child: ScaleTransition(
          scale:
              panelExpanded ? const AlwaysStoppedAnimation(1) : _panelPulse,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: EdgeInsets.all(small ? 13 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.94),
                  const Color(0xFF07111F).withOpacity(0.94),
                ],
              ),
              borderRadius: BorderRadius.circular(small ? 20 : 24),
              border: Border.all(
                color: _levelColor().withOpacity(0.75),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _levelGlow(),
                  blurRadius: panelExpanded ? 18 : 28,
                  spreadRadius: panelExpanded ? 1 : 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: small ? 38 : 42,
                      height: small ? 38 : 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _levelColor().withOpacity(0.95),
                            _levelColor().withOpacity(0.38),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _levelGlow(),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _levelIcon(),
                        color: Colors.white,
                        size: small ? 20 : 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nivel $level",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _levelColor(),
                              fontSize: small ? 14.5 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "$comunidadUsuarios miembros en SKANO",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: small ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      panelExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white70,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (reportesAcertados / _nextLevelGoal())
                              .clamp(0.0, 1.0),
                          color: _levelColor(),
                          backgroundColor: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              "Validados",
                              "$reportesAcertados",
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniStat(
                              "Meta",
                              "${_nextLevelGoal()}",
                              Icons.flag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniStat(
                              "Enviados",
                              "$reportesEnviados",
                              Icons.send,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _motivationalText(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: small ? 12.5 : 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  crossFadeState: panelExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkanoHud() {
    final small = _isSmallPhone(context);
    final double top = showAnyTopBanner ? (small ? 146 : 164) : 92;

    return Positioned(
      top: top,
      left: small ? 10 : 16,
      right: small ? 10 : 16,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 9 : 11,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0A6CFF).withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A6CFF).withOpacity(0.16),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _hudItem(
                Icons.verified_user,
                "$comunidadUsuarios",
                "COMUNIDAD",
                const Color(0xFF0A6CFF),
              ),
            ),
            _hudDivider(),
            Expanded(
              child: _hudItem(
                Icons.document_scanner,
                "$revisionPatenteHoy",
                "PATENTE",
                Colors.amberAccent,
              ),
            ),
            _hudDivider(),
            Expanded(
              child: _hudItem(
                Icons.directions_walk,
                "$pasosHoy",
                "PASOS",
                Colors.greenAccent,
              ),
            ),
            _hudDivider(),
            Expanded(
              child: _hudItem(
                Icons.route,
                kilometrosHoy.toStringAsFixed(1),
                "KM",
                Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyPanel() {
    final small = _isSmallPhone(context);
    final double top = showAnyTopBanner ? (small ? 214 : 236) : 162;

    return Positioned(
      top: top,
      left: small ? 10 : 16,
      right: small ? 10 : 16,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _emergencyItem(
                Icons.local_police,
                "Carabineros",
                "133",
                Colors.lightBlueAccent,
              ),
            ),
            Expanded(
              child: _emergencyItem(
                Icons.policy,
                "PDI",
                "134",
                Colors.purpleAccent,
              ),
            ),
            Expanded(
              child: _emergencyItem(
                Icons.local_fire_department,
                "Bomberos",
                "132",
                Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyItem(
    IconData icon,
    String label,
    String number,
    Color color,
  ) {
    final small = _isSmallPhone(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: small ? 17 : 19),
        SizedBox(height: small ? 2 : 3),
        Text(
          number,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 12.5 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white54,
            fontSize: small ? 8.5 : 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _hudItem(IconData icon, String value, String label, Color color) {
    final small = _isSmallPhone(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: small ? 16 : 18),
        SizedBox(height: small ? 3 : 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 12.5 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white54,
            fontSize: small ? 7.8 : 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _hudDivider() {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withOpacity(0.12),
    );
  }

  Widget _buildSpeedControl() {
    final small = _isSmallPhone(context);
    final moving = currentSpeedKmh >= 5;
    final safeBottom = _safeBottom(context);

    return Positioned(
      right: small ? 12 : 16,
      bottom: (small ? 96 : 108) + safeBottom,
      child: Container(
        width: small ? 74 : 92,
        height: small ? 74 : 92,
        padding: EdgeInsets.symmetric(vertical: small ? 8 : 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.82),
          border: Border.all(
            color: moving ? Colors.orangeAccent : const Color(0xFF0A6CFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (moving ? Colors.orangeAccent : const Color(0xFF0A6CFF))
                  .withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, color: Colors.white70, size: small ? 15 : 18),
            const SizedBox(height: 2),
            Text(
              currentSpeedKmh.toStringAsFixed(0),
              style: TextStyle(
                color: Colors.white,
                fontSize: small ? 19 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              "KM/H",
              style: TextStyle(
                color: Colors.white54,
                fontSize: small ? 8.5 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              moving ? "MOV." : "DET.",
              style: TextStyle(
                color: moving ? Colors.orangeAccent : Colors.lightBlueAccent,
                fontSize: small ? 8 : 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    final small = _isSmallPhone(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.065),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _levelColor(), size: small ? 16 : 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: small ? 13 : 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white54,
              fontSize: small ? 9 : 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(Color neonBlue) {
    final small = _isSmallPhone(context);

    return Container(
      height: small ? 62 : 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(small ? 20 : 24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF2A2A),
            Color(0xFF0A6CFF),
            Color(0xFF003CFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.34),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: neonBlue.withOpacity(0.55),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(small ? 20 : 24),
          onTap: () => _handleReport(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: small ? 40 : 46,
                height: small ? 40 : 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: small ? 24 : 28,
                ),
              ),
              SizedBox(width: small ? 9 : 12),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REPORTAR VEHÍCULO",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: small ? 15.5 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Robado, sospechoso o patente detectada",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: small ? 10 : 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _windowsPlaceholder() {
    return const Center(
      child: Text(
        "Mapa no disponible en Windows",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}