import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();

  final pinCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();

  String? bankName; // valor CANÓNICO (de la lista)
  String? accountType; // valor CANÓNICO (de la lista)
  String bankDocumentUrl = "";

  // ✅ CARNET SOLO PARA RETIRO/PAGO
  String payoutIdFrontUrl = "";
  String payoutIdBackUrl = "";

  bool loading = true;
  bool editingEnabled = false;
  bool bankVerified = false;
  bool saving = false;
  bool uploadingDoc = false;
  bool uploadingIdFront = false;
  bool uploadingIdBack = false;

  static const neonBlue = Color(0xFF0A6CFF);

  final banks = const [
    "Banco Estado",
    "Banco de Chile",
    "Banco Santander",
    "BCI",
    "Banco Falabella",
    "Banco Itaú",
    "Scotiabank",
    "Banco Security",
    "Banco Ripley",
  ];

  final accountTypes = const [
    "Cuenta Corriente",
    "Cuenta Vista",
    "Cuenta RUT",
    "Cuenta de Ahorro",
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    pinCtrl.dispose();
    accountNumberCtrl.dispose();
    super.dispose();
  }

  // ================= HELPERS =================

  String? _normalize(String? s) {
    final v = (s ?? "").trim();
    return v.isEmpty ? null : v;
  }

  /// Devuelve el ítem exacto de la lista (case-insensitive).
  /// Si no existe, retorna null (evita crash de Dropdown).
  String? _canonicalFromList(String? raw, List<String> list) {
    final v = (raw ?? "").trim();
    if (v.isEmpty) return null;

    for (final item in list) {
      if (item.toLowerCase() == v.toLowerCase()) return item;
    }
    return null;
  }

  /// Compatibilidad con valores antiguos guardados (ej: "Vista" -> "Cuenta Vista")
  String? _canonicalAccountType(String? raw) {
    final v = (raw ?? "").trim();
    if (v.isEmpty) return null;

    // match directo
    final direct = _canonicalFromList(v, accountTypes);
    if (direct != null) return direct;

    // alias antiguos típicos
    final low = v.toLowerCase();
    if (low == "vista") return "Cuenta Vista";
    if (low == "corriente") return "Cuenta Corriente";
    if (low == "rut") return "Cuenta RUT";
    if (low.contains("ahorro")) return "Cuenta de Ahorro";

    return null;
  }

  // ================= CARGA DE DATOS =================
  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final d = doc.data() ?? {};

      final loadedBankRaw = _normalize(d["bank_name"]?.toString());
      final loadedTypeRaw = _normalize(d["account_type"]?.toString());

      final canonicalBank = _canonicalFromList(loadedBankRaw, banks);
      final canonicalType = _canonicalAccountType(loadedTypeRaw);

      if (!mounted) return;

      setState(() {
        bankName = canonicalBank;
        accountType = canonicalType;
        accountNumberCtrl.text = (d["account_number"] ?? "").toString();
        bankDocumentUrl = (d["bankDocumentUrl"] ?? "").toString();

        // ✅ SOLO CAMPOS DE PAGO
        payoutIdFrontUrl = (d["payout_id_front_url"] ?? "").toString();
        payoutIdBackUrl = (d["payout_id_back_url"] ?? "").toString();

        bankVerified = d["bank_verified"] == true;

        editingEnabled = false;
        loading = false;
      });

      // Si había valores viejos que no calzan, avisa (sin bloquear)
      if ((loadedBankRaw != null && canonicalBank == null) ||
          (loadedTypeRaw != null && canonicalType == null)) {
        _snack(
          "Detecté datos antiguos. Selecciona banco/tipo nuevamente y guarda.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack("No se pudo cargar: $e");
    }
  }

  // ================= VALIDAR PIN =================
  Future<void> _enableEditing() async {
    if (pinCtrl.text.trim().length != 6) {
      _snack("PIN inválido (6 dígitos)");
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final storedHash = doc.data()?["report_pin_hash"];
    if (storedHash == null) {
      _snack("PIN no configurado");
      return;
    }

    final inputHash =
        sha256.convert(utf8.encode(pinCtrl.text.trim())).toString();

    if (inputHash != storedHash) {
      _snack("PIN incorrecto");
      return;
    }

    if (!mounted) return;
    setState(() => editingEnabled = true);
    _snack("Edición habilitada ✅");
  }

  // ================= SUBIR DOCUMENTO BANCARIO (OPCIONAL) =================
  Future<void> _uploadBankDoc() async {
    if (bankVerified || uploadingDoc) return;

    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() => uploadingDoc = true);

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref(
        "bank_docs/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() => bankDocumentUrl = url);

      _snack("Documento bancario subido ✅ (opcional)");
    } catch (e) {
      _snack("No se pudo subir el documento. Reintenta.");
    } finally {
      if (mounted) setState(() => uploadingDoc = false);
    }
  }

  // ================= SUBIR CARNET =================
  Future<void> _uploadId(String field, String path) async {
    if (bankVerified) return;

    if (field == "payout_id_front_url") {
      setState(() => uploadingIdFront = true);
    } else if (field == "payout_id_back_url") {
      setState(() => uploadingIdBack = true);
    }

    try {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) {
        if (mounted) {
          setState(() {
            if (field == "payout_id_front_url") uploadingIdFront = false;
            if (field == "payout_id_back_url") uploadingIdBack = false;
          });
        }
        return;
      }

      final file = File(picked.path);

      final ref = FirebaseStorage.instance.ref(
        "$path/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        field: url,
        "updated_at": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        if (field == "payout_id_front_url") {
          payoutIdFrontUrl = url;
          uploadingIdFront = false;
        }
        if (field == "payout_id_back_url") {
          payoutIdBackUrl = url;
          uploadingIdBack = false;
        }
      });

      _snack("Documento subido ✅");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (field == "payout_id_front_url") uploadingIdFront = false;
        if (field == "payout_id_back_url") uploadingIdBack = false;
      });
      _snack("No se pudo subir el documento. Reintenta.");
    }
  }

  // ================= GUARDAR =================
  Future<void> _save() async {
    if (bankVerified || saving) return;

    if (bankName == null ||
        accountType == null ||
        accountNumberCtrl.text.trim().isEmpty ||
        payoutIdFrontUrl.isEmpty ||
        payoutIdBackUrl.isEmpty) {
      _snack("Completa datos bancarios y sube tu carnet");
      return;
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "bank_name": bankName,
        "account_type": accountType,
        "account_number": accountNumberCtrl.text.trim(),

        // ✅ Se mantiene por compatibilidad, pero es opcional
        "bankDocumentUrl": bankDocumentUrl,

        // ✅ VALIDACIÓN SOLO PARA RETIRO
        "payout_id_front_url": payoutIdFrontUrl,
        "payout_id_back_url": payoutIdBackUrl,

        // Estado para revisión
        "bank_verified": false,
        "payout_verification_status": "pending",
        "identity_for_payout_completed": true,
        "bank_data_completed": true,
        "bank_last_updated_at": FieldValue.serverTimestamp(),

        // Descargo / auditoría
        "bank_disclaimer_accepted": true,
        "bank_disclaimer_accepted_at": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _snack("Datos guardados. Quedan en revisión ✅");
      Navigator.pop(context);
    } catch (e) {
      _snack("No se pudo guardar. Reintenta.");
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: neonBlue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Datos bancarios"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A6CFF), Color(0xFF7C4DFF)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Información bancaria",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Usada exclusivamente para pagos de recompensas.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= ESTADO =================
            if (bankVerified)
              _statusBox(
                "Cuenta bancaria verificada.\nPara modificarla debes contactar soporte.",
                Colors.greenAccent,
                Icons.verified,
              )
            else
              _statusBox(
                editingEnabled
                    ? "Edición habilitada. Completa y guarda para revisión."
                    : "Protección activa: confirma tu PIN para editar.",
                editingEnabled ? Colors.lightBlueAccent : Colors.orangeAccent,
                editingEnabled ? Icons.edit : Icons.lock,
              ),

            const SizedBox(height: 10),

            // ================= FORMULARIO =================
            if (!bankVerified) ...[
              _bankForm(readOnly: !editingEnabled),
              const SizedBox(height: 12),

              _disclaimerCard(),

              const SizedBox(height: 12),
              if (!editingEnabled) _pinCard(),
            ],
          ],
        ),
      ),
    );
  }

  // ================= COMPONENTES =================

  Widget _pinCard() => _card(
        title: "Confirmación de identidad",
        child: Column(
          children: [
            const Text(
              "Para proteger tus datos financieros, confirma tu PIN.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              maxLength: 6,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: _input("PIN de 6 dígitos", Icons.lock),
            ),
            const SizedBox(height: 6),
            _primaryButton("Confirmar identidad", _enableEditing),
          ],
        ),
      );

  Widget _bankForm({bool readOnly = false}) => Column(
        children: [
          _card(
            title: readOnly
                ? "Datos de la cuenta (solo lectura)"
                : "Datos de la cuenta",
            child: Column(
              children: [
                _dropdown(
                  label: "Banco",
                  items: banks,
                  value: bankName,
                  enabled: !readOnly,
                  onChanged: (v) => setState(() => bankName = v),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: "Tipo de cuenta",
                  items: accountTypes,
                  value: accountType,
                  enabled: !readOnly,
                  onChanged: (v) => setState(() => accountType = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountNumberCtrl,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: _input("Número de cuenta", Icons.numbers),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ CARNET OBLIGATORIO PARA RETIRO
          _card(
            title: "Verificación de identidad",
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Cédula frontal",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    payoutIdFrontUrl.isEmpty ? "Pendiente" : "Documento cargado",
                    style: TextStyle(
                      color: payoutIdFrontUrl.isEmpty
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: uploadingIdFront
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.upload, color: Colors.white),
                          onPressed: readOnly
                              ? null
                              : () => _uploadId(
                                    "payout_id_front_url",
                                    "payout_docs/id_front",
                                  ),
                        ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Cédula reverso",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    payoutIdBackUrl.isEmpty ? "Pendiente" : "Documento cargado",
                    style: TextStyle(
                      color: payoutIdBackUrl.isEmpty
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: uploadingIdBack
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.upload, color: Colors.white),
                          onPressed: readOnly
                              ? null
                              : () => _uploadId(
                                    "payout_id_back_url",
                                    "payout_docs/id_back",
                                  ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ CARTOLA OPCIONAL
          _card(
            title: "Documento bancario (opcional)",
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    bankDocumentUrl.isEmpty
                        ? "No enviado (opcional)"
                        : "Documento cargado",
                    style: TextStyle(
                      color: bankDocumentUrl.isEmpty
                          ? Colors.white60
                          : Colors.greenAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (uploadingDoc)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.upload, color: Colors.white),
                  onPressed: readOnly ? null : _uploadBankDoc,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!readOnly)
            _primaryButton(
              saving ? "Guardando..." : "Guardar datos bancarios",
              saving ? () {} : _save,
            ),
        ],
      );

  Widget _disclaimerCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Importante",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Los datos bancarios ingresados son de exclusiva responsabilidad del usuario.\n\n"
              "Si el usuario se equivoca al ingresar banco, tipo o número de cuenta, y por error un depósito "
              "se realiza a una cuenta distinta, SKANO no se hace responsable por dicha transferencia.\n\n"
              "Además, para habilitar pagos, es obligatorio subir la cédula de identidad del titular.",
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      );

  Widget _card({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: neonBlue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _primaryButton(String text, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onTap,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.black54,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      );

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;

    final effectiveItems = <String>[
      if (enabled) "Selecciona...",
      ...items.toSet(),
    ];

    return DropdownButtonFormField<String>(
      value: safeValue,
      dropdownColor: const Color(0xFF1C1C1E),
      items: effectiveItems.map((e) {
        if (enabled && e == "Selecciona...") {
          return const DropdownMenuItem<String>(
            value: null,
            child: Text(
              "Selecciona...",
              style: TextStyle(color: Colors.white60),
            ),
          );
        }
        return DropdownMenuItem<String>(
          value: e,
          child: Text(e, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: _input(label, Icons.arrow_drop_down),
    );
  }

  Widget _statusBox(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}