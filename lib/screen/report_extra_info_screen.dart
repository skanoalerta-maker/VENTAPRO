import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ReportExtraInfoScreen extends StatefulWidget {
  final String reportId;
  final String plate;

  const ReportExtraInfoScreen({
    super.key,
    required this.reportId,
    required this.plate,
  });

  @override
  State<ReportExtraInfoScreen> createState() => _ReportExtraInfoScreenState();
}

class _ReportExtraInfoScreenState extends State<ReportExtraInfoScreen> {
  static const Color bgBlack = Color(0xFF030712);
  static const Color cardDark = Color(0xFF0B1220);
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color red = Color(0xFFFF2D2D);
  static const Color green = Color(0xFF00E5A0);
  static const Color orange = Color(0xFFFFB547);

  final ImagePicker picker = ImagePicker();
  final TextEditingController noteCtrl = TextEditingController();

  final List<File> photos = [];
  File? videoFile;

  bool uploading = false;

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (photos.length >= 2) {
      _snack("Solo puedes agregar hasta 2 fotos adicionales.", true);
      return;
    }

    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 70,
    );

    if (file != null) setState(() => photos.add(File(file.path)));
  }

  Future<void> _takeVideo() async {
    final XFile? file = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 20),
    );

    if (file != null) setState(() => videoFile = File(file.path));
  }

  Future<String> _uploadFile(File file, String folder) async {
    final ref = FirebaseStorage.instance.ref(
      'reports/${widget.reportId}/extra/$folder/${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _sendExtraInfo() async {
    if (photos.isEmpty && videoFile == null && noteCtrl.text.trim().isEmpty) {
      _snack("Agrega una foto, video o comentario antes de enviar.", true);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => uploading = true);

    try {
      final List<String> photoUrls = [];

      for (final photo in photos) {
        photoUrls.add(await _uploadFile(photo, "photos"));
      }

      String? videoUrl;
      if (videoFile != null) {
        videoUrl = await _uploadFile(videoFile!, "video");
      }

      await FirebaseFirestore.instance.collection("report_extra_evidence").add({
        "report_id": widget.reportId,
        "plate": widget.plate.toUpperCase(),
        "uid": uid,
        "photo_urls": photoUrls,
        "video_url": videoUrl,
        "note": noteCtrl.text.trim(),
        "admin_review_required": true,
        "owner_share_status": "pending_admin_review",
        "owner_notified": false,
        "created_at": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId)
          .set({
        "has_extra_evidence": true,
        "extra_evidence_pending_admin": true,
        "extra_evidence_updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "extra_photos_uploaded_count": FieldValue.increment(photoUrls.length),
        "videos_uploaded_count":
            videoUrl == null ? FieldValue.increment(0) : FieldValue.increment(1),
        "reports_sent_to_admin_count": FieldValue.increment(1),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _snack("Información adicional enviada a SKANO ✅", false);
      Navigator.pop(context);
    } catch (e) {
      _snack("Error enviando información: $e", true);
    }

    if (mounted) setState(() => uploading = false);
  }

  void _snack(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  bool get _canSend =>
      !uploading &&
      (photos.isNotEmpty || videoFile != null || noteCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SKANO",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              "Información adicional",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.15,
                colors: [
                  Color(0xFF10275A),
                  Color(0xFF07111F),
                  Color(0xFF030712),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(),
                const SizedBox(height: 16),
                _securityBox(),
                const SizedBox(height: 16),
                _evidenceCard(),
                const SizedBox(height: 16),
                _noteCard(),
                const SizedBox(height: 22),
                _sendButton(),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (uploading)
            Container(
              color: Colors.black.withOpacity(0.72),
              child: const Center(
                child: CircularProgressIndicator(color: neonBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            neonBlue.withOpacity(0.25),
            Colors.black.withOpacity(0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonBlue.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: neonBlue.withOpacity(0.18),
              border: Border.all(color: neonBlue),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: neonBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "PATENTE ${widget.plate.toUpperCase()}\nAgrega antecedentes extra al reporte.",
              style: const TextStyle(
                color: Colors.white,
                height: 1.28,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: red.withOpacity(0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: red, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Esta información llegará primero a SKANO para revisión. No se enviará automáticamente al dueño. No te acerques, no confrontes y no grabes si no es seguro.",
              style: TextStyle(
                color: Colors.white70,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            icon: Icons.collections_rounded,
            title: "Evidencia adicional",
            subtitle: "Máximo 2 fotos y 1 video de hasta 20 segundos.",
          ),
          const SizedBox(height: 14),
          _button(
            label: "AGREGAR FOTO ADICIONAL (${photos.length}/2)",
            icon: Icons.photo_camera_rounded,
            color: neonBlue,
            onTap: uploading ? null : _takePhoto,
          ),
          const SizedBox(height: 10),
          _button(
            label: videoFile == null
                ? "GRABAR VIDEO CORTO MÁX. 20 SEG"
                : "VIDEO CORTO CARGADO ✅",
            icon: Icons.videocam_rounded,
            color: red,
            onTap: uploading ? null : _takeVideo,
          ),
          if (photos.isNotEmpty || videoFile != null) ...[
            const SizedBox(height: 14),
            _previewEvidence(),
          ],
        ],
      ),
    );
  }

  Widget _previewEvidence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: photos
                .asMap()
                .entries
                .map(
                  (entry) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          entry.value,
                          width: 128,
                          height: 94,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: uploading
                              ? null
                              : () => setState(() => photos.removeAt(entry.key)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        if (videoFile != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: red.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: red),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Video adicional seleccionado",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      uploading ? null : () => setState(() => videoFile = null),
                  icon: const Icon(Icons.delete, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _noteCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.edit_note_rounded,
            title: "Observación",
            subtitle: "Agrega contexto útil para revisión SKANO.",
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Ejemplo: el vehículo está estacionado frente a...",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withOpacity(0.50),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: neonBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      height: 62,
      child: ElevatedButton.icon(
        onPressed: _canSend ? _sendExtraInfo : null,
        icon: uploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.cloud_upload_rounded),
        label: Text(
          uploading ? "ENVIANDO..." : "ENVIAR A REVISIÓN SKANO",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _canSend ? green : const Color(0xFF263244),
          foregroundColor: _canSend ? Colors.black : Colors.white38,
          elevation: _canSend ? 12 : 0,
          shadowColor: green.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: neonBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? const Color(0xFF263244) : color,
          foregroundColor: onTap == null ? Colors.white38 : Colors.black,
          elevation: onTap == null ? 0 : 10,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}