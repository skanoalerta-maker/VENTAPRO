import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> reports = [];

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mis reportes",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: reports.isEmpty
            ? const _EmptyReportsExample()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final r = reports[index];

                  return _ReportCard(
                    plate: r["plate"] ?? "SIN PPU",
                    date: r["date"] ?? "Sin fecha",
                    status: r["status"] ?? "pendiente",
                    location: r["location"] ?? "Sin ubicación",
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyReportsExample extends StatelessWidget {
  const _EmptyReportsExample();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: const [
        _HeaderCard(),
        SizedBox(height: 18),
        Text(
          "Vista previa",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10),
        _ReportCard(
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _glassStrong(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A6CFF),
                  Color(0xFF38BDF8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0A6CFF).withOpacity(0.45),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Aún no tienes reportes",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Cuando reportes un vehículo con encargo, aquí podrás revisar el estado, la patente, la fecha y la ubicación del reporte.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A6CFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0A6CFF).withOpacity(0.35),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF38BDF8),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "SKANO mantiene el historial de tus reportes para seguimiento y validación.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

  Color get statusColor {
    switch (status.toLowerCase()) {
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

  String get statusLabel {
    switch (status.toLowerCase()) {
      case "validado":
        return "Validado";
      case "pendiente":
        return "En revisión";
      case "rechazado":
        return "Rechazado";
      default:
        return "Desconocido";
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case "validado":
        return Icons.check_circle_rounded;
      case "pendiente":
        return Icons.schedule_rounded;
      case "rechazado":
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _glass(),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A6CFF),
                        Color(0xFF38BDF8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A6CFF).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plate.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withOpacity(0.85),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.045),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isExample) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "Ejemplo ilustrativo",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _glass() {
  return BoxDecoration(
    color: const Color(0xFF111827).withOpacity(0.72),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.45),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

BoxDecoration _glassStrong() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0A6CFF).withOpacity(0.18),
        const Color(0xFF111827).withOpacity(0.92),
        const Color(0xFF05070D).withOpacity(0.95),
      ],
    ),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: Colors.white.withOpacity(0.09)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.55),
        blurRadius: 30,
        offset: const Offset(0, 16),
      ),
    ],
  );
}