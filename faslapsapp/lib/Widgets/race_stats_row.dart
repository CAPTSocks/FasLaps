
import 'package:flutter/material.dart';
import 'package:faslapsapp/Widgets/race_data_box.dart';

class RaceStatsRow extends StatelessWidget {
  final int currentLap;
  final int position;
  final String timeFromLead;

  const RaceStatsRow({
    super.key,
    required this.currentLap,
    required this.position,
    required this.timeFromLead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RaceDataBox(
            title: "Current Lap",
            value: "$currentLap",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RaceDataBox(
            title: "Position",
            value: "$position",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RaceDataBox(
            title: "Time from lead",
            value: timeFromLead,
          ),
        ),
      ],
    );
  }
}
