import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_navigator.dart';
import 'report_selfie_screen.dart';

class ReportResultScreen extends StatefulWidget {
  const ReportResultScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color alertRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  State<ReportResultScreen> createState() => _ReportResultScreenState();
}

class _ReportResultScreenState extends State<ReportResultScreen> {
  Future<Map<String, dynamic>?> _loadVehicleData({
    required String stolenId,
    required String plate,
  }) async {
    if (stolenId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('stolen_vehicles')
          .doc(stolenId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...?doc.data(),
        };
      }
    }

    final snap = await FirebaseFirestore.instance
        .collection('stolen_vehicles')
        .where('plate', isEqualTo: plate)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final String plate = (args?['plate'] ?? '---').toString().toUpperCase();
    final bool isStolen = args?['isStolen'] ?? false;

    final String fallbackVehiclePhotoUrl =
        (args?['vehiclePhotoUrl'] ?? args?['vehicle_photo_url'] ?? '')
            .toString()
            .trim();

    final String stolenId = (args?['stolenId'] ??
            args?['id'] ??
            args?['vehicleId'] ??
            '')
        .toString()
        .trim();

    if (!isStolen) {
      return AnimatedResultWrapper(
        isStolen: isStolen,
        child: _ResultNotStolenView(plate: plate),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadVehicleData(
        stolenId: stolenId,
        plate: plate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: ReportResultScreen.alertRed,
              ),
            ),
          );
        }

        final dbData = snapshot.data ?? {};

        final String finalVehiclePhotoUrl = (dbData['vehiclePhotoUrl'] ??
                dbData['vehicle_photo_url'] ??
                dbData['photoUrl'] ??
                fallbackVehiclePhotoUrl)
            .toString()
            .trim();

        final String finalStolenId = (dbData['id'] ?? stolenId).toString();

        final Map<String, dynamic> vehicle = {
          "id": finalStolenId.isNotEmpty ? finalStolenId : "stolen_manual",
          "plate": plate,
          "source": "stolen_vehicles",
          "vehiclePhotoUrl": finalVehiclePhotoUrl,
          "vehicle_photo_url": finalVehiclePhotoUrl,
          "owner_uid": dbData['owner_uid'] ?? args?['owner_uid'],
          "brand": dbData['brand'] ?? args?['brand'],
          "model": dbData['model'] ?? args?['model'],
          "year": dbData['year'] ?? args?['year'],
          "color": dbData['color'] ??
              dbData['vehicle_color'] ??
              dbData['car_color'] ??
              args?['color'],
        };

        return AnimatedResultWrapper(
          isStolen: isStolen,
          child: _ResultStolenView(
            plate: plate,
            vehicle: vehicle,
            vehiclePhotoUrl: finalVehiclePhotoUrl,
            stolenId: finalStolenId,
          ),
        );
      },
    );
  }
}

class AnimatedResultWrapper extends StatefulWidget {
  final Widget child;
  final bool isStolen;

  const AnimatedResultWrapper({
    super.key,
    required this.child,
    required this.isStolen,
  });

  @override
  State<AnimatedResultWrapper> createState() => _AnimatedResultWrapperState();
}

class _AnimatedResultWrapperState extends State<AnimatedResultWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 380));

    try {
      if (widget.isStolen) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {}

    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            await skanoNavigatorKey.currentState?.maybePop();
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
        ),
        const Expanded(
          child: Text(
            "Resultado de verificación",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateCard extends StatelessWidget {
  final String plate;
  final Color glowColor;

  const _PlateCard({
    required this.plate,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.16),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "PATENTE CONSULTADA",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plate,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDataCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const _VehicleDataCard({
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final brand = (vehicle['brand'] ?? 'Sin marca').toString().trim();
    final model = (vehicle['model'] ?? 'Sin modelo').toString().trim();
    final year = (vehicle['year'] ?? 'Sin año').toString().trim();
    final color = (vehicle['color'] ?? 'Sin color').toString().trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ReportResultScreen.alertRed.withOpacity(0.30),
            const Color(0xFF111827),
            Colors.black.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ReportResultScreen.alertRed.withOpacity(0.70),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ReportResultScreen.alertRed.withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VEHÍCULO DETECTADO',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      brand.isEmpty ? 'SIN MARCA' : brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      model.isEmpty ? 'SIN MODELO' : model.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StrongVehicleBox(
                  icon: Icons.calendar_month_rounded,
                  label: 'AÑO',
                  value: year,
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StrongVehicleBox(
                  icon: Icons.palette_rounded,
                  label: 'COLOR',
                  value: color.toUpperCase(),
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrongVehicleBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StrongVehicleBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'Sin dato' : value.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            cleanValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMiniChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VehicleMiniChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cleanText = text.trim().isEmpty ? 'Sin dato' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 15),
          const SizedBox(width: 5),
          Text(
            cleanText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingAlertIcon extends StatefulWidget {
  const _PulsingAlertIcon();

  @override
  State<_PulsingAlertIcon> createState() => _PulsingAlertIconState();
}

class _PulsingAlertIconState extends State<_PulsingAlertIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(
        Icons.warning_rounded,
        size: 76,
        color: ReportResultScreen.alertRed,
      ),
    );
  }
}

class _ResultStolenView extends StatelessWidget {
  final String plate;
  final Map<String, dynamic> vehicle;
  final String vehiclePhotoUrl;
  final String stolenId;

  const _ResultStolenView({
    required this.plate,
    required this.vehicle,
    required this.vehiclePhotoUrl,
    required this.stolenId,
  });

  Future<String?> _askReason(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "¿Por qué no reportarás?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const _ReasonTile(
                  label: "Fue un error / no era este vehículo",
                  value: "mistake",
                ),
                const _ReasonTile(
                  label: "No puedo reportar ahora (seguridad / tiempo)",
                  value: "cannot_now",
                ),
                const _ReasonTile(
                  label: "No quiero reportar (esto afecta mi cuenta)",
                  value: "dont_want",
                  danger: true,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const alertRed = ReportResultScreen.alertRed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              alertRed.withOpacity(0.12),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                const _ResultHeader(),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: alertRed.withOpacity(0.14),
                            boxShadow: [
                              BoxShadow(
                                color: alertRed.withOpacity(0.18),
                                blurRadius: 28,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const _PulsingAlertIcon(),
                        ),
                        const SizedBox(height: 18),
                        const _StatusChip(
                          icon: Icons.gpp_bad_rounded,
                          text: "ALERTA ACTIVA",
                          color: alertRed,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "ENCARGO ACTIVO DETECTADO",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "SKANO detectó un registro activo asociado a esta patente.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _PlateCard(
                          plate: plate,
                          glowColor: alertRed,
                        ),
                        const SizedBox(height: 14),
                        _VehicleDataCard(vehicle: vehicle),
                        const SizedBox(height: 18),
                        if (vehiclePhotoUrl.isNotEmpty) ...[
                          _VehiclePhotoCard(url: vehiclePhotoUrl),
                          const SizedBox(height: 12),
                          const Text(
                            "Referencia visual del vehículo registrada por el dueño.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ] else ...[
                          const _InfoPanel(
                            icon: Icons.image_not_supported_outlined,
                            title: "Sin referencia fotográfica",
                            text:
                                "Este registro no tiene imagen asociada, pero sigue figurando con encargo por robo activo.",
                            accent: Colors.white70,
                          ),
                          const SizedBox(height: 18),
                        ],
                        const _InfoPanel(
                          icon: Icons.shield_outlined,
                          title: "Antes de reportar",
                          text:
                              "Verifica visualmente el vehículo, marca, modelo, año, color y asegúrate de estar en un lugar seguro. El siguiente paso solicitará selfie y validación antes de enviar el reporte.",
                          accent: alertRed,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: alertRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "REPORTAR VEHÍCULO",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportSelfieScreen(
                                    nextRoute: '/report_declaration',
                                    reportDraft: {
                                      "vehicle": vehicle,
                                      "stolenId": stolenId,
                                      "plate": plate,
                                      "vehiclePhotoUrl": vehiclePhotoUrl,
                                      "vehicle_photo_url": vehiclePhotoUrl,
                                      "source": "stolen_vehicles",
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text(
                              "CANCELAR E INDICAR MOTIVO",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            onPressed: () async {
                              final reason = await _askReason(context);
                              if (reason == null) return;

                              await skanoPushNamedAndRemoveUntil(
                                context,
                                '/report',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultNotStolenView extends StatelessWidget {
  final String plate;

  const _ResultNotStolenView({
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    const successGreen = ReportResultScreen.successGreen;
    const neonBlue = ReportResultScreen.neonBlue;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              successGreen.withOpacity(0.10),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                const _ResultHeader(),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: successGreen.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: successGreen.withOpacity(0.18),
                                blurRadius: 28,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 76,
                            color: successGreen,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _StatusChip(
                          icon: Icons.check_circle_rounded,
                          text: "SIN ALERTA ACTIVA",
                          color: successGreen,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "VERIFICADO",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sin encargo por robo",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: successGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _PlateCard(
                          plate: plate,
                          glowColor: successGreen,
                        ),
                        const SizedBox(height: 18),
                        const _InfoPanel(
                          icon: Icons.fact_check_outlined,
                          title: "Resultado de búsqueda",
                          text:
                              "No existe un registro activo de robo asociado a esta patente dentro de SKANO en este momento.",
                          accent: successGreen,
                        ),
                        const SizedBox(height: 14),
                        const _InfoPanel(
                          icon: Icons.travel_explore_rounded,
                          title: "Puedes seguir verificando",
                          text:
                              "Continúa consultando otras patentes en tiempo real. Esto ayuda a mantener la comunidad informada y atenta.",
                          accent: neonBlue,
                        ),
                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, color: Colors.black),
                    label: const Text(
                      "BUSCAR OTRA PATENTE",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    onPressed: () async {
                      await skanoPushNamedAndRemoveUntil(
                        context,
                        '/report',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehiclePhotoCard extends StatelessWidget {
  final String url;
  const _VehiclePhotoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.55),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 10),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final total = progress.expectedTotalBytes;
            final loaded = progress.cumulativeBytesLoaded;
            final value = (total == null || total == 0) ? null : loaded / total;

            return Container(
              color: const Color(0xFF0B1220),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(value: value),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF0B1220),
            child: const Center(
              child: Text(
                "No se pudo cargar la foto.",
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _ReasonTile({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.pop(context, value),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.redAccent : Colors.white,
          fontWeight: danger ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
    );
  }
}