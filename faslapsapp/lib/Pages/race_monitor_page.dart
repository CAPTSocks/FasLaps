import 'package:faslapsapp/Widgets/fuel_bar.dart';
import 'package:faslapsapp/Widgets/lap_time_bar.dart';
import 'package:flutter/material.dart';
import 'package:faslapsapp/lap_data.dart';
import 'package:faslapsapp/race_info.dart';
import 'package:faslapsapp/services/background_race_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:faslapsapp/services/race_history_service.dart';
import 'package:faslapsapp/Widgets/race_data_box.dart';
import 'package:faslapsapp/fuel_data.dart';

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
  int fuelAmount = 100;
  bool readLastLap = true;
  bool readBestLap = true;
  bool readAverageLap = true;
  bool readFuel = true;
  bool isRacePaused = false;

  void _updateTTSSettings() {
    BackgroundRaceService.setTTSSettings(
      lastLap: readLastLap,
      bestLap: readBestLap,
      averageLap: readAverageLap,
      fuel: readFuel,
    );
  }

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

  switch (type) {
    case 'connectionStatus':
      _handleConnectionStatus(data);
      break;

    case 'raceHistory':
      await _handleRaceHistory(data);
      break;

    case 'lapData':
      _handleLapData(data);
      break;

    case 'raceInfo':
      await _handleRaceInfo(data);
      break;

    case 'startRace':
      _handleStartRace();
      break;

    case 'fuelData':
      _handleFuelData(data);
      break;

    default:
      print("Unknown message type received: $type");
  }
}

void _handleConnectionStatus(Map data) {
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
}

void _handleStartRace() {
  if (!mounted) return;

  setState(() {
    isRacePaused = false;
  });
}

void _handleLapData(Map data) {
  final lapDataJson = data['lapData'];

  if (lapDataJson is! Map) {
    return;
  }

  try {
    final lapData = LapData.fromJson(
      Map<String, dynamic>.from(lapDataJson),
    );

    if (!mounted) return;

    setState(() {
      raceHistory.insert(0, lapData);
    });
  } catch (e) {
    print("Error processing background lap data: $e");
  }
}

Future<void> _handleRaceHistory(Map data) async {
  final history = data['history'];

  if (history is! List) {
    return;
  }

  try {
    final loadedHistory = history.whereType<Map>().map((lapJson) {
      return LapData.fromJson(
        Map<String, dynamic>.from(lapJson),
      );
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
}

Future<void> _handleRaceInfo(Map data) async {
  final raceInfoJson = data['raceInfo'];

  if (raceInfoJson is! Map) {
    return;
  }

  try {
    final raceInfo = RaceInfo.fromJson(
      Map<String, dynamic>.from(raceInfoJson),
    );

    // Save the previous race before switching to the new one.
    if (raceInfoReceived && currentRaceInfo != null) {
      await RaceHistoryService.saveRace(
        currentRaceInfo!,
        raceHistory.reversed.toList(),
      );
    }

    currentRaceInfo = raceInfo;

    print(
      "CURRENT RACE INFO: "
      "${currentRaceInfo?.raceName} - "
      "${currentRaceInfo?.raceId}",
    );

    final existingRace = await RaceHistoryService.findRace(
      raceInfo.raceId,
    );

    if (!mounted) return;

    setState(() {
      raceName = raceInfo.raceName;
      raceHeat = raceInfo.raceHeat;
      raceInfoReceived = true;

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

void _handleFuelData(Map data) {
  final fuelDataJson = data['fuelData'];

  if (fuelDataJson is! Map) {
    return;
  }

  try {
    final fuelData = FuelData.fromJson(
      Map<String, dynamic>.from(fuelDataJson),
    );

    if (!mounted) return;

    setState(() {
      fuelAmount = fuelData.fuelLevel;
    });
  } catch (e) {
    print("Error processing background fuel data: $e");
  }
}

double get lastLap {
  if (raceHistory.isEmpty) {
    return 0.0;
  }

  return raceHistory.first.lapTimeSeconds;
}

double _calculateBestLap() {
  if (raceHistory.isEmpty) {
    return 0.0;
  }

  return raceHistory
      .map((lap) => lap.lapTimeSeconds)
      .reduce((a, b) => a < b ? a : b);
}

double _calculateAverageLap() {
  if (raceHistory.isEmpty) {
    return 0.0;
  }

  final total = raceHistory.fold<double>(
    0.0,
    (sum, lap) => sum + lap.lapTimeSeconds,
  );

  return total / raceHistory.length;
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

  Widget _buildLapTimeRow({
    required String title,
    required String value,
    required Color firstColor,
    required Color secondColor,
    required bool isTtsEnabled,
    required VoidCallback onTtsToggle,
  }) {
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
          margin: EdgeInsets.only(bottom: 8),
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

  Widget _buildFuelRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: FuelBar(fuelAmount: fuelAmount)),

        const SizedBox(width: 8),

        Container(
          width: 70,
          height: 65,
          margin: const EdgeInsets.only(top: 27),
          child: IconButton(
            onPressed: () {
              setState(() {
                readFuel = !readFuel;
                _updateTTSSettings();
              });
            },
            icon: Icon(readFuel ? Icons.volume_up : Icons.volume_off),
            color: Colors.white,
            tooltip: readFuel ? "Disable TTS" : "Enable TTS",
            style: IconButton.styleFrom(
              backgroundColor: readFuel
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Race Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
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
                    height: 90,
                    child: RaceDataBox(title: "", value: "1:30"),
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
                          title: "Position",
                          value:
                              "${raceHistory.isNotEmpty ? raceHistory[0].racePosition : 0}",
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: RaceDataBox(
                          title: "Time from lead",
                          value: ".223",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _buildFuelRow(),

                  const SizedBox(height: 36),

                  _buildLapTimeRow(
                    title: "Last Lap",
                    value: lastLap.toStringAsFixed(3),
                    firstColor: Colors.deepOrange,
                    secondColor: const Color.fromARGB(255, 255, 120, 78),
                    isTtsEnabled: readLastLap,
                    onTtsToggle: () {
                      setState(() {
                        readLastLap = !readLastLap;
                      });

                      _updateTTSSettings();
                    },
                  ),

                  _buildLapTimeRow(
                    title: "Best Lap",
                    value: _calculateBestLap().toStringAsFixed(3),
                    firstColor: Colors.red,
                    secondColor: Colors.redAccent,
                    isTtsEnabled: readBestLap,
                    onTtsToggle: () {
                      setState(() {
                        readBestLap = !readBestLap;
                      });

                      _updateTTSSettings();
                    },
                  ),

                  _buildLapTimeRow(
                    title: "Average Lap",
                    value: _calculateAverageLap().toStringAsFixed(3),
                    firstColor: Colors.blue,
                    secondColor: Colors.blueAccent,
                    isTtsEnabled: readAverageLap,
                    onTtsToggle: () {
                      setState(() {
                        readAverageLap = !readAverageLap;
                      });

                      _updateTTSSettings();
                    },
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
              height: 125,
              child: ElevatedButton.icon(
                onPressed: isRacePaused
                    ? null
                    : () {
                        BackgroundRaceService.pauseRace();

                        setState(() {
                          isRacePaused = true;
                        });
                      },
                icon: isRacePaused
                    ? const SizedBox.shrink()
                    : const Icon(Icons.pause, size: 28),
                label: Text(
                  isRacePaused ? "RACE PAUSED" : "PAUSE RACE",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.white70,
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
