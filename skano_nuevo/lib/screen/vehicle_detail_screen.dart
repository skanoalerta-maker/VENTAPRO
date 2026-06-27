import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  String? _vehicleId;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && _vehicle == null && _vehicleId == null) {
      if (args is Vehicle) {
        _vehicle = args;
        _vehicleId = args.id;
        _loading = false;
      } else if (args is String) {
        _vehicleId = args;
        _loadVehicleById(args);
      }
    } else {
      _loading = false;
    }
  }

  Future<void> _loadVehicleById(String id) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(id)
          .get();

      if (!snap.exists) {
        setState(() {
          _error = "No se encontró el vehículo.";
          _loading = false;
        });
        return;
      }

      setState(() {
        _vehicle = Vehicle.fromMap(id, snap.data()!);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = "Error al cargar el vehículo.";
        _loading = false;
      });
    }
  }

  // =====================================================
  // STATUS HELPERS
  // =====================================================
  Color _statusColor(String status) {
    switch (status) {
      case "stolen":
        return Colors.redAccent;
      case "recovered":
        return Colors.greenAccent;
      default:
        return const Color(0xFF0A6CFF);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case "stolen":
        return "Reportado robado";
      case "recovered":
        return "Recuperado";
      default:
        return "Activo";
    }
  }

  // =====================================================
  // UPDATE STATUS
  // =====================================================
  Future<void> _updateStatus(String newStatus) async {
    if (_vehicle == null || _vehicleId == null) return;

    setState(() => _updating = true);

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_vehicleId!)
          .update({
        'status': newStatus,
        'status_updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _vehicle = _vehicle!.copyWith(status: newStatus);
        _updating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Estado actualizado a ${_statusText(newStatus)}",
            ),
          ),
        );
      }
    } catch (_) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al actualizar el estado."),
          ),
        );
      }
    }
  }

  // =====================================================
  // MEMBERSHIP ACTION
  // =====================================================
  void _goToPayment() {
    Navigator.pushNamed(
      context,
      "/my_membership",
      arguments: {
        "vehicleId": _vehicleId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF0A6CFF);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return _errorScaffold();
    }

    if (_vehicle == null) {
      return _errorScaffold(msg: "No hay datos para mostrar.");
    }

    final v = _vehicle!;
    final needsPayment =
        v.membershipRequired == true && v.membershipActive != true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Detalle del Vehículo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO
            _vehiclePhoto(v, neonBlue),

            const SizedBox(height: 20),

            Text(
              v.plate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "${v.brand} ${v.model} • ${v.year}",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 4),

            Text(
              "${v.color.toUpperCase()} • ${v.type}",
              style: const TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(v.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusText(v.status),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =====================================================
            // 🔐 MEMBERSHIP BOX
            // =====================================================
            if (needsPayment) _membershipBox(),

            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            _infoRow("Dueño (UID)", v.ownerUid),
            _infoRow("Marca", v.brand),
            _infoRow("Modelo", v.model),
            _infoRow("Año", v.year.toString()),
            _infoRow("Color", v.color),
            _infoRow("Tipo", v.type),

            const SizedBox(height: 30),

            _updating
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    children: [
                      _statusButton(
                        label: "Marcar como ROBADO",
                        color: Colors.redAccent,
                        icon: Icons.report_gmailerrorred,
                        enabled: v.status != "stolen",
                        onTap: () => _updateStatus("stolen"),
                      ),
                      const SizedBox(height: 12),
                      _statusButton(
                        label: "Marcar como RECUPERADO",
                        color: Colors.greenAccent,
                        icon: Icons.check_circle_outline,
                        enabled: v.status != "recovered",
                        onTap: () => _updateStatus("recovered"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // UI HELPERS
  // =====================================================
  Widget _membershipBox() => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🔒 Protección desactivada",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Este vehículo no tiene protección activa.\n"
              "Debes activar la membresía para recibir reportes.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Activar protección",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _vehiclePhoto(Vehicle v, Color neon) => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: neon.withOpacity(0.5)),
        ),
        child: v.photoUrl == null
            ? const Icon(Icons.directions_car, color: Colors.white30, size: 80)
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(v.photoUrl!, fit: BoxFit.cover),
              ),
      );

  Widget _statusButton({
    required String label,
    required Color color,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(label,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 14)),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _errorScaffold({String? msg}) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text("Detalle Vehículo"),
        ),
        body: Center(
          child: Text(
            msg ?? _error ?? "Error",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
}
