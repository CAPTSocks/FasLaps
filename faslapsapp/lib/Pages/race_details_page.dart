import 'package:flutter/material.dart';

import '../Models/saved_race.dart';
import '../Widgets/history_lap_time_graph.dart';

class RaceDetailsPage extends StatelessWidget {
  final SavedRace race;

  const RaceDetailsPage({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate race statistics.
    final lapTimes = race.laps.map((lap) => lap.lapTimeSeconds).toList();

    final bestLap = lapTimes.isEmpty
        ? null
        : lapTimes.reduce((a, b) => a < b ? a : b);

    final averageLap = lapTimes.isEmpty
        ? null
        : lapTimes.reduce((a, b) => a + b) / lapTimes.length;

    // Get the five fastest laps.
    final hotLaps = List.of(race.laps)
      ..sort((a, b) => a.lapTimeSeconds.compareTo(b.lapTimeSeconds));

    final topFive = hotLaps.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Race Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Race date and total laps.

            Text(
              race.raceName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(race.raceDate),
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 4),

            // Text(
            //   "Total Laps: ${race.laps.length}",
            //   style: theme.textTheme.bodyMedium,
            // ),
            const SizedBox(height: 6),

            // Race statistics.
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    "Best Lap",
                    bestLap != null ? "${bestLap.toStringAsFixed(2)}s" : "--",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    context,
                    "Average Lap",
                    averageLap != null
                        ? "${averageLap.toStringAsFixed(2)}s"
                        : "--",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    context,
                    "Race Time",
                    _formatDuration(race.raceDurationSeconds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    context,
                    "Total Laps",
                    "${race.laps.length}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lap time graph.
            HistoryLapTimeGraph(lapTimes: lapTimes.reversed.toList()),

            const SizedBox(height: 6),

            // Lap history table header.
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 31, 44, 61),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Lap",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Time",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Position",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Behind Leader",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Lap history.
            Expanded(
              child: race.laps.isEmpty
                  ? const Center(child: Text("No lap data available."))
                  : ListView.builder(
                      itemCount: race.laps.length,
                      itemBuilder: (context, index) {
                        final lap = race.laps[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "${lap.lapNumber}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${lap.lapTimeSeconds.toStringAsFixed(2)}s",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${lap.racePosition}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lap.behindLeaderSeconds != null
                                      ? "${lap.behindLeaderSeconds!.toStringAsFixed(2)}s"
                                      : "-",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 6),

            // Fastest Laps section.
            _buildFastestLaps(context, topFive),
          ],
        ),
      ),
    );
  }

  // Individual statistics card.
  Widget _statCard(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 31, 44, 61),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fastest Laps section.

  Widget _buildFastestLaps(BuildContext context, List<dynamic> fastestLaps) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 31, 44, 61),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              "Fastest Laps",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 2),

          if (fastestLaps.isEmpty)
            const Text("No laps available.")
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(fastestLaps.length, (index) {
                final lap = fastestLaps[index];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 53, 75, 104),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              // border: Border.all(
                              //   color: theme.colorScheme.outlineVariant,
                              // ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "#${index + 1}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0
                                        ? Colors.orange
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "${lap.lapTimeSeconds.toStringAsFixed(2)}s",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Lap# ${lap.lapNumber.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Icon(
                                //   Icons.image_outlined,
                                //   size: 26,
                                //   color: theme.colorScheme.onSurfaceVariant,
                                // ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }

    return "${minutes}m ${remainingSeconds}s";
  }
}
