import 'package:flutter/material.dart';
import 'package:faslapsapp/race_data.dart';
import 'package:faslapsapp/services/background_race_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:faslapsapp/services/race_history_service.dart';

class ConnectionPage extends StatefulWidget {
  final String serverAddress;

  const ConnectionPage({super.key, required this.serverAddress});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final List<RaceData> raceHistory = [];

  String status = "Connecting...";

  @override
  void initState() {
    super.initState();

    _initForegroundTaskListener();

    BackgroundRaceService.requestRaceHistory();

    _startRace();
  }

  Future<void> _startRace() async {
    await BackgroundRaceService.requestPermissions();

    await BackgroundRaceService.start();

    BackgroundRaceService.sendServerAddress(widget.serverAddress);
  }

  @override
  void dispose() {
    // Remove this page's listener.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);

    // IMPORTANT:
    // Do NOT stop the race service here.
    //
    // We want the race to continue if the user
    // backgrounds the app or navigates away.

    super.dispose();
  }

  void _initForegroundTaskListener() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    print("UI received from background: $data");

    if (data is! Map) return;

    final type = data['type'];

    // Handle connection status messages.
    if (type == 'connectionStatus') {
      final connectionStatus = data['status'];

      if (!mounted) return;

      setState(() {
        switch (connectionStatus) {
          case 'connected':
            status = "Connected";
            break;

          case 'disconnected':
            status = "Disconnected";
            break;

          case 'error':
            status = "Connection Error";
            break;
        }
      });

      return;
    }

    if (type == 'raceHistory') {
      final history = data['history'];

      if (history is! List) {
        return;
      }

      try {
        final loadedHistory = history.whereType<Map>().map((lapJson) {
          return RaceData.fromJson(Map<String, dynamic>.from(lapJson));
        }).toList();

        if (!mounted) return;

        setState(() {
          raceHistory
            ..clear()
            ..addAll(loadedHistory);
        });

        print(
          "Loaded ${raceHistory.length} laps "
          "from background service",
        );
      } catch (e, stackTrace) {
        print("Error loading race history:");
        print(e);
        print(stackTrace);
      }

      return;
    }

    // Handle race data messages.
    if (type == 'raceData') {
      final raceDataJson = data['raceData'];

      if (raceDataJson is! Map<String, dynamic>) {
        return;
      }

      try {
        final raceData = RaceData.fromJson(raceDataJson);

        if (!mounted) return;

        setState(() {
          raceHistory.add(raceData);
        });
      } catch (e) {
        print("Error processing background race data: $e");
      }
    }
  }

  Future<void> _stopRace() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Stop Race?"),
          content: const Text(
            "Would you like to save the race data before stopping?",
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("Save"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text("Don't Save"),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldSave == null) {
      // User canceled the dialog.
      return;
    }

if (shouldSave) {
  await RaceHistoryService.saveRace(raceHistory);

  final savedRaces = await RaceHistoryService.loadRaces();

  print("Number of saved races: ${savedRaces.length}");

  for (final race in savedRaces) {
    print("Race date: ${race.date}");
    print("Number of laps: ${race.laps.length}");

    for (final lap in race.laps) {
      print(
        "Lap ${lap.lapNumber}: "
        "${lap.lapTimeSeconds} seconds, "
        "Position ${lap.racePosition}",
      );
    }
  }
}

    await BackgroundRaceService.stop();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Race Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: "Stop Race",
            onPressed: _stopRace,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              status,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: status == 'Connected' ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      "Lap",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Lap Time",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Best Lap",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Position",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: raceHistory.length,
                itemBuilder: (context, index) {
                  final lap = raceHistory[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${lap.lapNumber}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lap.lapTimeSeconds.toStringAsFixed(3),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lap.bestLapTimeSeconds.toStringAsFixed(3),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${lap.racePosition}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
