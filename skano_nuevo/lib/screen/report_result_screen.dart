import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ NAV ÚNICO
import '../app_navigator.dart';
import 'report_selfie_screen.dart';

/// =======================================================
/// RESULTADO DE BÚSQUEDA DE PATENTE – SKANO
/// ✅ Si isStolen = true, muestra foto del vehículo (si viene en args)
/// ✅ BOTÓN REPORTAR → SELFIE → DECLARACIÓN
/// ✅ UX 9.5: animación + haptic feedback + glow + mejor jerarquía
/// =======================================================
class ReportResultScreen extends StatelessWidget {
  const ReportResultScreen({super.key});

  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color alertRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final String plate = (args?['plate'] ?? '---').toString().toUpperCase();
    final bool isStolen = args?['isStolen'] ?? false;

    final String vehiclePhotoUrl =
        (args?['vehiclePhotoUrl'] ?? args?['vehicle_photo_url'] ?? '')
            .toString()
            .trim();

    final String stolenId = (args?['stolenId'] ??
            args?['id'] ??
            args?['vehicleId'] ??
            '')
        .toString()
        .trim();

    final Map<String, dynamic> vehicle = {
      "id": stolenId.isNotEmpty ? stolenId : "stolen_manual",
      "plate": plate,
      "source": args?['source'] ?? "stolen_vehicles",
      "vehiclePhotoUrl": vehiclePhotoUrl,
      "vehicle_photo_url": vehiclePhotoUrl,
      if (args?['owner_uid'] != null) "owner_uid": args?['owner_uid'],
      if (args?['brand'] != null) "brand": args?['brand'],
      if (args?['model'] != null) "model": args?['model'],
      if (args?['color'] != null) "color": args?['color'],
    };

    return AnimatedResultWrapper(
      isStolen: isStolen,
      child: isStolen
          ? _ResultStolenView(
              plate: plate,
              vehicle: vehicle,
              vehiclePhotoUrl: vehiclePhotoUrl,
              stolenId: stolenId,
            )
          : _ResultNotStolenView(plate: plate),
    );
  }
}

/// =======================================================
/// WRAPPER ANIMADO + HAPTIC FEEDBACK
/// =======================================================
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

/// =======================================================
/// HEADER
/// =======================================================
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

/// =======================================================
/// CHIP ESTADO
/// =======================================================
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

/// =======================================================
/// CARD PATENTE
/// =======================================================
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

/// =======================================================
/// PANEL INFO
/// =======================================================
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

/// =======================================================
/// ICONO PULSANTE ROJO
/// =======================================================
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

/// =======================================================
/// VISTA ROJA
/// =======================================================
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
                              "Verifica visualmente el vehículo y asegúrate de estar en un lugar seguro. El siguiente paso solicitará selfie y validación antes de enviar el reporte.",
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

/// =======================================================
/// VISTA VERDE
/// =======================================================
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

/// =======================================================
/// CARD FOTO VEHÍCULO
/// =======================================================
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

/// =======================================================
/// ITEM DE MOTIVO
/// =======================================================
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