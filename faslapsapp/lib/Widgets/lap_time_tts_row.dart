
import 'package:flutter/material.dart';
import 'package:faslapsapp/Widgets/lap_time_bar.dart';

class LapTimeTtsRow extends StatelessWidget {
  final String title;
  final String value;
  final Color firstColor;
  final Color secondColor;
  final bool isTtsEnabled;
  final VoidCallback onTtsToggle;

  const LapTimeTtsRow({
    super.key,
    required this.title,
    required this.value,
    required this.firstColor,
    required this.secondColor,
    required this.isTtsEnabled,
    required this.onTtsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LapTimeBar(
            title: title,
            value: value,
            firstColor: firstColor,
            secondColor: secondColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 70,
          height: 70,
          margin: const EdgeInsets.only(bottom: 8),
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
