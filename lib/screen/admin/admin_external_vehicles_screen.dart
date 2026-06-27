import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AdminExternalVehiclesScreen extends StatefulWidget {
  const AdminExternalVehiclesScreen({super.key});

  @override
  State<AdminExternalVehiclesScreen> createState() =>
      _AdminExternalVehiclesScreenState();
}

class _AdminExternalVehiclesScreenState
    extends State<AdminExternalVehiclesScreen> {
  static const Color neonBlue = Color(0xFF0A6CFF);
  static const Color bg = Color(0xFF0D0F14);
  static const Color cardBg = Color(0xFF151922);

  String _upper(TextEditingController c) => c.text.trim().toUpperCase();

  Future<void> _openAddDialog() async {
    final plateCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final ownerEmailCtrl = TextEditingController();
    final stolenRegionCtrl = TextEditingController();
    final stolenCityCtrl = TextEditingController();
    final stolenAddressCtrl = TextEditingController();
    final sourceCtrl = TextEditingController(text: "FACEBOOK");
    final sourceLinkCtrl = TextEditingController();
    final publicNotesCtrl = TextEditingController();
    final internalNotesCtrl = TextEditingController();
    final caseNumberCtrl = TextEditingController();
    final vehicleTypeCtrl = TextEditingController();

    File? selectedImage;
    bool saving = false;
    String? formError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 75,
              );

              if (picked == null) return;

              setDialogState(() {
                selectedImage = File(picked.path);
                formError = null;
              });
            }

            Future<String> uploadImage(String plate) async {
              debugPrint("SKANO ADMIN: iniciando upload imagen $plate");

              final ref = FirebaseStorage.instance
                  .ref()
                  .child("external_stolen_vehicles")
                  .child("$plate.jpg");

              try {
                await ref.putFile(selectedImage!).timeout(
                  const Duration(seconds: 45),
                  onTimeout: () {
                    throw Exception(
                      "Tiempo agotado subiendo imagen a Firebase Storage.",
                    );
                  },
                );

                debugPrint("SKANO ADMIN: upload terminado");

                final url = await ref.getDownloadURL().timeout(
                  const Duration(seconds: 20),
                  onTimeout: () {
                    throw Exception(
                      "Tiempo agotado obteniendo URL de la imagen.",
                    );
                  },
                );

                debugPrint("SKANO ADMIN: URL imagen = $url");

                return url;
              } catch (e) {
                debugPrint("SKANO ADMIN ERROR uploadImage: $e");
                rethrow;
              }
            }

            Future<void> saveVehicle() async {
              debugPrint("SKANO ADMIN: saveVehicle iniciado");

              final plate = _upper(plateCtrl);
              final email = ownerEmailCtrl.text.trim();

              debugPrint("SKANO ADMIN: patente=$plate email=$email");
              debugPrint("SKANO ADMIN: imagen=${selectedImage?.path}");

              setDialogState(() => formError = null);

              if (plate.isEmpty) {
                setDialogState(() => formError = "Debes ingresar la patente.");
                return;
              }

              if (email.isEmpty) {
                setDialogState(
                    () => formError = "Debes ingresar el correo del dueño.");
                return;
              }

              if (selectedImage == null) {
                setDialogState(
                    () => formError = "Debes seleccionar una foto.");
                return;
              }

              setDialogState(() => saving = true);

              try {
                final year = int.tryParse(yearCtrl.text.trim());

                debugPrint("SKANO ADMIN: antes upload");
                final photoUrl = await uploadImage(plate);
                debugPrint("SKANO ADMIN: después upload");

                final db = FirebaseFirestore.instance;
                final batch = db.batch();

                final externalRef =
                    db.collection("external_stolen_vehicles").doc(plate);

                final stolenRef = db.collection("stolen_vehicles").doc(plate);

                final statsRef = db.collection("app_config").doc("stats");
final vehicleData = {
  "active": true,
  "brand": _upper(brandCtrl),
  "case_number": _upper(caseNumberCtrl),
  "city": _upper(stolenCityCtrl),
  "color": _upper(colorCtrl),
  "created_at": FieldValue.serverTimestamp(),
  "created_by": "admin_external",
  "external_vehicle": true,
  "is_external_vehicle": true,
  "uploaded_by_skano": true,
  "uploaded_source": "admin_external_panel",
  "marked_stolen_by": "admin_external",
  "marked_stolen_reason": "Vehículo externo autorizado",
  "model": _upper(modelCtrl),
  "ownerEmail": email,
  "ownerName": _upper(ownerNameCtrl),
  "owner_email": email,
  "owner_name": _upper(ownerNameCtrl),
  "owner_phone": "",

  // URLs compatibles con todas las pantallas SKANO
  "photo_url": photoUrl,
  "photoUrl": photoUrl,
  "vehicle_photo_url": photoUrl,

  "plate": plate,
  "plate_normalized": plate,
  "public_notes": _upper(publicNotesCtrl),
  "internal_notes": _upper(internalNotesCtrl),
  "recovered": false,
  "recovered_at": null,
  "reports_count": 0,
  "reward_amount": 50000,
  "source": _upper(sourceCtrl),
  "source_link": sourceLinkCtrl.text.trim(),
  "status": "stolen",
  "stolen_address": _upper(stolenAddressCtrl),
  "stolen_city": _upper(stolenCityCtrl),
  "stolen_region": _upper(stolenRegionCtrl),
  "vehicle_type": _upper(vehicleTypeCtrl),
  "verified": true,
  "verified_vehicle": true,
  "views_count": 0,
  "year": year,
}; 

                batch.set(externalRef, {
                  ...vehicleData,
                  "external_record": true,
                  "published_to_stolen_vehicles": true,
                  "published_at": FieldValue.serverTimestamp(),
                  "published_stolen_vehicle_id": plate,
                }, SetOptions(merge: true));

                batch.set(stolenRef, {
                  ...vehicleData,
                  "created_from": "external_stolen_vehicles",
                  "external_vehicle_id": plate,
                }, SetOptions(merge: true));

                batch.set(statsRef, {
                  "external_vehicles_uploaded": FieldValue.increment(1),
                  "stolen_vehicles_uploaded": FieldValue.increment(1),
                  "last_external_vehicle_uploaded": plate,
                  "last_external_vehicle_uploaded_at":
                      FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                debugPrint("SKANO ADMIN: antes batch Firestore");

                await batch.commit().timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    throw Exception(
                      "Tiempo agotado guardando en Firestore.",
                    );
                  },
                );

                debugPrint("SKANO ADMIN: después batch Firestore");

                if (!mounted) return;
                Navigator.pop(dialogContext);
                _snack("Vehículo guardado y publicado en vehículos con encargo.");
              } catch (e) {
                debugPrint("SKANO ADMIN ERROR saveVehicle: $e");
                setDialogState(() {
                  saving = false;
                  formError = "Error al guardar: $e";
                });
              }
            }

            return PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10131C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: neonBlue.withOpacity(0.45)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: neonBlue,
                              child: Icon(Icons.add_road, color: Colors.black),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Agregar vehículo con encargo",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel("Datos del vehículo"),
                        _field(plateCtrl, "Patente *"),
                        _field(brandCtrl, "Marca"),
                        _field(modelCtrl, "Modelo"),
                        _field(yearCtrl, "Año", keyboard: TextInputType.number),
                        _field(colorCtrl, "Color"),
                        _field(vehicleTypeCtrl, "Tipo de vehículo"),
                        _sectionLabel("Datos del propietario"),
                        _field(ownerNameCtrl, "Nombre dueño"),
                        _field(
                          ownerEmailCtrl,
                          "Correo dueño *",
                          keyboard: TextInputType.emailAddress,
                          forceUppercase: false,
                        ),
                        _sectionLabel("Foto del vehículo"),
                        _photoPickerBox(selectedImage, pickImage),
                        _sectionLabel("Origen"),
                        _field(sourceCtrl, "Fuente"),
                        _field(
                          sourceLinkCtrl,
                          "Link publicación",
                          keyboard: TextInputType.url,
                          forceUppercase: false,
                        ),
                        _sectionLabel("Lugar del robo"),
                        _field(stolenRegionCtrl, "Región robo"),
                        _field(stolenCityCtrl, "Comuna/Ciudad robo"),
                        _field(stolenAddressCtrl, "Dirección o sector robo"),
                        _sectionLabel("Control interno"),
                        _field(caseNumberCtrl, "Número denuncia / parte"),
                        _field(publicNotesCtrl, "Notas públicas"),
                        _field(internalNotesCtrl, "Notas internas"),
                        const SizedBox(height: 14),
                        if (formError != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Text(
                              formError!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                child: const Text("Cancelar"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: saving ? null : saveVehicle,
                                icon: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(saving
                                    ? "Guardando..."
                                    : "Guardar y publicar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: neonBlue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markRecovered(String id) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.update(db.collection("external_stolen_vehicles").doc(id), {
      "active": false,
      "status": "recovered",
      "recovered": true,
      "recovered_at": FieldValue.serverTimestamp(),
    });

    batch.set(db.collection("stolen_vehicles").doc(id), {
      "active": false,
      "status": "recovered",
      "recovered": true,
      "recovered_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    _snack("Vehículo marcado como recuperado en todo el sistema.");
  }

  Future<void> _deleteVehicle(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: const Text("Eliminar vehículo",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Seguro que quieres eliminar el vehículo $id del sistema?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.delete(db.collection("external_stolen_vehicles").doc(id));
    batch.delete(db.collection("stolen_vehicles").doc(id));

    await batch.commit();

    _snack("Vehículo eliminado del sistema.");
  }

  void _openVehicleDetail(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) {
        final photoUrl = (data["vehicle_photo_url"] ??
                data["photo_url"] ??
                data["photoUrl"] ??
                "")
            .toString();
        final plate = (data["plate"] ?? id).toString();

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10131C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: neonBlue.withOpacity(0.45)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        photoUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _plateBadge(plate),
                      const SizedBox(width: 8),
                      _miniBadge(
                        (data["status"] ?? "stolen").toString().toUpperCase(),
                        neonBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detail("Marca", data["brand"]),
                  _detail("Modelo", data["model"]),
                  _detail("Año", data["year"]),
                  _detail("Color", data["color"]),
                  _detail("Dueño", data["owner_name"] ?? data["ownerName"]),
                  _detail("Correo", data["owner_email"] ?? data["ownerEmail"]),
                  _detail("Comuna robo", data["stolen_city"]),
                  _detail("Región robo", data["stolen_region"]),
                  _detail("Dirección", data["stolen_address"]),
                  _detail("Fuente", data["source"]),
                  _detail("Número denuncia / parte", data["case_number"]),
                  _detail("Notas públicas", data["public_notes"]),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _markRecovered(id);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Recuperado"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteVehicle(id);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Eliminar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _detail(String label, dynamic value) {
    final text = value == null || value.toString().isEmpty
        ? "Sin información"
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        "$label: $text",
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Vehículos externos"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: neonBlue,
        foregroundColor: Colors.white,
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("external_stolen_vehicles")
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: neonBlue),
                  );
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay vehículos externos registrados.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _vehicleCard(
                      id: doc.id,
                      data: data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: neonBlue.withOpacity(0.5)),
      ),
      child: const Text(
        "Todo vehículo agregado aquí queda vinculado al sistema y publicado como vehículo con encargo.",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _vehicleCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final plate = (data["plate"] ?? id).toString();
    final brand = (data["brand"] ?? "").toString();
    final model = (data["model"] ?? "").toString();
    final city = (data["stolen_city"] ?? data["city"] ?? "").toString();
    final email = (data["owner_email"] ?? data["ownerEmail"] ?? "").toString();
    final photoUrl = (data["vehicle_photo_url"] ??
            data["photo_url"] ??
            data["photoUrl"] ??
            "")
        .toString();
    final recovered = data["recovered"] == true;
    final active = data["active"] == true;

    final statusColor = recovered
        ? Colors.greenAccent
        : active
            ? neonBlue
            : Colors.redAccent;

    final statusText = recovered
        ? "RECUPERADO"
        : active
            ? "CON ENCARGO"
            : "INACTIVO";

    return InkWell(
      onTap: () => _openVehicleDetail(id, data),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.55)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emptyImage(),
                    )
                  : _emptyImage(),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _plateBadge(plate),
                      _miniBadge(statusText, statusColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$brand $model",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(city.isEmpty ? "Sin comuna registrada" : city,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(email,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Text(
                    "Publicado en vehículos con encargo",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF202532),
              onSelected: (value) {
                if (value == "recovered") _markRecovered(id);
                if (value == "delete") _deleteVehicle(id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: "recovered",
                  child: Text("Marcar recuperado",
                      style: TextStyle(color: Colors.white)),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: "delete",
                  child:
                      Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _photoPickerBox(File? image, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: image == null ? 130 : 190,
        decoration: BoxDecoration(
          color: const Color(0xFF171B26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: neonBlue.withOpacity(0.65)),
        ),
        child: image == null
            ? const Center(
                child: Text(
                  "Seleccionar foto del vehículo",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(image, fit: BoxFit.cover),
              ),
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: neonBlue,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool forceUppercase = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: forceUppercase
            ? [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  ),
                ),
              ]
            : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF171B26),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static Widget _plateBadge(String plate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        plate.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _emptyImage() {
    return Container(
      width: 76,
      height: 76,
      color: const Color(0xFF252A36),
      child: const Icon(Icons.directions_car, color: Colors.white54),
    );
  }
}