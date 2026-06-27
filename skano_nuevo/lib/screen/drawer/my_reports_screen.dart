import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 REPORTES REALES (luego Firestore)
    final List<Map<String, dynamic>> reports = [];

    // 👉 para testear puedes usar:
    // final List<Map<String, dynamic>> reports = mockReports;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Mis reportes",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: reports.isEmpty
          ? _EmptyReportsExample()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return _ReportCard(
                  plate: r["plate"],
                  date: r["date"],
                  status: r["status"],
                  location: r["location"],
                );
              },
            ),
    );
  }
}

/// =======================================================
/// 🟡 ESTADO VACÍO + CARD EJEMPLO PROFESIONAL
/// =======================================================
class _EmptyReportsExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        const Text(
          "Aún no tienes reportes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Cuando reportes un vehículo robado, aquí podrás "
          "seguir el estado de tu reporte.",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Text(
          "Así se verá tu reporte cuando sea validado",
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 14),

        // 🧾 CARD EJEMPLO (MISMO ESTILO REAL)
        const _ReportCard(
          plate: "ABCD12",
          date: "20 Dic 2025 • 21:35",
          status: "validado",
          location: "Concepción · Centro",
          isExample: true,
        ),
      ],
    );
  }
}

/// =======================================================
/// 🧾 CARD DE REPORTE (REAL O EJEMPLO)
/// =======================================================
class _ReportCard extends StatelessWidget {
  final String plate;
  final String date;
  final String status;
  final String location;
  final bool isExample;

  const _ReportCard({
    required this.plate,
    required this.date,
    required this.status,
    required this.location,
    this.isExample = false,
  });

  Color getStatusColor() {
    switch (status) {
      case "validado":
        return const Color(0xFF22C55E);
      case "pendiente":
        return const Color(0xFFFACC15);
      case "rechazado":
        return const Color(0xFFFF4B4B);
      default:
        return Colors.white70;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case "validado":
        return "Validado por SKANO";
      case "pendiente":
        return "En revisión";
      case "rechazado":
        return "Rechazado";
      default:
        return "Desconocido";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _glass(),
      child: Row(
        children: [
          // ICONO
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              ),
            ),
            child: const Icon(Icons.directions_car, color: Colors.white),
          ),

          const SizedBox(width: 14),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                if (isExample)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Ejemplo ilustrativo",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ESTADO
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: getStatusColor(), width: 1.2),
            ),
            child: Text(
              getStatusLabel(),
              style: TextStyle(
                fontSize: 11,
                color: getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// 🎨 GLASS EFFECT
/// =======================================================
BoxDecoration _glass() {
  return BoxDecoration(
    color: const Color(0x331A1F2E),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0x22FFFFFF)),
    boxShadow: const [
      BoxShadow(
        color: Colors.black87,
        blurRadius: 18,
        offset: Offset(0, 10),
      )
    ],
  );
}
