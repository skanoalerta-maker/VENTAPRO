import 'package:flutter/material.dart';
import 'status_badge.dart';

class VehicleCard extends StatelessWidget {
  final String plate;
  final String brand;
  final String model;
  final String status;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.plate,
    required this.brand,
    required this.model,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plate,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "$brand $model",
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            const SizedBox(height: 10),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}
