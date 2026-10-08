import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:faslapsapp/Models/lap_data.dart';
import 'package:faslapsapp/Models/race_info.dart';
import 'package:faslapsapp/services/tts_service.dart';
import 'package:faslapsapp/Models/fuel_data.dart';
import 'package:faslapsapp/Models/race_time.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(RaceTaskHandler());
}

class RaceTaskHandler extends TaskHandler {
  WebSocketChannel? _socketChannel;
  StreamSubscription? _socketSubscription;

  final List<LapData> _raceHistory = [];

  final TtsService _ttsService = TtsService.instance;

  bool _isConnecting = false;

  bool _readLastLap = true;
  bool _readBestLap = true;
  bool _readAverageLap = true;
  bool _readFuel = true;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("FasLaps background service started");

    WidgetsFlutterBinding.ensureInitialized();
    // Initialize TTS inside the background isolate.
    //await _ttsService.initializeTTS();

    print("Background TTS initialized");
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // We don't need to repeatedly do anything here.
    //
    // The WebSocket stream listener will receive race data
    // whenever the server sends it.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print("FasLaps background service stopped");

    await _socketSubscription?.cancel();
    await _socketChannel?.sink.close();

    await _ttsService.stop();
  }

  @override
  void onNotificationButtonPressed(String id) {
    print("Notification button pressed: $id");

    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onReceiveData(Object data) {
    print("Background service received: $data");

    if (data is! Map) return;

    final type = data['type'];

    switch (type) {
      case 'connect':
        final serverAddress = data['serverAddress'];

        if (serverAddress is String) {
          _connectToServer(serverAddress);
        }
        break;

      case 'getRaceHistory':
        _sendRaceHistoryToMain();
        break;

      case 'ttsSettings':
        _readLastLap = data['lastLap'] ?? true;
        _readBestLap = data['bestLap'] ?? true;
        _readAverageLap = data['averageLap'] ?? true;
        _readFuel = data['fuel'] ?? true;

        print(
          "TTS settings updated: "
          "Last Lap=$_readLastLap, "
          "Best Lap=$_readBestLap, "
          "Average Lap=$_readAverageLap, "
          "Fuel=$_readFuel",
        );
        break;

      case 'pauseRace':
        _pauseRace();
        break;
      default:
        print("Unknown background command: $type");
        break;
    }
  }

  void _sendRaceHistoryToMain() {
    final historyJson = _raceHistory.map((lap) {
      return {
        'lapData': lap.type,
        'lapNumber': lap.lapNumber,
        'lapTimeSeconds': lap.lapTimeSeconds,
        'bestLapTimeSeconds': lap.bestLapTimeSeconds,
        'racePosition': lap.racePosition,
      };
    }).toList();

    FlutterForegroundTask.sendDataToMain({
      'type': 'raceHistory',
      'history': historyJson,
    });

    print(
      "Sent ${historyJson.length} laps "
      "to Flutter UI",
    );
  }

  Future<void> _connectToServer(String serverAddress) async {
    if (_isConnecting) {
      print("Already connecting to the race server.");
      return;
    }

    // Don't create a second connection if one already exists.
    if (_socketChannel != null) {
      print("Already connected to a race server.");
      return;
    }

    _isConnecting = true;
    serverAddress = 'ws://$serverAddress:5000/mobile';

    try {
      print(
        "Background service connecting to: "
        "$serverAddress",
      );

      _socketChannel = WebSocketChannel.connect(Uri.parse(serverAddress));

      // Send the user's registration information.
      await _sendUserName();

      _socketSubscription = _socketChannel!.stream.listen(
        (event) {
          print("Background WebSocket received: $event");

          _receiveJSONString(event);
        },
        onDone: () {
          print("Background WebSocket disconnected");

          _socketChannel = null;
          _socketSubscription = null;
          FlutterForegroundTask.sendDataToMain({
            'type': 'connectionStatus',
            'status': 'disconnected',
          });
        },
        onError: (error) {
          FlutterForegroundTask.sendDataToMain({
            'type': 'connectionStatus',
            'status': 'error',
          });
          print("Background WebSocket error: $error");

          _socketChannel = null;
          _socketSubscription = null;
        },
      );

      print("Background WebSocket connected");
      FlutterForegroundTask.sendDataToMain({
        'type': 'connectionStatus',
        'status': 'connected',
      });
    } catch (e, stackTrace) {
      print("Background WebSocket connection error: $e");

      print(stackTrace);

      _socketChannel = null;
      _socketSubscription = null;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _sendUserName() async {
    if (_socketChannel == null) return;

    final prefs = await SharedPreferences.getInstance();

    final storedFirstName = prefs.getString('firstName') ?? '';

    final storedLastName = prefs.getString('lastName') ?? '';

    final storedPin = prefs.getString('pin') ?? '';

    final registration = {
      "type": "registration",
      "firstName": storedFirstName,
      "lastName": storedLastName,
      "pin": storedPin,
    };

    final json = jsonEncode(registration);

    _socketChannel!.sink.add(json);

    print("Background registration sent: $json");
  }

  void _pauseRace() {
    if (_socketChannel == null) {
      print("Cannot pause race: WebSocket is not connected.");
      return;
    }

    final pauseMessage = {"type": "pauseRace"};

    final json = jsonEncode(pauseMessage);

    _socketChannel!.sink.add(json);

    print("Pause race command sent: $json");
  }

  void _receiveJSONString(String jsonString) {
    try {
      print("Raw JSON:");
      print(jsonString);

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      final String? messageType = jsonData['type'];

      if (messageType == null) {
        print("Received JSON without a type.");
        return;
      }

      switch (messageType) {
        case 'lapData':
          _handleLapData(jsonData);
          break;

        case 'raceInfo':
          _handleRaceInfo(jsonData);
          break;

        case 'fuelData':
          _handleFuelData(jsonData);
          break;

        case 'startRace':
          FlutterForegroundTask.sendDataToMain({'type': 'startRace'});
          break;

        case 'raceTimeStart':
          _handleStartTime(jsonData);
          break;

        default:
          print("Unknown message type received: $messageType");
          break;
      }
    } catch (e, stack) {
      print("JSON Error:");
      print(e);
      print(stack);
    }
  }

  void _handleLapData(Map<String, dynamic> jsonData) async {
    try {
      final lapData = LapData.fromJson(jsonData);

      _raceHistory.add(lapData);

      FlutterForegroundTask.sendDataToMain({
        'type': 'lapData',
        'lapData': lapData.toJson(),
      });

      // Calculate the average lap.
      final averageLap =
          _raceHistory
              .map((lap) => lap.lapTimeSeconds)
              .reduce((a, b) => a + b) /
          _raceHistory.length;

      final bestLap = _raceHistory
          .map((lap) => lap.lapTimeSeconds)
          .reduce((a, b) => a < b ? a : b);

      await _ttsService.announceLapStats(
        lap: lapData,
        bestLap: bestLap,
        averageLap: averageLap,
        readLastLap: _readLastLap,
        readBestLap: _readBestLap,
        readAverageLap: _readAverageLap,
      );
    } catch (e, stack) {
      print("Error handling lap data:");
      print(e);
      print(stack);
    }
  }

  void _handleRaceInfo(Map<String, dynamic> jsonData) {
    try {
      final raceInfo = RaceInfo.fromJson(jsonData);

      FlutterForegroundTask.sendDataToMain({
        'type': 'raceInfo',
        'raceInfo': raceInfo.toJson(),
      });
    } catch (e, stack) {
      print("Error handling race info:");
      print(e);
      print(stack);
    }
  }

  void _handleFuelData(Map<String, dynamic> jsonData) async {
    try {
      final fuelData = FuelData.fromJson(jsonData);

      FlutterForegroundTask.sendDataToMain({
        'type': 'fuelData',
        'fuelData': fuelData.toJson(),
      });

      if (_readFuel) {
        await _ttsService.announceFuel(fuelData.fuelLevel);
      }
    } catch (e, stack) {
      print("Error handling fuel data:");
      print(e);
      print(stack);
    }
  }

  void _handleStartTime(Map<String, dynamic> jsonData) {
    try {
      final raceTime = RaceTime.fromJson(jsonData);

      FlutterForegroundTask.sendDataToMain(raceTime.toJson());
    } catch (e, stack) {
      print("Error handling start race:");
      print(e);
      print(stack);
    }
  }
}

class BackgroundRaceService {
  static Future<void> requestPermissions() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      print("FasLaps background service is already running.");
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'FasLaps Race',
      notificationText: 'Race monitoring is active.',
      callback: startCallback,
    );

    print("Foreground service result: $result");
  }

  static void pauseRace() {
    FlutterForegroundTask.sendDataToTask({'type': 'pauseRace'});
  }

  static void setTTSSettings({
    required bool lastLap,
    required bool bestLap,
    required bool averageLap,
    required bool fuel,
  }) {
    FlutterForegroundTask.sendDataToTask({
      'type': 'ttsSettings',
      'lastLap': lastLap,
      'bestLap': bestLap,
      'averageLap': averageLap,
      'fuel': fuel,
    });
  }

  static void sendServerAddress(String serverAddress) {
    FlutterForegroundTask.sendDataToTask({
      'type': 'connect',
      'serverAddress': serverAddress,
    });
  }

  static void requestRaceHistory() {
    FlutterForegroundTask.sendDataToTask({'type': 'getRaceHistory'});
  }

  static Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();

    print("Foreground service stop result: $result");
  }
}
