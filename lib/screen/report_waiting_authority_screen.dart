import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class ReportWaitingAuthorityScreen extends StatefulWidget {
  final String reportId;
  final bool suspectedClone;

  const ReportWaitingAuthorityScreen({
    super.key,
    required this.reportId,
    this.suspectedClone = false,
  });

  @override
  State<ReportWaitingAuthorityScreen> createState() =>
      _ReportWaitingAuthorityScreenState();
}

class _ReportWaitingAuthorityScreenState
    extends State<ReportWaitingAuthorityScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color skanoCyan = Color(0xFF00D5FF);
  static const Color skanoGreen = Color(0xFF00E5A0);
  static const Color skanoOrange = Color(0xFFFFB547);
  static const Color bgBlack = Color(0xFF030712);
  static const Color cardDark = Color(0xFF0B1220);

  File? finalPhoto;
  File? vinPhoto;

  bool sending = false;
  bool sendingVin = false;
  bool markingVehicleLeft = false;

  String? vinPhotoUrl;

  final ImagePicker picker = ImagePicker();

  Future<void> _takeFinalPhoto() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 72,
    );

    if (file != null) {
      setState(() => finalPhoto = File(file.path));
    }
  }

  Future<void> _takeVinPhoto() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 72,
    );

    if (file != null) {
      setState(() => vinPhoto = File(file.path));
    }
  }

  Future<void> _uploadVinPhoto() async {
    if (vinPhoto == null) {
      _snack(
        'Primero toma una foto del parabrisas donde se observe el VIN.',
        isError: true,
      );
      return;
    }

    setState(() => sendingVin = true);

    try {
      final ref = FirebaseStorage.instance.ref(
        'reports/${widget.reportId}/vin_${DateTime.now().millisecondsSinceEpoch}${path.extension(vinPhoto!.path)}',
      );

      await ref.putFile(vinPhoto!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'clone_vin_photo_url': url,
        'clone_vin_uploaded': true,
        'clone_vin_uploaded_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => vinPhotoUrl = url);

      _snack('Foto VIN enviada correctamente ✅');
    } catch (e) {
      _snack('Error al subir foto VIN: $e', isError: true);
    } finally {
      if (mounted) setState(() => sendingVin = false);
    }
  }

  Future<void> _markVehicleLeftScene() async {
    if (markingVehicleLeft || sending) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '¿El vehículo se fue?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'Usa esta opción solo si el vehículo abandonó el lugar o ya no se encuentra visible.\n\n'
          'No lo sigas, no lo persigas y mantente en un lugar seguro.',
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
              'Informar',
              style: TextStyle(
                color: skanoOrange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => markingVehicleLeft = true);

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'vehicle_left_scene': true,
        'vehicle_left_scene_at': FieldValue.serverTimestamp(),
        'vehicle_left_scene_note':
            'El reportante informó que el vehículo abandonó el lugar o ya no se encuentra visible.',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _snack('Se informó que el vehículo ya no está en el lugar.');

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      _snack('No se pudo informar que el vehículo se fue: $e', isError: true);
    } finally {
      if (mounted) setState(() => markingVehicleLeft = false);
    }
  }

  Future<void> _closeReport() async {
    if (finalPhoto == null) {
      _snack(
        'Para cerrar el reporte debes tomar una foto que confirme que la autoridad tiene el vehículo.',
        isError: true,
      );
      return;
    }

    setState(() => sending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance.ref(
        'reports/${widget.reportId}/authority_${DateTime.now().millisecondsSinceEpoch}${path.extension(finalPhoto!.path)}',
      );

      await ref.putFile(finalPhoto!);
      final finalPhotoUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'status': 'closed',
        'authority_confirmed': true,
        'final_photo_url': finalPhotoUrl,
        'closed_by': uid,
        'closed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reporte cerrado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Gracias por tu ayuda.\n\n'
            'El reporte fue cerrado correctamente tras la confirmación de la autoridad competente.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (_) => false);
              },
              child: const Text(
                'Finalizar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('Error al cerrar reporte: $e', isError: true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1F2937),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color borderColor = Colors.white12,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101A2E),
            Color(0xFF08111F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String text,
    Color color = skanoOrange,
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
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
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
    IconData icon = Icons.arrow_forward_rounded,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? const Color(0xFF263244) : color,
          foregroundColor: onPressed == null ? Colors.white38 : Colors.black,
          elevation: onPressed == null ? 0 : 8,
          shadowColor: color.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
            : Icon(icon),
        label: Text(
          loading ? 'Procesando...' : label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _photoBox({
    required File? photo,
    required VoidCallback onTap,
    required String emptyText,
    required IconData icon,
    Color color = neonBlue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 178,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.9)),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white10,
        ),
        child: photo == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 54, color: Colors.white38),
                    const SizedBox(height: 10),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  photo,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SKANO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Reporte en observación',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgBlack,
              Color(0xFF050816),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  borderColor: neonBlue.withOpacity(0.28),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: neonBlue.withOpacity(0.14),
                          border: Border.all(color: neonBlue.withOpacity(0.55)),
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          size: 34,
                          color: neonBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Reporte inicial enviado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tu reporte fue enviado correctamente al sistema.\n\n'
                        'Mantente en un lugar seguro. No enfrentes a terceros, no intentes recuperar el vehículo y no sigas el vehículo si se mueve.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _infoBox(
                  icon: Icons.security_rounded,
                  color: skanoGreen,
                  text:
                      'SKANO registra la información del reporte, pero no reemplaza a Carabineros, PDI ni Seguridad Ciudadana. Actúa siempre con prudencia.',
                ),
                _card(
  borderColor: skanoCyan.withOpacity(0.25),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Row(
        children: [
          Icon(
            Icons.gps_fixed_rounded,
            color: skanoCyan,
            size: 26,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Última ubicación registrada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      _infoBox(
        icon: Icons.location_on_rounded,
        color: skanoCyan,
        text:
            'Esta fue la última ubicación registrada por el usuario al momento del reporte inicial.',
      ),

      const SizedBox(height: 14),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: skanoCyan.withOpacity(0.35),
          ),
        ),
        child: Column(
          children: [

            const Icon(
              Icons.map_rounded,
              color: skanoCyan,
              size: 46,
            ),

            const SizedBox(height: 10),

            const Text(
              'Ubicación del reporte almacenada correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 14),

            _primaryButton(
              label: 'ABRIR UBICACIÓN EN GOOGLE MAPS',
              icon: Icons.navigation_rounded,
              color: skanoCyan,
              loading: false,
              onPressed: () async {

                final reportSnap = await FirebaseFirestore.instance
                    .collection('reports')
                    .doc(widget.reportId)
                    .get();

                final data = reportSnap.data();

                if (data == null) return;

                final GeoPoint? geo = data['location'];

                if (geo == null) {
                  _snack(
                    'No se encontró ubicación registrada.',
                    isError: true,
                  );
                  return;
                }

                final lat = geo.latitude;
                final lng = geo.longitude;

                final url = Uri.parse(
                  'https://maps.google.com/?q=$lat,$lng',
                );

                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ),
    ],
  ),
),

const SizedBox(height: 14),
                const SizedBox(height: 14),
                if (widget.suspectedClone) ...[
                  _card(
                    borderColor: skanoOrange.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              color: skanoOrange,
                              size: 26,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Protocolo patente clonada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoBox(
                          icon: Icons.car_repair_rounded,
                          color: skanoOrange,
                          text:
                              'Si es seguro hacerlo, toma una foto del parabrisas por el lado del conductor. En muchos vehículos ahí se observa el VIN o número de chasis.',
                        ),
                        const SizedBox(height: 14),
                        _photoBox(
                          photo: vinPhoto,
                          onTap: _takeVinPhoto,
                          emptyText: 'Toca para tomar foto del VIN',
                          icon: Icons.camera_alt_rounded,
                          color: skanoOrange,
                        ),
                        const SizedBox(height: 12),
                        _primaryButton(
                          label: vinPhotoUrl != null
                              ? 'FOTO VIN ENVIADA ✅'
                              : 'ENVIAR FOTO VIN',
                          icon: Icons.cloud_upload_rounded,
                          color: skanoOrange,
                          loading: sendingVin,
                          onPressed: vinPhoto == null || vinPhotoUrl != null
                              ? null
                              : _uploadVinPhoto,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No te acerques si hay personas cerca o si existe cualquier riesgo. La seguridad está primero.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _card(
                  borderColor: skanoGreen.withOpacity(0.28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: skanoGreen,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Confirmación con autoridad',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoBox(
                        icon: Icons.local_police_rounded,
                        color: skanoGreen,
                        text:
                            'Solo toma esta foto si la autoridad competente ya tiene el vehículo bajo su control.',
                      ),
                      const SizedBox(height: 14),
                      _photoBox(
                        photo: finalPhoto,
                        onTap: _takeFinalPhoto,
                        emptyText:
                            'Toca para tomar foto con autoridad presente',
                        icon: Icons.photo_camera_back_rounded,
                        color: skanoGreen,
                      ),
                      const SizedBox(height: 14),
                      _primaryButton(
                        label: 'LA AUTORIDAD TOMÓ EL VEHÍCULO',
                        icon: Icons.check_circle_rounded,
                        color: skanoGreen,
                        loading: sending,
                        onPressed: sending ? null : _closeReport,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  borderColor: skanoOrange.withOpacity(0.30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: skanoOrange,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¿El vehículo se fue?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Si el vehículo abandonó el lugar o ya no está visible, informa esta situación y no lo sigas.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _primaryButton(
                        label: 'EL VEHÍCULO SE FUE / YA NO ESTÁ AQUÍ',
                        icon: Icons.directions_car_filled_rounded,
                        color: skanoOrange,
                        loading: markingVehicleLeft,
                        onPressed: markingVehicleLeft
                            ? null
                            : _markVehicleLeftScene,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: sending || sendingVin || markingVehicleLeft
                      ? null
                      : () {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/home', (_) => false);
                        },
                  child: const Text(
                    'Salir sin cerrar el reporte',
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w700,
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