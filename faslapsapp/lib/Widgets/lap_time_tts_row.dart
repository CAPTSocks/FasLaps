import 'package:flutter/material.dart';
import 'package:faslapsapp/Widgets/lap_time_bar.dart';

class LapTimeTtsRow extends StatelessWidget {
  final String title;
  final String value;
  final Color firstColor;
  final Color secondColor;
  final bool isTtsEnabled;
  final VoidCallback onTtsToggle;
  final bool compact;

  const LapTimeTtsRow({
    super.key,
    required this.title,
    required this.value,
    required this.firstColor,
    required this.secondColor,
    required this.isTtsEnabled,
    required this.onTtsToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 65.0 : 70.0;

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

        SizedBox(width: compact ? 6 : 8),

        Container(
          width: buttonSize / 1.1,
          height: buttonSize,
          margin: EdgeInsets.only(bottom: compact ? 8 : 8),
          child: IconButton(
            onPressed: onTtsToggle,
            icon: Icon(
              isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              size: compact ? 24 : 24,
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
