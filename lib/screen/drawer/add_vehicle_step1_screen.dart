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

  static const Color neon = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF00D5FF);
  static const Color bg = Color(0xFF020617);
  static const Color card = Color(0xFF0B1220);

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
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Agregar vehículo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [
              Color(0xFF102D5A),
              Color(0xFF07111F),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: cyan.withOpacity(0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: neon.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _plateController,
                          label: "Patente",
                          hint: "Ej: KJPL55",
                          icon: Icons.pin_outlined,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Obligatorio"
                              : null,
                        ),
                        const SizedBox(height: 13),
                        _buildTextField(
                          controller: _brandController,
                          label: "Marca",
                          hint: "Ej: Toyota",
                          icon: Icons.directions_car_filled_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Obligatorio"
                              : null,
                        ),
                        const SizedBox(height: 13),
                        _buildTextField(
                          controller: _modelController,
                          label: "Modelo",
                          hint: "Ej: Hilux",
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Obligatorio"
                              : null,
                        ),
                        const SizedBox(height: 13),
                        _buildTextField(
                          controller: _yearController,
                          label: "Año",
                          hint: "Ej: 2020",
                          icon: Icons.calendar_month_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Obligatorio";
                            }
                            final year = int.tryParse(v);
                            if (year == null || year < 1950 || year > 2100) {
                              return "Año inválido";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        _buildTextField(
                          controller: _colorController,
                          label: "Color",
                          hint: "Ej: Blanco",
                          icon: Icons.palette_outlined,
                        ),
                        const SizedBox(height: 16),
                        _VehicleTypeSelector(
                          value: _type,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _type = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                _SecurityNote(),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00A3FF),
                        Color(0xFF0057FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neon.withOpacity(0.42),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
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
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Continuar a documentos",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16.5,
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      validator: validator,
      cursorColor: cyan,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: cyan.withOpacity(0.86),
          size: 21,
        ),
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.32),
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.66),
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF6B7A),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.09),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: cyan,
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFFF4D5E),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFFF4D5E),
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AddVehicleStep1ScreenStateAccessor.card.withOpacity(0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AddVehicleStep1ScreenStateAccessor.cyan.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepPill(text: "Paso 1 de 4"),
              const Spacer(),
              const Icon(
                Icons.directions_car_rounded,
                color: AddVehicleStep1ScreenStateAccessor.cyan,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "Datos del vehículo",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ingresa la información básica tal como aparece en el padrón. Esto ayuda a validar correctamente el vehículo.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: AddVehicleStep1ScreenStateAccessor.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final String text;

  const _StepPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AddVehicleStep1ScreenStateAccessor.neon.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AddVehicleStep1ScreenStateAccessor.cyan.withOpacity(0.26),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AddVehicleStep1ScreenStateAccessor.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _VehicleTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _VehicleTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tipo de vehículo",
          style: TextStyle(
            color: Colors.white.withOpacity(0.76),
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AddVehicleStep1ScreenStateAccessor.cyan.withOpacity(0.16),
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF101827),
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            ),
            items: const [
              DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              DropdownMenuItem(value: 'Camioneta', child: Text('Camioneta')),
              DropdownMenuItem(value: 'Moto', child: Text('Moto')),
              DropdownMenuItem(value: 'SUV', child: Text('SUV')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF14F195).withOpacity(0.075),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF14F195).withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF14F195),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Estos datos serán revisados junto a los documentos del vehículo antes de activar su protección en SKANO.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 13.5,
                height: 1.38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddVehicleStep1ScreenStateAccessor {
  static const Color neon = Color(0xFF0A6CFF);
  static const Color cyan = Color(0xFF00D5FF);
  static const Color card = Color(0xFF0B1220);
}