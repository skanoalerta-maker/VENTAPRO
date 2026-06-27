import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertMapScreen extends StatefulWidget {
  const AlertMapScreen({super.key});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen>
    with TickerProviderStateMixin {
  // ===================================================
  // ✅ Controller del mapa (para mover cámara / zoom)
  // ===================================================
  final Completer<GoogleMapController> _controller = Completer();

  // ===================================================
  // ✅ Location plugin (posición del usuario)
  // ===================================================
  Location location = Location();
  LocationData? userLocation;

  // ===================================================
  // ✅ Animación (fade-in elegante al cargar)
  // ===================================================
  late AnimationController fadeController;
  late Animation<double> fadeIn;

  // ===================================================
  // ✅ Filtro de distancia de alertas (metros)
  // ===================================================
  final double maxDistanceMeters = 5000;

  // ===================================================
  // ✅ NUEVO: Recorrido del usuario (Polyline)
  // ===================================================
  final List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};

  // ===================================================
  // ✅ NUEVO: Throttle para no saturar GPS / UI
  // ===================================================
  StreamSubscription<LocationData>? _locSub;

  @override
  void initState() {
    super.initState();

    // 1) Pedir ubicación + empezar a escuchar cambios para la ruta
    _initLocationTracking();

    // 2) Fade-in UI
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    fadeIn = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );

    fadeController.forward();
  }

  @override
  void dispose() {
    // ✅ Cerrar subscripción de ubicación (evita fugas de memoria)
    _locSub?.cancel();
    fadeController.dispose();
    super.dispose();
  }

  // ===================================================
  // 📍 UBICACIÓN + TRACKING DE RUTA (Polyline)
  // - Pide permisos
  // - Obtiene ubicación inicial
  // - Escucha cambios para dibujar recorrido
  // ===================================================
  Future<void> _initLocationTracking() async {
    bool enabled = await location.serviceEnabled();
    if (!enabled) {
      enabled = await location.requestService();
      if (!enabled) return;
    }

    PermissionStatus perm = await location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await location.requestPermission();
      if (perm != PermissionStatus.granted) return;
    }

    // ✅ Ubicación inicial
    final first = await location.getLocation();
    _applyNewLocation(first);

    // ✅ Config GPS (mejor UX, no sobrecarga)
    await location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2500, // ms
      distanceFilter: 8, // metros mínimos para agregar punto
    );

    // ✅ Escuchar cambios (ruta)
    _locSub?.cancel();
    _locSub = location.onLocationChanged.listen((loc) {
      _applyNewLocation(loc);
    });
  }

  // ===================================================
  // ✅ Aplica ubicación y actualiza polyline
  // - Guarda puntos del recorrido
  // - Recalcula polylines
  // ===================================================
  void _applyNewLocation(LocationData loc) {
    if (!mounted) return;

    userLocation = loc;

    if (loc.latitude != null && loc.longitude != null) {
      final p = LatLng(loc.latitude!, loc.longitude!);

      // Evita duplicar puntos iguales (ruido GPS)
      if (_routePoints.isEmpty ||
          (_routePoints.last.latitude != p.latitude ||
              _routePoints.last.longitude != p.longitude)) {
        _routePoints.add(p);

        _polylines = {
          Polyline(
            polylineId: const PolylineId("user_route"),
            points: _routePoints,
            width: 6,
            color: Colors.greenAccent,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      }
    }

    setState(() {});
  }

  // ===================================================
  // 🔐 SEGURIDAD PARA REPORTAR (PIN 30 MIN + IDENTIDAD)
  // - NO TOCADO (solo se mantiene igual)
  // ===================================================
  Future<void> _secureReportFlow(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushNamed(context, "/welcome");
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!snap.exists) return;

    final data = snap.data() ?? {};
    final now = DateTime.now();

    // 🚫 Bloqueo
    if (data["blocked"] == true) {
      Navigator.pushNamed(context, "/account_blocked", arguments: {
        "reason": data["blocked_reason"] ?? "Bloqueo por seguridad",
        "blockedUntil": data["blocked_until"]?.toDate(),
      });
      return;
    }

// ✅ Identidad debe estar APROBADA (coherente con tu sistema real)
final st = (data["verification_status"] ?? "draft").toString();
final isVerified = st == "approved" || st == "active";

if (!isVerified) {
  Navigator.pushNamed(context, "/review_pending");
  return;
}

    // 🔐 PIN cada 30 min: session_verified_until
    final Timestamp? untilTs = data["session_verified_until"] as Timestamp?;
    final sessionValid = untilTs != null && untilTs.toDate().isAfter(now);

    if (!sessionValid) {
      Navigator.pushNamed(context, "/session_verification");
      return;
    }

    // ✅ OK: entra al flujo normal de reportar
    Navigator.pushNamed(context, "/report_method");
  }

  // ===================================================
  // ⭐ STREAM Firestore (alertas cercanas)
  // ===================================================
  Stream<List<Map<String, dynamic>>> getAlertsStream() {
    return FirebaseFirestore.instance.collection("reporters").snapshots().map(
      (query) {
        return query.docs.map((doc) {
          final data = doc.data();
          return {
            "plate": data["plate"] ?? "SIN PATENTE",
            "brand": data["brand"] ?? "Vehículo",
            "color": data["color"] ?? "Color desconocido",
            "lat": data["location"]["lat"],
            "lng": data["location"]["lng"],
          };
        }).toList();
      },
    );
  }

  // ===================================================
  // ⭐ Distancia real (Haversine)
  // ===================================================
  double calculateDistance(lat1, lon1, lat2, lon2) {
    const earthRadius = 6371000; // metros
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    const Color neonYellow = Color(0xFFFFD740);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Alertas Cercanas",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: userLocation == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: getAlertsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // ===================================================
                // ✅ Filtrar alertas por distancia al usuario
                // ===================================================
                final filteredAlerts = snapshot.data!.where((alert) {
                  double distance = calculateDistance(
                    userLocation!.latitude!,
                    userLocation!.longitude!,
                    alert["lat"],
                    alert["lng"],
                  );
                  return distance <= maxDistanceMeters;
                }).toList();

                // ===================================================
                // ✅ Marcadores de alertas
                // ===================================================
                final Set<Marker> markers = filteredAlerts.map((alert) {
                  return Marker(
                    markerId: MarkerId(alert["plate"]),
                    position: LatLng(alert["lat"], alert["lng"]),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueYellow,
                    ),
                    infoWindow: InfoWindow(
                      title: "Patente: ${alert["plate"]}",
                      snippet: "${alert["brand"]} - ${alert["color"]}",
                    ),
                  );
                }).toSet();

                return FadeTransition(
                  opacity: fadeIn,
                  child: Stack(
                    children: [
                      // ===================================================
                      // 🌍 MAPA GOOGLE (MEJORADO)
                      // - Estilo oscuro real (JSON)
                      // - Polyline de recorrido
                      // - Sin botones default (ponemos los pro)
                      // ===================================================
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            userLocation!.latitude!,
                            userLocation!.longitude!,
                          ),
                          zoom: 15,
                        ),
                        markers: markers,
                        polylines: _polylines,
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (GoogleMapController controller) async {
                          _controller.complete(controller);

                          // ✅ Estilo de mapa oscuro profesional
                          try {
                            final style =
                                await DefaultAssetBundle.of(context).loadString(
                              'assets/map_style_dark.json',
                            );
                            controller.setMapStyle(style);
                          } catch (_) {
                            // Si no existe el asset, el mapa igual funciona
                          }
                        },
                      ),

                      // ===================================================
                      // ✅ BOTONES FLOTANTES PRO (Waze-like)
                      // ===================================================
                      Positioned(
                        right: 16,
                        bottom: 190,
                        child: Column(
                          children: [
                            _mapButton(
                              hero: "my_location_btn",
                              icon: Icons.my_location,
                              onTap: () async {
                                final c = await _controller.future;
                                c.animateCamera(
                                  CameraUpdate.newLatLng(
                                    LatLng(
                                      userLocation!.latitude!,
                                      userLocation!.longitude!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _mapButton(
                              hero: "layers_btn",
                              icon: Icons.layers,
                              onTap: () {
                                // Futuro: capas/heatmap
                              },
                            ),
                          ],
                        ),
                      ),

                      // ===================================================
                      // ⭐ TARJETAS DE ALERTAS (NO TOCADO)
                      // ===================================================
                      Positioned(
                        bottom: 110,
                        child: SizedBox(
                          height: 160,
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredAlerts.length,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemBuilder: (context, index) {
                              return _alertCard(filteredAlerts[index]);
                            },
                          ),
                        ),
                      ),

                      // ===================================================
                      // ⭐ BOTÓN REPORTAR (seguridad intacta)
                      // ===================================================
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonYellow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _secureReportFlow(context),
                            child: const Text(
                              "REPORTAR AVISTAMIENTO",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ===================================================
  // 🧭 Botón flotante pro (negro + borde sutil)
  // ===================================================
  Widget _mapButton({
    required String hero,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FloatingActionButton(
      heroTag: hero,
      mini: true,
      backgroundColor: Colors.black,
      elevation: 8,
      onPressed: onTap,
      child: Icon(icon, color: Colors.white),
    );
  }

  // ---------------------------------------------------
  //  TARJETA PREMIUM (NO TOCADA)
  // ---------------------------------------------------
  Widget _alertCard(Map<String, dynamic> alert) {
    const Color neonYellow = Color(0xFFFFD740);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonYellow, width: 2),
        boxShadow: [
          BoxShadow(
            color: neonYellow.withOpacity(0.7),
            blurRadius: 25,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Patente: ${alert["plate"]}",
            style: const TextStyle(
              color: neonYellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert["brand"],
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            "Color: ${alert["color"]}",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 15),

          // IR AL MAPA (NO TOCADO)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: neonYellow),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final GoogleMapController controller = await _controller.future;
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(alert["lat"], alert["lng"]),
                  16,
                ),
              );
            },
            child: const Text(
              "Ver en el mapa",
              style: TextStyle(color: neonYellow),
            ),
          ),
        ],
      ),
    );
  }
}
