import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  bool loading = true;

  // ✅ Evita que se borre mientras escriben
  bool _controllersInitialized = false;
  bool _isEditingLocally = false;

  // ✅ Geo loaded
  bool _geoLoaded = false;

  // ================= CONTROLLERS =================
  final fullNameCtrl = TextEditingController();
  final nationalIdCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String country = "Chile";
  String? region;
  String? comuna;

  // ================= ESTADO =================
  String verificationStatus = "draft"; // draft | pending | approved | rejected
  bool identityChangePending = false;
  bool faceRegistered = false;
  String adminComment = "";

  // ================= REGIONES / COMUNAS (DESDE JSON) =================
  List<String> regions = [];
  Map<String, List<String>> comunasByRegion = {};

  // ================= THEME =================
  static const Color _bg = Color(0xFF050712);
  static const Color _card = Color(0xFF0D1424);
  static const Color _card2 = Color(0xFF101A2E);
  static const Color _neonBlue = Color(0xFF0A6CFF);
  static const Color _cyan = Color(0xFF18D8FF);
  static const Color _line = Color(0xFF22314D);

  // ================= ESTADO DERIVADO =================
  bool get pendingButIncomplete =>
      verificationStatus == "pending" && !faceRegistered;

  bool get canEditInitialVerification =>
      verificationStatus == "draft" ||
      verificationStatus == "rejected" ||
      identityChangePending ||
      pendingButIncomplete;

  // ================= LOCK RULE =================
  bool get locked {
    if (verificationStatus == "approved" && !identityChangePending) return true;

    if (verificationStatus == "pending" && faceRegistered) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _loadGeo();
    } catch (_) {
      if (mounted) {
        setState(() => _geoLoaded = true);
      } else {
        _geoLoaded = true;
      }
    } finally {
      await _loadUser();
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    nationalIdCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD GEO (JSON) =================
  Future<void> _loadGeo() async {
    final raw = await rootBundle.loadString('assets/data/comunas-regiones.json');
    final dynamic decoded = json.decode(raw);

    final Map<String, List<String>> map = {};

    if (decoded is Map<String, dynamic> && decoded["regiones"] is List) {
      final List<dynamic> regionesList = decoded["regiones"] as List<dynamic>;
      for (final r in regionesList) {
        if (r is Map<String, dynamic>) {
          final rn = (r["region"] ?? "").toString().trim();
          final cs = (r["comunas"] is List)
              ? List<String>.from(
                  (r["comunas"] as List).map((e) => e.toString()),
                )
              : <String>[];
          if (rn.isNotEmpty) map[rn] = cs;
        }
      }
    } else if (decoded is Map<String, dynamic>) {
      decoded.forEach((k, v) {
        final rn = k.toString().trim();
        if (v is List) {
          map[rn] = List<String>.from(v.map((e) => e.toString()));
        }
      });
    }

    if (map.isEmpty) {
      regions = [];
      comunasByRegion = {};
      _geoLoaded = true;
      return;
    }

    regions = map.keys.toList()..sort();
    comunasByRegion = map;
    _geoLoaded = true;
  }

  // ================= LOAD USER =================
  Future<void> _loadUser() async {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    final d = doc.data() ?? {};

    if (!mounted) return;

    final rawStatus =
        (d["verification_status"] ?? "draft").toString().trim().toLowerCase();
    final normalizedStatus = (rawStatus == "active") ? "approved" : rawStatus;

    setState(() {
      if (!_controllersInitialized || !_isEditingLocally) {
        fullNameCtrl.text = (d["full_name"] ?? "").toString();
        nationalIdCtrl.text = (d["nationalId"] ?? "").toString();
        phoneCtrl.text = (d["phone"] ?? "").toString();
        addressCtrl.text = (d["address_text"] ?? "").toString();
        _controllersInitialized = true;
      }

      region = d["region"]?.toString();
      comuna = d["comuna"]?.toString();

      verificationStatus = normalizedStatus;

      identityChangePending =
          d["identity_change_pending"] == true ||
          d["identityChangePending"] == true;

      faceRegistered = d["faceRegistered"] == true;
      adminComment = (d["adminComment"] ?? "").toString();

      loading = false;
    });

    if (_geoLoaded && region != null && comuna != null) {
      final list = comunasByRegion[region!] ?? <String>[];
      if (!list.contains(comuna)) {
        if (mounted) setState(() => comuna = null);
      }
    }
  }

  // ================= NORMALIZE RUT =================
  String normalizeRut(String rut) {
    return rut
        .replaceAll('.', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim();
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (locked) {
      _snack(
        "⛔ No puedes modificar tus datos mientras tu identidad está en revisión.",
        Colors.redAccent,
      );
      return;
    }

    final rutInput = nationalIdCtrl.text.trim();
    if (rutInput.isEmpty) {
      _snack("Debes ingresar tu RUT", Colors.orangeAccent);
      return;
    }

    final rutNormalized = normalizeRut(rutInput);

    try {
      final rutRef =
          FirebaseFirestore.instance.collection("rut_index").doc(rutNormalized);

      final rutSnap = await rutRef.get();

      if (rutSnap.exists && rutSnap.data()?["uid"] != user.uid) {
        _snack("Este RUT ya se encuentra vinculado a otra cuenta.", Colors.redAccent);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final userRef =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      batch.set(
        userRef,
        {
          "full_name": fullNameCtrl.text.trim(),
          "nationalId": rutInput,
          "rut_normalized": rutNormalized,
          "phone": phoneCtrl.text.trim(),
          "address_text": addressCtrl.text.trim(),
          "country": country,
          "region": region,
          "comuna": comuna,
          "updated_at": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!rutSnap.exists) {
        batch.set(rutRef, {
          "uid": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      _isEditingLocally = false;
      _snack("✅ Datos guardados correctamente", Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _snack("❌ Firebase: ${e.code} — ${e.message}", Colors.redAccent);
    } catch (e) {
      if (!mounted) return;
      _snack("❌ Error: $e", Colors.redAccent);
    }
  }

  // ================= ACTIVAR RE-VERIFICACIÓN =================
  Future<void> _resetVerification() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "Modificar datos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Si modificas tus datos, tu cuenta será enviada nuevamente a revisión.\n\n"
          "No podrás reportar hasta que el administrador apruebe.",
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _neonBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continuar"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "identity_change_pending": true,
      "identityChangePending": true,
      "updated_at": FieldValue.serverTimestamp(),
    });

    await _loadUser();
  }

  // ================= ENVIAR A REVISIÓN =================
  Future<void> _submitVerification() async {
    try {
      if (!mounted) return;
      setState(() => loading = true);

      final ref = FirebaseFirestore.instance.collection("users").doc(user.uid);
      final snap = await ref.get();
      final data = snap.data() ?? {};

      final currentStatus =
          (data["verification_status"] ?? "draft").toString().toLowerCase();

      if (currentStatus == "approved" || currentStatus == "active") {
        await ref.update({
          "updated_at": FieldValue.serverTimestamp(),
          "last_activity": FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        setState(() => loading = false);

        _snack("✅ Tu cuenta ya está aprobada.", Colors.green);
        Navigator.pushReplacementNamed(context, "/home");
        return;
      }

      await ref.update({
        "verification_status": "pending",
        "reviewPending": true,
        "documentStatus": "pending",
        "identity_change_pending": false,
        "identityChangePending": false,
        "updated_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => loading = false);

      _snack("✅ Enviado a revisión.", Colors.green);
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("❌ Firebase: ${e.code} — ${e.message}", Colors.redAccent);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("❌ Error: $e", Colors.redAccent);
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final comunasList =
        region != null ? (comunasByRegion[region!] ?? <String>[]) : <String>[];

    if (loading || !_geoLoaded) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _neonBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Mi Cuenta",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071126), Color(0xFF050712), Colors.black],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroCard(),
                const SizedBox(height: 16),
                _statusCard(),
                const SizedBox(height: 16),
                _section(
                  icon: Icons.badge_outlined,
                  title: "Datos personales",
                  subtitle: "Información asociada a tu identidad SKANO.",
                  children: [
                    _input("Nombre completo", fullNameCtrl,
                        icon: Icons.person_outline, enabled: !locked),
                    _input("RUT", nationalIdCtrl,
                        icon: Icons.credit_card_outlined, enabled: !locked),
                    _input("Teléfono", phoneCtrl,
                        icon: Icons.phone_outlined,
                        enabled: !locked,
                        keyboardType: TextInputType.phone),
                  ],
                ),
                _section(
                  icon: Icons.location_on_outlined,
                  title: "Dirección",
                  subtitle: "Usada para validar tu cuenta y tu zona de actividad.",
                  children: [
                    _readonly("País", "Chile", Icons.flag_outlined),
                    _dropdown("Región", regions, region, !locked, (v) {
                      setState(() {
                        region = v;
                        comuna = null;
                      });
                      _isEditingLocally = true;
                    }),
                    _dropdown("Comuna", comunasList, comuna, !locked, (v) {
                      setState(() => comuna = v);
                      _isEditingLocally = true;
                    }),
                    _input("Dirección", addressCtrl,
                        icon: Icons.home_outlined, enabled: !locked),
                  ],
                ),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102A55), Color(0xFF07101F)],
          ),
          border: Border.all(color: _neonBlue.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: _neonBlue.withOpacity(0.20),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 76,
              width: 76,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: _cyan.withOpacity(0.45)),
              ),
              child: Image.asset("assets/images/skano_logo.png"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Perfil SKANO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Completa tu información para habilitar funciones de seguridad, reportes y verificación.",
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statusCard() {
    late final Color color;
    late final IconData icon;
    late final String title;
    late final String message;

    if (verificationStatus == "rejected") {
      color = Colors.redAccent;
      icon = Icons.cancel_outlined;
      title = "Verificación rechazada";
      message = adminComment.isNotEmpty
          ? "Motivo: $adminComment\nCorrige la información y vuelve a enviar a revisión."
          : "Corrige la información y vuelve a enviar a revisión.";
    } else if (identityChangePending) {
      color = Colors.orangeAccent;
      icon = Icons.warning_amber_rounded;
      title = "Re-verificación requerida";
      message = "Puedes editar tus datos, pero no podrás reportar hasta aprobación del administrador.";
    } else if (pendingButIncomplete) {
      color = Colors.orangeAccent;
      icon = Icons.photo_camera_front_outlined;
      title = "Falta selfie y PIN";
      message = "Tu cuenta aparece en revisión, pero aún falta registrar tu selfie/PIN.";
    } else if (verificationStatus == "pending") {
      color = Colors.orangeAccent;
      icon = Icons.hourglass_top_rounded;
      title = "Cuenta en revisión";
      message = "No podrás modificar tu información hasta que sea aprobada.";
    } else if (verificationStatus == "approved") {
      color = Colors.greenAccent;
      icon = Icons.verified_user_outlined;
      title = "Cuenta verificada";
      message = "Tu identidad está aprobada. Para modificar datos debes solicitar re-verificación.";
    } else {
      color = _cyan;
      icon = Icons.edit_note_outlined;
      title = "Completa tu perfil";
      message = "Guarda tus datos, registra selfie/PIN y envía tu cuenta a revisión.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line.withOpacity(0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _neonBlue.withOpacity(0.14),
                    border: Border.all(color: _neonBlue.withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: _cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _actions() => Column(
        children: [
          if (!locked) ...[
            _secondaryButton(
              label: "Guardar cambios",
              icon: Icons.save_outlined,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 12),
          ],
          if (verificationStatus == "approved" && !identityChangePending) ...[
            _secondaryButton(
              label: "Modificar mis datos",
              icon: Icons.edit_outlined,
              onPressed: _resetVerification,
            ),
            const SizedBox(height: 12),
          ],
          if (canEditInitialVerification) ...[
            _secondaryButton(
              label: faceRegistered ? "Cambiar selfie / PIN" : "Registrar selfie y PIN",
              icon: Icons.face_retouching_natural_outlined,
              onPressed: locked ? null : () => Navigator.pushNamed(context, "/selfie_register"),
            ),
            const SizedBox(height: 14),
            _primaryButton(
              label: "Enviar a verificación",
              icon: Icons.verified_outlined,
              onPressed: locked
                  ? null
                  : () {
                      if (!faceRegistered) {
                        _snack("❌ Debes registrar tu selfie y PIN", Colors.redAccent);
                        return;
                      }
                      _submitVerification();
                    },
            ),
          ],
        ],
      );

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _neonBlue,
            disabledBackgroundColor: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      );

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white30,
            side: BorderSide(color: _neonBlue.withOpacity(0.55)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor: Colors.white.withOpacity(0.04),
          ),
        ),
      );

  Widget _input(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: (_) => _isEditingLocally = true,
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration(label, icon, enabled),
        ),
      );

  Widget _readonly(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _card2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Text(
                "$label: ",
                style: const TextStyle(color: Colors.white54),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    bool enabled,
    ValueChanged<String?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: _card2,
          value: items.contains(value) ? value : null,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: _cyan,
          iconDisabledColor: Colors.white24,
          decoration: _fieldDecoration(label, Icons.map_outlined, enabled),
        ),
      );

  InputDecoration _fieldDecoration(String label, IconData icon, bool enabled) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: enabled ? Colors.white60 : Colors.white30),
      prefixIcon: Icon(icon, color: enabled ? _cyan : Colors.white24, size: 21),
      filled: true,
      fillColor: enabled ? _card2 : Colors.white.withOpacity(0.035),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _neonBlue, width: 1.4),
      ),
    );
  }
}
