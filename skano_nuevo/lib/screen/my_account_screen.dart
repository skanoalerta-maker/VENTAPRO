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
    // ✅ Solo bloquea de verdad si ya fue aprobado y no está en re-verificación
    if (verificationStatus == "approved" && !identityChangePending) return true;

    // ✅ Si está pending y ya completó selfie/PIN, queda bloqueado
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
      // ✅ IMPORTANTE: si falla el asset, NO dejamos spinner infinito
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
  // ✅ Soporta 2 formatos:
  // A) { "regiones": [ { "region":"...", "comunas":[...] }, ... ] }
  // B) { "Biobío": ["Concepción", ...], "Los Lagos":[...], ... }
  Future<void> _loadGeo() async {
    final raw = await rootBundle.loadString('assets/data/comunas-regiones.json');
    final dynamic decoded = json.decode(raw);

    final Map<String, List<String>> map = {};

    // ---- Formato A ----
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
    }
    // ---- Formato B ----
    else if (decoded is Map<String, dynamic>) {
      decoded.forEach((k, v) {
        final rn = k.toString().trim();
        if (v is List) {
          map[rn] = List<String>.from(v.map((e) => e.toString()));
        }
      });
    }

    // Si no calzó ningún formato, igual no bloqueamos la UI
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
      // ✅ NO pisa texto si el usuario ya está escribiendo
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

    // ✅ Si la comuna no existe dentro de la región, la limpiamos
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⛔ No puedes modificar tus datos mientras tu identidad está en revisión.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final rutInput = nationalIdCtrl.text.trim();
    if (rutInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes ingresar tu RUT")),
      );
      return;
    }

    final rutNormalized = normalizeRut(rutInput);

    try {
      final rutRef =
          FirebaseFirestore.instance.collection("rut_index").doc(rutNormalized);

      final rutSnap = await rutRef.get();

      if (rutSnap.exists && rutSnap.data()?["uid"] != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Este RUT ya se encuentra vinculado a otra cuenta."),
          ),
        );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Datos guardados correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Firebase: ${e.code} — ${e.message}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ================= ACTIVAR RE-VERIFICACIÓN =================
  Future<void> _resetVerification() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Modificar datos",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Si modificas tus datos, tu cuenta será enviada nuevamente a revisión.\n\n"
          "No podrás reportar hasta que el administrador apruebe.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
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

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "verification_status": "pending",
        "reviewPending": true,
        "documentStatus": "pending",
        "identity_change_pending": false,
        "identityChangePending": false,
        "updated_at": FieldValue.serverTimestamp(),
        "last_activity": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Enviado a revisión."),
        ),
      );

      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Firebase: ${e.code} — ${e.message}"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Error: $e"),
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final comunasList =
        region != null ? (comunasByRegion[region!] ?? <String>[]) : <String>[];

    const neonBlue = Color(0xFF0A6CFF);

    if (loading || !_geoLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Mi Cuenta"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Image.asset("assets/images/skano_logo.png", height: 80),
            const SizedBox(height: 20),

            Text(
              "Completa tu información para mantener tu cuenta actualizada y\n"
              "habilitar las funciones de SKANO.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            if (verificationStatus == "rejected")
              _infoBox(
                "❌ Tu verificación fue rechazada.\n"
                "${adminComment.isNotEmpty ? "Motivo: $adminComment\n\n" : ""}"
                "Corrige la información y vuelve a enviar a revisión.",
                Colors.redAccent,
              )
            else if (identityChangePending)
              _infoBox(
                "⚠️ Re-verificación requerida.\n"
                "Puedes editar tus datos, pero NO podrás reportar hasta aprobación del administrador.",
                Colors.orangeAccent,
              )
            else if (pendingButIncomplete)
              _infoBox(
                "⚠️ Tu cuenta aparece en revisión, pero aún falta registrar tu selfie/PIN.\n"
                "Completa ese paso para finalizar correctamente tu verificación.",
                Colors.orangeAccent,
              )
            else if (verificationStatus == "pending")
              _infoBox(
                "⏳ Tu cuenta está en revisión.\n"
                "No podrás modificar tu información hasta que sea aprobada.",
                Colors.orangeAccent,
              )
            else if (verificationStatus == "approved")
              _infoBox(
                "✅ Tu cuenta está verificada.\n"
                "Para modificar datos debes solicitar re-verificación.",
                Colors.greenAccent,
              ),

            _section("Datos personales", [
              _input("Nombre completo", fullNameCtrl, enabled: !locked),
              _input("RUT", nationalIdCtrl, enabled: !locked),
              _input("Teléfono", phoneCtrl, enabled: !locked),
            ]),

            _section("Dirección", [
              _readonly("País", "Chile"),
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
              _input("Dirección", addressCtrl, enabled: !locked),
            ]),

            if (!locked) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saveProfile,
                  child: const Text("Guardar cambios"),
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (verificationStatus == "approved" && !identityChangePending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resetVerification,
                  child: const Text("Modificar mis datos"),
                ),
              ),

            if (canEditInitialVerification) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: locked
                      ? null
                      : () => Navigator.pushNamed(context, "/selfie_register"),
                  child: Text(
                    faceRegistered
                        ? "Cambiar selfie / PIN"
                        : "Registrar selfie y PIN",
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: locked
                      ? null
                      : () {
                          if (!faceRegistered) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("❌ Debes registrar tu selfie y PIN"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          _submitVerification();
                        },
                  child: const Text("Enviar a verificación"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _infoBox(String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(text, style: TextStyle(color: color)),
      );

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _input(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          enabled: enabled,
          onChanged: (_) => _isEditingLocally = true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      );

  Widget _readonly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          "$label: $value",
          style: const TextStyle(color: Colors.white70),
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
          dropdownColor: const Color(0xFF1C1C1E),
          value: items.contains(value) ? value : null,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      );
}