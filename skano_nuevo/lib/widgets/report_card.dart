import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String plate;
  final String date;
  final String city;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.plate,
    required this.date,
    required this.city,
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
          borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),
            Text(
              "$city — $date",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
