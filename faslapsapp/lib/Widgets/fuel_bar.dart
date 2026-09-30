import 'package:flutter/material.dart';

class FuelBar extends StatelessWidget {
  final int fuelAmount;

  const FuelBar({
    super.key,
    required this.fuelAmount,
  });

@override
  Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "FUEL",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            "${fuelAmount.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 6),

      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fuelAmount / 100,
          minHeight: 40,
          backgroundColor: const Color(0xFF303030),
          valueColor: AlwaysStoppedAnimation<Color>(
            fuelAmount > 50
                ? Colors.blue
                : fuelAmount > 20
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ),
    ],
  );
}
}