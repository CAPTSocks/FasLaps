import 'package:flutter/material.dart';

class RaceDataBox extends StatelessWidget {
  final String title;
  final String value;

  const RaceDataBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF202020),
            Color(0xFF4D4D4D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(255, 224, 87, 7),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}