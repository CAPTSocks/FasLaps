import 'package:faslapsapp/Models/race_finished.dart';
import 'package:faslapsapp/Pages/practice_race_history_page.dart';
import 'package:faslapsapp/Pages/race_history_page.dart';
import 'package:faslapsapp/Widgets/fuel_bar.dart';
import 'package:flutter/material.dart';
import 'package:faslapsapp/Models/lap_data.dart';
import 'package:faslapsapp/Models/race_info.dart';
import 'package:faslapsapp/Models/race_time.dart';
import 'package:faslapsapp/services/background_race_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:faslapsapp/services/race_history_service.dart';
import 'package:faslapsapp/Widgets/race_data_box.dart';
import 'package:faslapsapp/Models/fuel_data.dart';
import 'package:faslapsapp/Widgets/race_header.dart';
import 'package:faslapsapp/Widgets/race_stats_row.dart';
import 'package:faslapsapp/Widgets/lap_time_tts_row.dart';
import 'package:faslapsapp/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
//import 'package:faslapsapp/Pages/race_history_page.dart';
import 'package:faslapsapp/Pages/race_details_page.dart';
import 'package:faslapsapp/Theme/app_colors.dart';
import 'dart:async';
import '../widgets/lap_time_graph.dart';

class RaceMonitorPage extends StatefulWidget {
  final String serverAddress;

  const RaceMonitorPage({super.key, required this.serverAddress});

  @override
  State<RaceMonitorPage> createState() => _RaceMonitorPageState();
}

enum RaceState { waiting, running, paused, finished }

class _RaceMonitorPageState extends State<RaceMonitorPage> {
  final List<LapData> raceHistory = [];

  RaceInfo? currentRaceInfo;
  DateTime? raceStartTime;
  DateTime? raceEndTime;
  DateTime? _countdownEndTime;
  Timer? _displayTimer;
  Duration raceElapsed = Duration.zero;
  DateTime? _lapRaceElapsedAnchor;
  bool _hasAuthoritativeSync = false;
  int _graphSyncVersion = 0;

  String status = "Connecting...";
  String raceName = "";
  String raceHeat = "";
  String raceStatus = "Waitng for Race to Begin";
  String? raceType = "";
  int fuelAmount = 100;
  int lapTotal = 0;
  int currentLap = 0;
  int lapLeaderCurrentLap = 0;
  bool raceInfoReceived = false;
  bool readLastLap = true;
  bool readBestLap = true;
  bool readAverageLap = true;
  bool readFuel = true;
  bool showFuelBar = true;
  bool canPauseRace = false;
  bool isMinuteRace = true;
  bool raceSaved = false;
  bool keepScreenOn = false;
  RaceState raceState = RaceState.waiting;
  List<double> _recentLapTimes = [];

  IconData get connectionIcon {
    switch (status) {
      case "Connected":
        return Icons.link;
      case "Disconnected":
      case "Connection Error":
        return Icons.link_off;
      default:
        return Icons.search;
    }
  }

  Color get connectionColor {
    switch (status) {
      case "Connected":
        return Colors.green;
      case "Disconnected":
      case "Connection Error":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateTTSSettings() {
    BackgroundRaceService.setTTSSettings(
      lastLap: readLastLap,
      bestLap: readBestLap,
      averageLap: readAverageLap,
      fuel: readFuel,
    );
  }

  Future<void> _loadTTSSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      readFuel = prefs.getBool('readFuel') ?? true;
      readLastLap = prefs.getBool('readLastLap') ?? true;
      readBestLap = prefs.getBool('readBestLap') ?? true;
      readAverageLap = prefs.getBool('readAverageLap') ?? true;
    });
  }

  Future<void> _saveTTSSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('readFuel', readFuel);
    await prefs.setBool('readLastLap', readLastLap);
    await prefs.setBool('readBestLap', readBestLap);
    await prefs.setBool('readAverageLap', readAverageLap);

    _updateTTSSettings();
  }

  Future<void> _loadScreenOnSetting() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      keepScreenOn = prefs.getBool('keepScreenOn') ?? false;
    });

    await _updateScreenAwake();
  }

  Future<void> _updateScreenAwake() async {
    if (keepScreenOn && raceState == RaceState.running) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTaskListener();

    BackgroundRaceService.requestRaceHistory();

    _initializeTTSSettings();
  }

  Future<void> _initializeTTSSettings() async {
    await _loadTTSSettings();
    await _loadScreenOnSetting();

    if (!mounted) return;

    await _startRace();
  }

  Future<void> _startRace() async {
    await BackgroundRaceService.requestPermissions();

    await BackgroundRaceService.start();

    _updateTTSSettings();

    BackgroundRaceService.sendServerAddress(widget.serverAddress);
  }

  @override
  void dispose() {
    // Remove this page's listener.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);

    _displayTimer?.cancel();

    // IMPORTANT:
    // Do NOT stop the race service here.
    //
    // We want the race to continue if the user
    // backgrounds the app or navigates away.
    WakelockPlus.disable();
    super.dispose();
  }

  void _initForegroundTaskListener() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) async {
    print("UI received from background: $data");

    if (data is Map && data['type'] == 'startRaceTimer') {
      print(
        '[TIMER DEBUG] UI received start command at '
        '${DateTime.now().toIso8601String()}',
      );
    }

    print("UI received from background: $data");

    if (data is! Map) return;

    final type = data['type'];

    switch (type) {
      case 'serverNotification':
        await _handleServerNotification(data);
        break;

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

      case 'raceSync':
        _handleRaceSync(data);
        break;

      case 'pauseRace':
        _handlePauseRace();
        break;

      case 'unpauseRace':
        _handleUnpauseRace();
        break;

      case 'fuelData':
        _handleFuelData(data);
        break;

      case 'startRaceTimer':
        _handleStartTime(data);
        break;

      case 'raceFinished':
        _handleRaceFinished(data);
        break;

      default:
        print("Unknown message type received: $type");
    }
  }

  Future<void> _handleServerNotification(Map data) async {
    final notification = data['notification'];

    if (notification is! Map) {
      print("Invalid server notification data.");
      return;
    }

    try {
      await NotificationService.instance.showServerNotification(
        Map<String, dynamic>.from(notification),
      );
    } catch (e, stackTrace) {
      print("Error displaying server notification: $e");
      print(stackTrace);
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

        case 'connecting':
          status = "Connecting...";
          break;

        case 'reconnecting':
          status = "Reconnecting...";
          break;
      }
    });
  }

  void _handlePauseRace() {
    _pauseTimer();
  }

  void _handleUnpauseRace() {
    _resumeTimer();
  }

  void _handleLapData(Map data) {
    final lapDataJson = data['lapData'];

    if (lapDataJson is! Map) {
      print("Invalid lap data received.");
      return;
    }

    try {
      final lapData = LapData.fromJson(Map<String, dynamic>.from(lapDataJson));

      if (!mounted) return;
      if (raceHistory.any((lap) => lap.lapNumber == lapData.lapNumber)) return;

      print("New lap received: ${lapData.lapTimeSeconds}");

      setState(() {
        // Add the new lap time to the graph.
        if (lapData.lapTimeSeconds > 0) {
          _recentLapTimes.add(lapData.lapTimeSeconds);

          // Keep only the most recent 10 laps.
          if (_recentLapTimes.length > 100) {
            _recentLapTimes.removeAt(0);
          }
        }

        // Update existing race history.
        raceHistory.insert(0, lapData);

        lapLeaderCurrentLap = lapData.lapLeaderCurrentLap;
      });
    } catch (e, stackTrace) {
      print("Error processing background lap data: $e");
      print(stackTrace);
    }
  }

  Future<void> _handleRaceHistory(Map data) async {
    final history = data['history'];

    if (history is! List) {
      return;
    }

    try {
      final loadedHistory = history.whereType<Map>().map((lapJson) {
        return LapData.fromJson(Map<String, dynamic>.from(lapJson));
      }).toList();

      if (!mounted || _hasAuthoritativeSync) return;

      loadedHistory.sort((a, b) => b.lapNumber.compareTo(a.lapNumber));
      setState(() {
        raceHistory
          ..clear()
          ..addAll(loadedHistory);
        _rebuildGraphFromHistory();
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

  // raceHistory is newest-first; LapTimeGraph expects oldest-to-newest.
  void _rebuildGraphFromHistory() {
    _recentLapTimes = raceHistory.reversed
        .map((lap) => lap.lapTimeSeconds)
        .where((time) => time > 0)
        .toList();
    if (_recentLapTimes.length > 100) {
      _recentLapTimes = _recentLapTimes.sublist(_recentLapTimes.length - 100);
    }
  }

  // Apply a complete authoritative snapshot in one setState, without TTS.
  void _handleRaceSync(Map data) {
    try {
      if (data['raceInfo'] is! Map || data['laps'] is! List) {
        debugPrint('Ignoring incomplete raceSync.');
        return;
      }

      final infoJson = Map<String, dynamic>.from(data['raceInfo'] as Map);
      final info = RaceInfo.fromJson(infoJson);
      final restored = (data['laps'] as List)
          .whereType<Map>()
          .map((json) => LapData.fromJson(Map<String, dynamic>.from(json)))
          .toList()
        ..sort((a, b) => b.lapNumber.compareTo(a.lapNumber));

      final rawState = (data['raceState'] ?? 'waiting').toString().toLowerCase();
      final syncedState = switch (rawState) {
        'running' => RaceState.running,
        'paused' => RaceState.paused,
        'finished' => RaceState.finished,
        _ => RaceState.waiting,
      };

      final elapsedMs = (data['elapsedRaceTime'] as num?)?.toInt() ?? 0;
      final remainingMs = (data['remainingRaceTimeMs'] as num?)?.toInt() ?? 0;
      final minuteRace = infoJson['isMinuteRace'] == true;
      final now = DateTime.now();
      final synchronizedDisplayTime = minuteRace
          ? Duration(milliseconds: remainingMs < 0 ? 0 : remainingMs)
          : Duration(milliseconds: elapsedMs < 0 ? 0 : elapsedMs);
      final rawEndTime = data['endTime'];
      final parsedEndTime = rawEndTime is String
          ? DateTime.tryParse(rawEndTime)?.toLocal()
          : null;
      final isNewRace = currentRaceInfo?.raceId != info.raceId;

      if (!mounted) return;

      _displayTimer?.cancel();
      _displayTimer = null;

      setState(() {
        currentRaceInfo = info;
        raceName = info.raceName;
        raceHeat = info.raceHeat;
        raceType = info.raceType;
        raceInfoReceived = true;
        isMinuteRace = minuteRace;
        lapTotal = minuteRace ? 0 : info.raceLength;
        showFuelBar = infoJson['showFuelBar'] is bool
            ? infoJson['showFuelBar'] as bool : true;
        canPauseRace = infoJson['canPauseRace'] is bool
            ? infoJson['canPauseRace'] as bool : false;

        if (isNewRace) {
          raceSaved = false;
          fuelAmount = 100;
        }

        raceHistory
          ..clear()
          ..addAll(restored);
        _rebuildGraphFromHistory();
        _graphSyncVersion++;
        currentLap = restored.isNotEmpty ? restored.first.lapNumber : 0;
        lapLeaderCurrentLap = (data['lapLeaderCurrentLap'] as num?)?.toInt() ?? 0;
        raceElapsed = synchronizedDisplayTime;
        raceState = syncedState;
        raceEndTime = syncedState == RaceState.finished ? parsedEndTime : null;

        // The server provides elapsed race time, which excludes pauses.
        // Reconstruct display anchors from the snapshot received right now.
        _countdownEndTime = minuteRace && syncedState == RaceState.running
            ? now.add(synchronizedDisplayTime) : null;
        _lapRaceElapsedAnchor = !minuteRace && syncedState == RaceState.running
            ? now.subtract(synchronizedDisplayTime) : null;

        raceStatus = switch (syncedState) {
          RaceState.waiting => 'Waiting for Race to Begin',
          RaceState.running => 'Race Running',
          RaceState.paused => 'Race Paused',
          RaceState.finished => 'Race Completed',
        };
        _hasAuthoritativeSync = true;
      });

      if (syncedState == RaceState.running) {
        _startDisplayTimer();
      }
      _updateScreenAwake();
      debugPrint('raceSync applied: ${restored.length} laps; state=$rawState');
    } catch (e, stack) {
      debugPrint('Error applying raceSync: $e');
      debugPrint('$stack');
    }
  }

  // Reuses one display-timer implementation for both race types.
  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || raceState != RaceState.running) return;
      final now = DateTime.now();
      setState(() {
        if (isMinuteRace && _countdownEndTime != null) {
          final remaining = _countdownEndTime!.difference(now);
          raceElapsed = remaining.isNegative ? Duration.zero : remaining;
        } else if (!isMinuteRace && _lapRaceElapsedAnchor != null) {
          raceElapsed = now.difference(_lapRaceElapsedAnchor!);
        }
      });
      // Wait for server raceFinished; never infer completion locally.
    });
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

      // Reconnection may resend raceInfo for the *same* race.
      // Do not reset its graph, timer, results, or saved state.
      if (currentRaceInfo?.raceId == raceInfo.raceId) return;

      final syncVersionAtStart = _graphSyncVersion;

      // Save the previous race before switching to the new one.
      if (raceInfoReceived && currentRaceInfo != null && !raceSaved) {
        await RaceHistoryService.saveRace(
          currentRaceInfo!,
          raceHistory.reversed.toList(),
          raceDurationSeconds: raceElapsed.inSeconds,
        );
      }

      currentRaceInfo = raceInfo;

      raceType = currentRaceInfo?.raceType;

      final showFuelBarValue = raceInfoJson['showFuelBar'];
      final canPauseRaceValue = raceInfoJson['canPauseRace'];

      print(
        "CURRENT RACE INFO: "
        "${currentRaceInfo?.raceName} - "
        "${currentRaceInfo?.raceId}",
      );

      final existingRace = await RaceHistoryService.findRace(raceInfo.raceId);

      if (!mounted || syncVersionAtStart != _graphSyncVersion) return;

      // Stop any timer left over from the previous race.
      _displayTimer?.cancel();
      _displayTimer = null;

      setState(() {
        // Reset all race-specific values for the new race.
        raceName = raceInfo.raceName;
        raceHeat = raceInfo.raceHeat;
        raceType = raceInfo.raceType;
        raceInfoReceived = true;
        raceState = RaceState.waiting;
        raceStatus = "Waiting for Race to Begin";
        raceSaved = false;
        _hasAuthoritativeSync = false;
        _lapRaceElapsedAnchor = null;

        raceStartTime = null;
        raceEndTime = null;
        _countdownEndTime = null;

        fuelAmount = 100;
        currentLap = 0;
        lapLeaderCurrentLap = 0;
        lapTotal = 0;

        isMinuteRace = raceInfoJson['isMinuteRace'] == true;
        raceElapsed = isMinuteRace
            ? Duration(minutes: raceInfo.raceLength)
            : Duration.zero;
        if (!isMinuteRace) {
          lapTotal = raceInfo.raceLength;
        }

        showFuelBar = showFuelBarValue is bool ? showFuelBarValue : true;
        canPauseRace = canPauseRaceValue is bool ? canPauseRaceValue : true;

        // Reset both the race stats and the graph: they use separate lists.
        raceHistory
          ..clear()
          ..addAll(existingRace?.laps.reversed ?? []);
        _recentLapTimes = existingRace == null
            ? []
            : existingRace.laps
                  .map((lap) => lap.lapTimeSeconds)
                  .where((time) => time > 0)
                  .toList()
                  .reversed
                  .take(100)
                  .toList()
                  .reversed
                  .toList();
      });

      _updateScreenAwake();

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

  void _handleStartTime(Map data) {
    try {
      final raceTime = RaceTime.fromJson(Map<String, dynamic>.from(data));
      if (!mounted) return;
      _displayTimer?.cancel();
      final now = DateTime.now();
      final start = raceTime.startTime.toLocal();
      final elapsed = now.difference(start);
      final validElapsed = elapsed.isNegative ? Duration.zero : elapsed;
      setState(() {
        raceStartTime = start;
        raceEndTime = null;
        raceState = RaceState.running;
        raceStatus = 'Race Running';
        if (isMinuteRace) {
          final total = Duration(minutes: currentRaceInfo?.raceLength ?? 0);
          final remaining = total - validElapsed;
          raceElapsed = remaining.isNegative ? Duration.zero : remaining;
          _countdownEndTime = now.add(raceElapsed);
          _lapRaceElapsedAnchor = null;
        } else {
          raceElapsed = validElapsed;
          _lapRaceElapsedAnchor = now.subtract(raceElapsed);
          _countdownEndTime = null;
        }
      });
      _updateTTSSettings();
      _startDisplayTimer();
      _updateScreenAwake();
    } catch (e, stack) {
      debugPrint('Error handling race start time: $e');
      debugPrint('$stack');
    }
  }

  void _handleRaceFinished(Map data) {
    try {
      final raceFinishedData = RaceFinished.fromJson(
        Map<String, dynamic>.from(data),
      );

      _displayTimer?.cancel();
      _displayTimer = null;

      if (!mounted) return;

      setState(() {
        raceEndTime = raceFinishedData.endTime;

        // Use the duration calculated by the C# server.
        raceElapsed = Duration(milliseconds: raceFinishedData.elapsedRaceTime);

        raceStatus = "Race Completed";

        raceState = RaceState.finished;
        _countdownEndTime = null;
        _lapRaceElapsedAnchor = null;
        _updateScreenAwake();
      });

      debugPrint('Final race time: ${_formatElapsedTime(raceElapsed)}');
    } catch (e, stackTrace) {
      debugPrint('Error processing race-finished message: $e');
      debugPrint('$stackTrace');
    }
  }

  String _formatElapsedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centiseconds.toString().padLeft(2, '0')}';
  }

  void _pauseTimer() {
    if (raceState != RaceState.running || !mounted) return;
    _displayTimer?.cancel();
    _displayTimer = null;
    final now = DateTime.now();
    setState(() {
      if (isMinuteRace && _countdownEndTime != null) {
        final remaining = _countdownEndTime!.difference(now);
        raceElapsed = remaining.isNegative ? Duration.zero : remaining;
      } else if (!isMinuteRace && _lapRaceElapsedAnchor != null) {
        raceElapsed = now.difference(_lapRaceElapsedAnchor!);
      }
      raceState = RaceState.paused;
      raceStatus = 'Race Paused';
      _countdownEndTime = null;
      _lapRaceElapsedAnchor = null;
    });
    _updateScreenAwake();
  }

  void _resumeTimer() {
    if (raceState != RaceState.paused || !mounted) return;
    final now = DateTime.now();
    setState(() {
      raceState = RaceState.running;
      raceStatus = 'Race Running';
      if (isMinuteRace) {
        _countdownEndTime = now.add(raceElapsed);
      } else {
        _lapRaceElapsedAnchor = now.subtract(raceElapsed);
      }
    });
    _startDisplayTimer();
    _updateScreenAwake();
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

  Future<void> _leaveRace() async {
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
        raceDurationSeconds: raceElapsed.inSeconds,
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

  Future<void> _viewResults() async {
    if (currentRaceInfo == null) return;

    // Save the completed race first.
    await RaceHistoryService.saveRace(
      currentRaceInfo!,
      raceHistory.reversed.toList(),
      raceDurationSeconds: raceElapsed.inSeconds,
    );

    if (!mounted) return;

    // Navigate based on race type.
    if (raceType == "Race") {
      // Retrieve the newly saved race.
      final savedRace = await RaceHistoryService.findRace(
        currentRaceInfo!.raceId,
      );

      if (!mounted) return;

      if (savedRace != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RaceDetailsPage(race: savedRace)),
        );
      } else {
        // Fallback if the saved race couldn't be found.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RaceHistoryPage()),
        );
      }
    } else if (raceType == "Practice") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeRaceHistoryPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Race Monitor"),
          actions: [
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: status,
                child: Icon(connectionIcon, color: connectionColor, size: 28),
              ),
            ),

            // Disconnect button
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Stop Race",
              onPressed: _leaveRace,
            ),
          ],
        ),

        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;

              // Determine how compact the layout should be.
              // Both height and width matter for foldable phones.
              final isCompact = screenHeight < 800 || screenWidth < 400;

              final isVeryCompact = screenHeight < 680 || screenWidth < 350;

              // Reduce unused space on smaller screens.
              final spacing = isVeryCompact
                  ? 4.0
                  : isCompact
                  ? 6.0
                  : 10.0;

              final outerPadding = isVeryCompact
                  ? 8.0
                  : isCompact
                  ? 12.0
                  : 16.0;

              final cardPadding = isVeryCompact
                  ? 6.0
                  : isCompact
                  ? 8.0
                  : 12.0;

              // Timer and graph can shrink on smaller screens.
              final timerHeight = isVeryCompact
                  ? 72.0
                  : isCompact
                  ? 82.0
                  : 90.0;

              final graphHeight = isVeryCompact
                  ? 60.0
                  : isCompact
                  ? 85.0
                  : 110.0;

              // Keep the bottom button large.
              // It is NOT included in the scalable content.
              final buttonHeight = screenHeight < 650
                  ? 88.0
                  : screenHeight < 780
                  ? 105.0
                  : 120.0;

              return Padding(
                padding: EdgeInsets.all(outerPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================
                        // RESPONSIVE RACE INFORMATION
                        // ==================================
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              // Give the widgets enough layout
                              // width, even on narrow screens.
                              // FittedBox will scale this down
                              // to the actual available width.
                              final designWidth =
                                  contentConstraints.maxWidth < 380
                                  ? 380.0
                                  : contentConstraints.maxWidth;

                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: designWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      RaceHeader(
                                        raceName: raceName,
                                        raceHeat: raceHeat,
                                        raceStatus: raceStatus,
                                      ),

                                      SizedBox(height: spacing),

                                      // RACE TIMER
                                      SizedBox(
                                        width: double.infinity,
                                        height: timerHeight,
                                        child: RaceDataBox(
                                          title: "",
                                          value: isMinuteRace
                                              ? _formatElapsedTime(raceElapsed)
                                              : "Laps: $lapLeaderCurrentLap/$lapTotal",
                                        ),
                                      ),

                                      SizedBox(height: spacing),

                                      // RACE STATS
                                      RaceStatsRow(
                                        currentLap: raceHistory.isNotEmpty
                                            ? raceHistory.first.lapNumber
                                            : 0,
                                        position: raceHistory.isNotEmpty
                                            ? raceHistory.first.racePosition
                                            : 0,
                                        timeFromLead: raceHistory.isNotEmpty
                                            ? "${raceHistory.first.behindLeaderSeconds.toStringAsFixed(3)}s"
                                            : "0.000s",
                                      ),

                                      SizedBox(height: spacing),

                                      // LAST LAP
                                      LapTimeTtsRow(
                                        title: "Last Lap",
                                        value: lastLap.toStringAsFixed(3),
                                        firstColor: AppColors.primary,
                                        secondColor: AppColors.primaryGradiant,
                                        compact: isCompact,
                                        isTtsEnabled: readLastLap,
                                        onTtsToggle: () {
                                          setState(() {
                                            readLastLap = !readLastLap;
                                          });
                                          _saveTTSSettings();
                                        },
                                      ),

                                      // BEST LAP
                                      LapTimeTtsRow(
                                        title: "Best Lap",
                                        value: _calculateBestLap()
                                            .toStringAsFixed(3),
                                        firstColor: AppColors.primary,
                                        secondColor: AppColors.primaryGradiant,
                                        compact: isCompact,
                                        isTtsEnabled: readBestLap,
                                        onTtsToggle: () {
                                          setState(() {
                                            readBestLap = !readBestLap;
                                          });
                                          _saveTTSSettings();
                                        },
                                      ),

                                      // LAP TIME GRAPH
                                      Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(cardPadding),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: graphHeight,
                                                child: KeyedSubtree(
                                                  // Reset any internal graph state when
                                                  // a different race is configured.
                                                  key: ValueKey(
                                                    '${currentRaceInfo?.raceId}-$_graphSyncVersion',
                                                  ),
                                                  child: LapTimeGraph(
                                                    lapTimes: _recentLapTimes,
                                                  ),
                                                ),
                                              ),

                                              Center(
                                                child: Text(
                                                  'Lap Times - AVG time: '
                                                  '${_calculateAverageLap().toStringAsFixed(3)}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: isVeryCompact
                                                        ? 12
                                                        : 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // FUEL BAR
                                      if (showFuelBar) ...[
                                        FuelBar(
                                          fuelAmount: fuelAmount,
                                          isTtsEnabled: readFuel,
                                          onTtsToggle: () {
                                            setState(() {
                                              readFuel = !readFuel;
                                            });
                                            _saveTTSSettings();
                                          },
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: spacing),

                        // ==================================
                        // FIXED LARGE ACTION BUTTON
                        // ==================================
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: raceState == RaceState.finished
                                ? _viewResults
                                : (raceState == RaceState.paused ||
                                      !canPauseRace)
                                ? null
                                : () {
                                    BackgroundRaceService.pauseRace();
                                    _pauseTimer();
                                  },
                            icon: Icon(
                              raceState == RaceState.finished
                                  ? Icons.emoji_events
                                  : Icons.pause,
                              size: 28,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                raceState == RaceState.finished
                                    ? "VIEW RESULTS"
                                    : raceState == RaceState.paused
                                    ? "RACE PAUSED"
                                    : "PAUSE RACE",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: raceState == RaceState.finished
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
