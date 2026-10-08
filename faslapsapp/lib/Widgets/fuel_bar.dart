
import 'package:flutter/material.dart';

class FuelBar extends StatelessWidget {
  final int fuelAmount;
  final bool isTtsEnabled;
  final VoidCallback onTtsToggle;

  const FuelBar({
    super.key,
    required this.fuelAmount,
    required this.isTtsEnabled,
    required this.onTtsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final int activeBars = (fuelAmount / 10).ceil();

    final Color fuelColor = fuelAmount > 50
        ? Colors.green
        : fuelAmount > 20
            ? Colors.orange
            : Colors.red;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 65,
          height: 65,
          margin: const EdgeInsets.only(top: 27),
          child: IconButton(
            onPressed: onTtsToggle,
            icon: Icon(
              isTtsEnabled ? Icons.volume_up : Icons.volume_off,
            ),
            color: Colors.white,
            tooltip: isTtsEnabled ? "Disable TTS" : "Enable TTS",
            style: IconButton.styleFrom(
              backgroundColor: isTtsEnabled
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
