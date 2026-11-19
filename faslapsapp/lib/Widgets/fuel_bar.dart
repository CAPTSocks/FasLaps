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
    final int activeBars = (fuelAmount.clamp(0, 100) / 10).ceil();

    final Color fuelColor = fuelAmount > 50
        ? Colors.green
        : fuelAmount > 20
        ? Colors.orange
        : Colors.red;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4A4A4A), width: 3),
            ),
            child: Row(
              children: [
                // Fuel pump icon on the left.
                Container(
                  width: 42,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF263343),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    size: 28,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 6),

                // Fuel level segments.
                Expanded(
                  child: Row(
                    children: List.generate(10, (index) {
                      final bool isActive = index < activeBars;

                      return Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(right: index == 9 ? 0 : 3),
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
        ),

        const SizedBox(width: 8),

        // Fuel TTS toggle.
        SizedBox(
          width: 65,
          height: 72,
          child: IconButton(
            onPressed: onTtsToggle,
            icon: Icon(isTtsEnabled ? Icons.volume_up : Icons.volume_off),
            color: Colors.white,
            tooltip: isTtsEnabled ? 'Disable TTS' : 'Enable TTS',
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
