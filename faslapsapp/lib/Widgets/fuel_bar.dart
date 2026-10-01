import 'package:flutter/material.dart';

class FuelBar extends StatelessWidget {
  final int fuelAmount;

  const FuelBar({
    super.key,
    required this.fuelAmount,
  });

  @override
  Widget build(BuildContext context) {
    final int activeBars = (fuelAmount / 10).ceil();

    final Color fuelColor = fuelAmount > 50
        ? Colors.green
        : fuelAmount > 20
            ? Colors.orange
            : Colors.red;

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
                fontSize: 16,
              ),
            ),
            Text(
              "$fuelAmount%",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Background behind all 10 fuel bars
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color.fromARGB(255, 74, 74, 74),
              width: 3,
            ),
          ),
          child: Row(
            children: List.generate(10, (index) {
              final bool isActive = index < activeBars;

              return Expanded(
                child: Container(
                  height: 50,
                  margin: EdgeInsets.only(
                    right: index == 9 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? fuelColor
                        : const Color(0xFF303030),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
