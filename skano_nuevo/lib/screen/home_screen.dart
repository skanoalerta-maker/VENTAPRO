//============================================================================
// 📄 Archivo: home_screen.dart
// 📱 Pantalla principal de SKANO (Home)
// 🗺️ Incluye mapa, panel de nivel, botón de reporte y drawer
// 🖥️ En Windows muestra placeholder (Google Maps no soportado)
// 🔐 La identidad se valida SOLO al momento de reportar
// ✅ AJUSTADO: el registro ya NO depende de documentsCompleted
// ✅ AJUSTADO: antes de reportar valida GPS activo y permiso de ubicación
//============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../widgets/drawer_items.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  // ================= USER DATA =================
  String fullName = "Cargando...";
  int reportesEnviados = 0;
  int reportesAcertados = 0;
  String level = "BRONCE";
  String role = "user";

  // ================= SEGURIDAD =================
  bool blocked = false;
  String identityStatus = "none"; // none | draft | pending | approved | rejected
  Timestamp? sessionVerifiedUntil;

  // ✅ REGISTRO REAL PARA HOME
  bool faceRegistered = false;
  bool pinCreated = false;

  // ℹ️ DOCUMENTOS DE RETIRO / BANCARIOS (YA NO DEFINEN EL HOME)
  bool documentsCompleted = false;

  // ================= PANEL =================
  bool panelExpanded = false;
  bool userLoaded = false;

  // 🔥 NUEVO – animación sutil
  late AnimationController _panelPulseController;
  late Animation<double> _panelPulse;

  // ================= MAPA =================
  final Location location = Location();
  LatLng? userPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _userMarker;
  bool _didIntroAnimation = false;

  // 🔥 NUEVO – realtime
  StreamSubscription? _stolenSub;

  // ================= HELPERS DE ESTADO =================
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

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _initLocation();
    _listenStolenVehiclesRealtime();
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
    super.dispose();
  }

  // ================= MAPA – ICONO USUARIO =================
  Future<void> _loadUserMarker() async {
    final data = await rootBundle.load('assets/images/marker_user.png');

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 180,
    );

    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted) return;

    setState(() {
      _userMarker = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    });
  }

  // ================= FIRESTORE =================
  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    final data = doc.data() ?? {};
    int _i(v) => v is num ? v.toInt() : int.tryParse("$v") ?? 0;

    if (!mounted) return;

    final String userRole = (data["role"] ?? "user").toString();

    final rawStatus = (data["verification_status"] ?? "draft").toString();
    String normalizedStatus = rawStatus == "active" ? "approved" : rawStatus;

    // 🔥 BYPASS TOTAL PARA ADMIN
    if (userRole == "admin") {
      normalizedStatus = "approved";
    }

    final bool faceDone = data["faceRegistered"] == true;

    final bool hasPin =
        (data["report_pin_hash"] ?? "").toString().isNotEmpty ||
            data["pin_created_at"] != null;

    // ℹ️ Se mantiene solo como dato auxiliar para otros flujos
    final bool docsDone =
        data["documentsCompleted"] == true ||
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

  reportesEnviados = _i(data["reportes_enviados"]);
  reportesAcertados = _i(data["reportes_acertados"]);
  level = (data["level"] ?? "bronce").toUpperCase();

  blocked = data["blocked"] == true;

  identityStatus = normalizedStatus;

  sessionVerifiedUntil = data["session_verified_until"];

  faceRegistered = faceDone;
  pinCreated = hasPin;

  documentsCompleted = docsDone;

  // ✅ FIX REAL
  userLoaded = true;
});

}
  // ================= MAPA =================
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
    if (!mounted) return;

    setState(() {
      userPosition = LatLng(loc.latitude!, loc.longitude!);
    });

    _runIntroCameraIfReady();
  }

  // ================= GPS – VALIDACIÓN ANTES DE REPORTAR =================
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
            content: Text(
              "Debes mantener el GPS activado para reportar.",
            ),
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
            content: Text(
              "No se pudo confirmar tu ubicación. Intenta nuevamente.",
            ),
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
          content: Text(
            "No se pudo obtener tu ubicación actual. Mantén el GPS activado.",
          ),
        ),
      );

      return false;
    }
  }

  Future<void> _applyMapStyle() async {
    if (_mapController == null) return;

    try {
      final style = await rootBundle.loadString('assets/map_style_dark.json');
      debugPrint("✅ MAP STYLE LOADED (len=${style.length})");

      await _mapController!.setMapStyle(style);
      debugPrint("✅ MAP STYLE APPLIED");
    } catch (e) {
      debugPrint("❌ MAP STYLE ERROR: $e");
    }
  }

  void _runIntroCameraIfReady() {
    if (_didIntroAnimation) return;
    if (_mapController == null || userPosition == null) return;

    _didIntroAnimation = true;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(userPosition!, 16),
      );
    });
  }

  // ================= MARKERS REALTIME =================
  void _listenStolenVehiclesRealtime() {
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
      CameraUpdate.newLatLngZoom(userPosition!, 16),
    );
  }

  // ================= ADMIN =================
  Future<void> _tryOpenAdmin(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.data()?['role'] == 'admin') {
      Navigator.pushNamed(context, '/admin_dashboard');
    }
  }

  // ================= REPORTAR =================
  Future<void> _handleReport(BuildContext context) async {
    // 📍 GPS obligatorio antes de iniciar cualquier reporte
    final gpsOk = await _checkGPSBeforeReport();
    if (!gpsOk) return;

    // ⛔ Bloqueo de seguridad
    if (blocked) {
      Navigator.pushNamed(context, '/account_blocked', arguments: {
        'reason': 'selfie_fast_failed',
        'blocked_until': sessionVerifiedUntil?.toDate(),
        'adminComment': null,
      });
      return;
    }

    // 📝 Usuario aún no completa registro inicial
    if (identityStatus == "none" ||
        identityStatus == "draft" ||
        pendingButIncomplete) {
      Navigator.pushNamed(context, "/my_account");
      return;
    }

    // ❌ Rechazado
    if (identityStatus == "rejected") {
      Navigator.pushNamed(context, "/my_account");
      return;
    }

    // ⏳ En revisión real
    if (showPendingBanner && role != "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text("⏳ Tu identidad está en revisión."),
        ),
      );
      return;
    }

    // 🔐 Sesión expirada
    if (sessionVerifiedUntil == null ||
        sessionVerifiedUntil!.toDate().isBefore(DateTime.now())) {
      Navigator.pushNamed(context, "/session_verification");
      return;
    }

    // ✅ Todo OK → Reportar
    Navigator.pushNamed(context, "/report");
  }

  // ================= HELPERS =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    // ✅ ESPERAR CARGA REAL DE FIRESTORE
    if (!userLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: SkanoDrawer(
        userName: fullName,
        correctReports: reportesAcertados,
        totalReports: reportesEnviados,
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
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

                      Future.delayed(const Duration(milliseconds: 350), () async {
                        if (!mounted) return;
                        await _applyMapStyle();
                      });

                      _runIntroCameraIfReady();
                    },
                  ),
                ),

                if (userPosition == null)
                  const Center(child: CircularProgressIndicator()),

                // ✅ BANNERS
                if (identityStatus == "rejected")
                  _buildTopBanner(
                    Colors.redAccent,
                    Icons.block,
                    "❌ Verificación rechazada: revisa Mi Cuenta y vuelve a intentarlo.",
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
                    "⚠️ Termina de registrar tu cuenta para activar todas las funciones.",
                  ),

_buildTopPanel(),

Positioned(
  left: 16,
  right: 16,
  bottom: 0,
  child: SafeArea(
    top: false,
    minimum: const EdgeInsets.only(bottom: 12),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonBlue,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      onPressed: () => _handleReport(context),
      child: const Text(
        "🚨 Reportar vehículo robado",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),
  // ================= UI PARTS =================
  Widget _buildTopBanner(Color color, IconData icon, String text) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: color.withOpacity(0.95),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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
    final double topOffset = showAnyTopBanner ? 86.0 : 12.0;

    return Positioned(
      top: topOffset,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => panelExpanded = !panelExpanded),
        child: ScaleTransition(
          scale: panelExpanded
              ? const AlwaysStoppedAnimation(1)
              : _panelPulse,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _levelColor().withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: _levelGlow(),
                  blurRadius: panelExpanded ? 18 : 28,
                  spreadRadius: panelExpanded ? 1 : 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "🏆 Nivel $level",
                      style: TextStyle(
                        color: _levelColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      panelExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white70,
                    ),
                  ],
                ),
                if (panelExpanded) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (reportesAcertados / _nextLevelGoal())
                        .clamp(0.0, 1.0),
                    color: _levelColor(),
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$reportesAcertados / ${_nextLevelGoal()} reportes validados",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _motivationalText(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= WINDOWS =================
  Widget _windowsPlaceholder() {
    return const Center(
      child: Text(
        "Mapa no disponible en Windows",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
} 