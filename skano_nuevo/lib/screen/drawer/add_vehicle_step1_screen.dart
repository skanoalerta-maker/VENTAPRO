import 'package:flutter/material.dart';
import 'add_vehicle_step2_screen.dart';

class AddVehicleStep1Screen extends StatefulWidget {
  const AddVehicleStep1Screen({super.key});

  @override
  State<AddVehicleStep1Screen> createState() => _AddVehicleStep1ScreenState();
}

class _AddVehicleStep1ScreenState extends State<AddVehicleStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  String _type = 'Auto';

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF0A6CFF);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Agregar vehículo (1/4)",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Datos del vehículo",
              style: TextStyle(
                color: neon,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ingresa los datos básicos tal como aparecen en el padrón.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _plateController,
                    label: "Patente",
                    hint: "Ej: KJPL55",
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _brandController,
                    label: "Marca",
                    hint: "Ej: Toyota",
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _modelController,
                    label: "Modelo",
                    hint: "Ej: Hilux",
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _yearController,
                    label: "Año",
                    hint: "Ej: 2020",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Obligatorio";
                      final year = int.tryParse(v);
                      if (year == null || year < 1950 || year > 2100) {
                        return "Año inválido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _colorController,
                    label: "Color",
                    hint: "Ej: Blanco",
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Tipo de vehículo",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: neon.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      value: _type,
                      dropdownColor: const Color(0xFF151821),
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white70),
                      items: const [
                        DropdownMenuItem(
                          value: 'Auto',
                          child: Text('Auto'),
                        ),
                        DropdownMenuItem(
                          value: 'Camioneta',
                          child: Text('Camioneta'),
                        ),
                        DropdownMenuItem(
                          value: 'Moto',
                          child: Text('Moto'),
                        ),
                        DropdownMenuItem(
                          value: 'SUV',
                          child: Text('SUV'),
                        ),
                        DropdownMenuItem(
                          value: 'Otro',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddVehicleStep2Screen(
                          plate: _plateController.text.trim(),
                          brand: _brandController.text.trim(),
                          model: _modelController.text.trim(),
                          year: _yearController.text.trim(),
                          color: _colorController.text.trim(),
                          type: _type,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continuar a documentos (2/4)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    const neon = Color(0xFF0A6CFF);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neon),
        ),
      ),
    );
  }
}
