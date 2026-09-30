import 'package:faslapsapp/Widgets/fuel_bar.dart';
import 'package:faslapsapp/Widgets/lap_time_bar.dart';
import 'package:flutter/material.dart';
import 'package:faslapsapp/lap_data.dart';
import 'package:faslapsapp/race_info.dart';
import 'package:faslapsapp/services/background_race_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:faslapsapp/services/race_history_service.dart';
import 'package:faslapsapp/Widgets/race_data_box.dart';

class RaceMonitorPage extends StatefulWidget {
  final String serverAddress;

  const RaceMonitorPage({super.key, required this.serverAddress});

  @override
  State<RaceMonitorPage> createState() => _RaceMonitorPageState();
}

class _RaceMonitorPageState extends State<RaceMonitorPage> {
  final List<LapData> raceHistory = [];

  RaceInfo? currentRaceInfo;

  String status = "Connecting...";
  String raceName = "Waiting for Race Info";
  String raceHeat = "";
  bool raceInfoReceived = false;

  @override
  void initState() {
    super.initState();
    _initForegroundTaskListener();

    BackgroundRaceService.requestRaceHistory();
    //RaceHistoryService.clearRaces();

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

  void _onReceiveTaskData(Object data) async {
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
          return LapData.fromJson(Map<String, dynamic>.from(lapJson));
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

    // Handle lap data messages.
    if (type == 'lapData') {
      final lapDataJson = data['lapData'];

      if (lapDataJson is! Map<String, dynamic>) {
        return;
      }

      try {
        final lapData = LapData.fromJson(lapDataJson);

        if (!mounted) return;

        setState(() {
          raceHistory.insert(0, lapData);
        });
      } catch (e) {
        print("Error processing background lap data: $e");
      }
    }

    if (type == 'raceInfo') {
      final raceInfoJson = data['raceInfo'];

      if (raceInfoJson is! Map) {
        return;
      }

      try {
        final raceInfo = RaceInfo.fromJson(
          Map<String, dynamic>.from(raceInfoJson),
        );

        if (raceInfoReceived) {
          RaceHistoryService.saveRace(
            currentRaceInfo!,
            raceHistory.reversed.toList(),
          );
        }

        currentRaceInfo = raceInfo;
        print(
          "CURRENT RACE INFO: ${currentRaceInfo?.raceName} - ${currentRaceInfo?.raceId}",
        );
        final existingRace = await RaceHistoryService.findRace(raceInfo.raceId);

        if (!mounted) return;

        setState(() {
          raceName = raceInfo.raceName;
          raceHeat = raceInfo.raceHeat;
          raceInfoReceived = true;

          // If this race has been saved before, load its laps.
          raceHistory
            ..clear()
            ..addAll(existingRace?.laps.reversed ?? []);
        });

        if (existingRace != null) {
          print(
            "Found existing race ${raceInfo.raceId} "
            "with ${existingRace.laps.length} laps.",
          );
        } else {
          print(
            "No saved race found for ${raceInfo.raceId}. "
            "Starting with empty history.",
          );
        }
      } catch (e, stackTrace) {
        print("Error processing background race info:");
        print(e);
        print(stackTrace);
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

    if (shouldSave && currentRaceInfo != null) {
      await RaceHistoryService.saveRace(
        currentRaceInfo!,
        raceHistory.reversed.toList(),
      );

      final savedRaces = await RaceHistoryService.loadRaces();

      print("Number of saved races: ${savedRaces.length}");

      for (final race in savedRaces) {
        print("Race date: ${race.raceDate}");
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
    final lastLap = raceHistory.isNotEmpty
        ? raceHistory[0].lapTimeSeconds
        : 0.0;
    final bestLap = raceHistory.isNotEmpty
        ? raceHistory
              .map((lap) => lap.lapTimeSeconds)
              .reduce((a, b) => a < b ? a : b)
        : 0.0;
    final averageLap = raceHistory.isNotEmpty
        ? raceHistory.map((lap) => lap.lapTimeSeconds).reduce((a, b) => a + b) /
              raceHistory.length
        : 0.0;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        raceName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        " - ",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        raceHeat,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),

                  Center(
                    child: Text(
                      "Status: $status",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: status == 'Connected'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: RaceDataBox(
                      title: "Elapsed Time / Time Left",
                      value: "1:30",
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: RaceDataBox(
                          title: "Current Lap",
                          value:
                              "${raceHistory.isNotEmpty ? raceHistory[0].lapNumber : 0}",
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: RaceDataBox(
                          title: "Postion",
                          value:
                              "${raceHistory.isNotEmpty ? raceHistory[0].racePosition : 0}",
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: RaceDataBox(
                          title: "Time from lead",
                          value: ".223 s",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  FuelBar(fuelAmount: 100),

                  const SizedBox(height: 12),

                  LapTimeBar(
                    title: "Last Lap",
                    value: "${lastLap.toStringAsFixed(3)} s",
                    firstColor: Colors.green,
                    secondColor: const Color.fromARGB(255, 45, 227, 139),
                  ),

                  LapTimeBar(
                    title: "Best Lap",
                    value: "${bestLap.toStringAsFixed(3)} s",
                    firstColor: Colors.red,
                    secondColor: Colors.redAccent,
                  ),

                  LapTimeBar(
                    title: "Average Lap",
                    value: "${averageLap.toStringAsFixed(3)} s",
                    firstColor: Colors.blue,
                    secondColor: Colors.blueAccent,
                  ),

                  // Your lap history ListView can eventually go here.
                  //
                  // Expanded(
                  //   child: ListView.builder(...)
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // This stays at the bottom of the screen.
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Tell the server to stop the race
                },
                icon: const Icon(Icons.stop, size: 28),
                label: const Text(
                  "PAUSE RACE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
