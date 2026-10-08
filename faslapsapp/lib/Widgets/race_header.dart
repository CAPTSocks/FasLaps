
import 'package:flutter/material.dart';

class RaceHeader extends StatelessWidget {
  final String raceName;
  final String raceHeat;
  final String status;

  const RaceHeader({
    super.key,
    required this.raceName,
    required this.raceHeat,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                raceName,
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text(
              " - ",
              style: textTheme.titleMedium,
            ),
            Flexible(
              child: Text(
                raceHeat,
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        Text(
          "Status: $status",
          style: textTheme.titleSmall?.copyWith(
            color: status == 'Connected'
                ? Colors.green
                : Colors.red,
          ),
        ),
      ],
    );
  }
}
