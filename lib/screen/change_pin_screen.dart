import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final currentPinCtrl = TextEditingController();
  final newPinCtrl = TextEditingController();
  final confirmPinCtrl = TextEditingController();

  bool showPin = false;
  bool loading = false;
  String errorMessage = "";

  bool hasExistingPin = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _checkIfPinExists();
  }

  Future<void> _checkIfPinExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = snap.data() ?? {};
    setState(() {
      hasExistingPin =
          data["report_pin_hash"] != null &&
          data["report_pin_hash"].toString().isNotEmpty;
    });
  }

  // ================= VALIDATIONS =================
  bool get pinsMatch =>
      newPinCtrl.text.length == 6 &&
      RegExp(r'^\d{6}$').hasMatch(newPinCtrl.text) &&
      newPinCtrl.text == confirmPinCtrl.text;

  // ================= SUBMIT =================
  Future<void> _submit() async {
    setState(() {
      errorMessage = "";
      loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      final snap = await ref.get();
      final data = snap.data() ?? {};

      // 🔁 CAMBIO DE PIN (re-verificación)
      if (hasExistingPin) {
        final storedHash = data["report_pin_hash"];

        final currentHash = sha256
            .convert(utf8.encode(currentPinCtrl.text.trim()))
            .toString();

        if (currentHash != storedHash) {
          setState(() {
            errorMessage = "El PIN actual es incorrecto.";
          });
          return;
        }

        if (!pinsMatch) {
          setState(() {
            errorMessage = "Los PIN nuevos no coinciden.";
          });
          return;
        }

        final newHash =
            sha256.convert(utf8.encode(newPinCtrl.text.trim())).toString();

        await ref.update({
          "report_pin_hash": newHash,
          "pin_updated_at": FieldValue.serverTimestamp(),

          // 🔁 re-verificación
          "identity_change_pending": true,
          "verification_status": "pending",
          "reviewPending": true,
          "blocked": true,
          "blocked_reason": "pin_changed",
        });

        if (!mounted) return;
        Navigator.pop(context);
      }

      // 🆕 CREACIÓN DE PIN (usuario nuevo)
      else {
        if (!pinsMatch) {
          setState(() {
            errorMessage = "Los PIN no coinciden o no son válidos.";
          });
          return;
        }

        final newHash =
            sha256.convert(utf8.encode(newPinCtrl.text.trim())).toString();

        await ref.update({
          "report_pin_hash": newHash,
          "pin_created_at": FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/selfie_register");
      }
    } catch (_) {
      setState(() {
        errorMessage = "Error al guardar el PIN.";
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(hasExistingPin ? "Cambiar PIN" : "Crear PIN"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasExistingPin
                  ? "Ingresa tu PIN actual y define uno nuevo."
                  : "Crea tu PIN de seguridad (6 dígitos numéricos).",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            if (hasExistingPin) ...[
              _pinField("PIN actual", currentPinCtrl),
              const SizedBox(height: 16),
            ],

            _pinField("Nuevo PIN (6 dígitos)", newPinCtrl),
            const SizedBox(height: 16),
            _pinField("Confirmar PIN", confirmPinCtrl),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => showPin = !showPin),
                child: Text(
                  showPin ? "Ocultar PIN" : "Mostrar PIN",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),

            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(errorMessage,
                  style: const TextStyle(color: Colors.redAccent)),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      pinsMatch && !loading ? neonBlue : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: pinsMatch && !loading ? _submit : null,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        hasExistingPin
                            ? "Guardar nuevo PIN"
                            : "Continuar",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _pinField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      maxLength: 6,
      obscureText: !showPin,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    currentPinCtrl.dispose();
    newPinCtrl.dispose();
    confirmPinCtrl.dispose();
    super.dispose();
  }
}
