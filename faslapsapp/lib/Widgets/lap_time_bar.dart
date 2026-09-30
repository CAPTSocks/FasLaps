import 'package:flutter/material.dart';

class LapTimeBar extends StatelessWidget {
  final String title;
  final String value;
  final Color firstColor;
  final Color secondColor;

  const LapTimeBar({
    super.key,
    required this.title,
    required this.value,
    required this.firstColor,
    required this.secondColor,
  });

@override
 Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 14,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          firstColor,
          secondColor,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xFF168BFF),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
}