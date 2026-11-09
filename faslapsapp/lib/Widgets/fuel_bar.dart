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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color.fromARGB(255, 74, 74, 74),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: List.generate(10, (index) {
                    final bool isActive = index < activeBars;

                    return Expanded(
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(right: index == 9 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isActive ? fuelColor : const Color(0xFF303030),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 34,
                      color: Colors.orange,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 60,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 65,
          height: 65,
          child: IconButton(
            onPressed: onTtsToggle,
            icon: Icon(isTtsEnabled ? Icons.volume_up : Icons.volume_off),
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
