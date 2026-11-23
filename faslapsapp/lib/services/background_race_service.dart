import 'dart:async';
import 'dart:convert';
import 'package:faslapsapp/Models/race_finished.dart';
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
  bool _shouldReconnect = false;
  String? _serverAddress;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  int _connectionGeneration = 0;
  String? _currentRaceId;


  bool _readLastLap = true;
  bool _readBestLap = true;
  bool _readAverageLap = true;
  bool _readFuel = true;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("FasLaps background service started");

    WidgetsFlutterBinding.ensureInitialized();
    // Initialize TTS inside the background isolate.
    // Load saved TTS settings.
    final prefs = await SharedPreferences.getInstance();

    _readLastLap = prefs.getBool('readLastLap') ?? true;
    _readBestLap = prefs.getBool('readBestLap') ?? true;
    _readAverageLap = prefs.getBool('readAverageLap') ?? true;
    _readFuel = prefs.getBool('readFuel') ?? true;

    print(
      '[TTS DEBUG] Loaded saved settings: '
      'Last Lap=$_readLastLap, '
      'Best Lap=$_readBestLap, '
      'Average Lap=$_readAverageLap, '
      'Fuel=$_readFuel',
    );

    // Initialize TTS here too if required by your TtsService.
    // await _ttsService.initializeTTS();

    print("Background TTS settings loaded");
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

    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _connectionGeneration++;
    await _socketSubscription?.cancel();
    await _socketChannel?.sink.close();
    _socketSubscription = null;
    _socketChannel = null;

    //await _ttsService.stop();
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

      case 'disconnect':
        _disconnectFromServer();
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

  // The UI supplies the hostname/IP, without a ws:// prefix or port.
  Future<void> _connectToServer(String serverAddress) async {
    final address = serverAddress.trim();
    if (address.isEmpty) return;

    // A manual change of server is different from retrying the same server.
    if (_serverAddress != address) {
      _shouldReconnect = false;
      _reconnectTimer?.cancel();
      _connectionGeneration++;
      final previousSubscription = _socketSubscription;
      final previousSocket = _socketChannel;
      _socketSubscription = null;
      _socketChannel = null;
      await previousSubscription?.cancel();
      await previousSocket?.sink.close();
      _raceHistory.clear();
      _currentRaceId = null;
      _reconnectAttempt = 0;
    }

    _serverAddress = address;
    _shouldReconnect = true;
    _reconnectTimer?.cancel();
    await _openConnection();
  }

  Future<void> _openConnection() async {
    if (!_shouldReconnect || _serverAddress == null ||
        _isConnecting || _socketChannel != null) {
      return;
    }

    _isConnecting = true;
    final generation = ++_connectionGeneration;
    final uri = Uri.parse('ws://${_serverAddress!}:5000/mobile');
    WebSocketChannel? channel;

    FlutterForegroundTask.sendDataToMain({
      'type': 'connectionStatus',
      'status': _reconnectAttempt == 0 ? 'connecting' : 'reconnecting',
    });

    try {
      channel = WebSocketChannel.connect(uri);
      _socketChannel = channel;

      // Install listeners before registering so no early server messages
      // are missed. Both onDone and onError funnel through one cleanup path.
      _socketSubscription = channel.stream.listen(
        (event) {
          if (generation != _connectionGeneration) return;
          if (event is String) _receiveJSONString(event);
        },
        onDone: () => _connectionLost(generation, channel!),
        onError: (Object error) {
          print('Background WebSocket error: $error');
          _connectionLost(generation, channel!);
        },
        cancelOnError: true,
      );

      // This throws on handshake/network failure. Do not claim connected
      // merely because WebSocketChannel.connect() returned an object.
      await channel.ready.timeout(const Duration(seconds: 10));
      if (generation != _connectionGeneration || !_shouldReconnect) return;

      await _sendRegistration(channel);
      if (generation != _connectionGeneration || !_shouldReconnect) return;

      // Keep 'connecting' until sessionIdentity arrives; that confirms
      // the server processed registration, not just the socket handshake.
      print('WebSocket ready; registration sent to $uri');
    } catch (error) {
      print('Background WebSocket connection failed: $error');
      if (channel != null) {
        _connectionLost(generation, channel);
      } else {
        _scheduleReconnect();
      }
    } finally {
      _isConnecting = false;
    }
  }

  void _connectionLost(int generation, WebSocketChannel channel) {
    if (generation != _connectionGeneration ||
        !identical(_socketChannel, channel)) return;

    _socketChannel = null;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    // Avoid awaiting here: the callback can originate inside the stream.
    unawaited(subscription?.cancel() ?? Future<void>.value());
    unawaited(channel.sink.close().catchError((Object _) {}));

    FlutterForegroundTask.sendDataToMain({
      'type': 'connectionStatus',
      'status': 'disconnected',
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _serverAddress == null ||
        _reconnectTimer?.isActive == true) return;

    // Exponential backoff: 2, 4, 8, 16, 30, 30... seconds.
    final seconds = _reconnectAttempt >= 4
        ? 30
        : 2 * (1 << _reconnectAttempt);
    _reconnectAttempt++;
    print('Retrying WebSocket in $seconds seconds');
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      unawaited(_openConnection());
    });
  }

  Future<void> _disconnectFromServer() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionGeneration++;
    _serverAddress = null;

    final subscription = _socketSubscription;
    final channel = _socketChannel;
    _socketSubscription = null;
    _socketChannel = null;
    await subscription?.cancel();
    await channel?.sink.close();

    FlutterForegroundTask.sendDataToMain({
      'type': 'connectionStatus',
      'status': 'disconnected',
    });
  }

  Future<void> _sendRegistration(WebSocketChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final pin = prefs.getString('pin') ?? '';
    // Keep tokens scoped by server address. Don't reuse a token with
    // another race server on the same phone.
    final tokenKey = 'raceResumeToken_${_serverAddress!}';
    final resumeToken = prefs.getString(tokenKey) ?? '';

    channel.sink.add(jsonEncode({
      'type': 'registration',
      'firstName': firstName,
      'lastName': lastName,
      'pin': pin,
      if (resumeToken.isNotEmpty) 'resumeToken': resumeToken,
    }));
    // Never print a resume token or PIN to logs.
    print('Registration sent for $firstName $lastName');
  }

  Future<void> _handleSessionIdentity(Map<String, dynamic> data) async {
    final token = data['resumeToken'];
    if (token is! String || token.isEmpty || _serverAddress == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('raceResumeToken_${_serverAddress!}', token);
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    FlutterForegroundTask.sendDataToMain({
      'type': 'connectionStatus',
      'status': 'connected',
    });
    print('Registered driver ${data['clientId']}; resumed: ${data['resumed']}');
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

      // The test server also sends a legacy plain-text CLIENT_ID message.
      if (jsonString.startsWith('CLIENT_ID:')) return;
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      final String? messageType = jsonData['type'];

      if (messageType == null) {
        print("Received JSON without a type.");
        return;
      }

      switch (messageType) {
        case 'sessionIdentity':
          unawaited(_handleSessionIdentity(jsonData));
          break;

        case 'notification':
          FlutterForegroundTask.sendDataToMain({
            'type': 'serverNotification',
            'notification': jsonData,
          });
          break;

        case 'raceSync':
          _handleRaceSync(jsonData);
          break;

        case 'lapData':
          _handleLapData(jsonData);
          break;

        case 'raceInfo':
          _handleRaceInfo(jsonData);
          break;

        case 'fuelData':
          _handleFuelData(jsonData);
          break;

        case 'pauseRace':
          FlutterForegroundTask.sendDataToMain({'type': 'pauseRace'});
          break;

        case 'unpauseRace':
          FlutterForegroundTask.sendDataToMain({'type': 'unpauseRace'});
          break;

        case 'startRaceTimer':
          _handleStartTime(jsonData);
          break;

        case 'raceFinished':
          _handleFinishRace(jsonData);
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

  // Replaces the background service's history without replaying old lap TTS.
  // The UI must also handle the forwarded raceSync event atomically.
  void _handleRaceSync(Map<String, dynamic> data) {
    try {
      final rawInfo = data['raceInfo'];
      if (rawInfo is! Map) {
        print('Ignoring raceSync without raceInfo');
        return;
      }

      final raceInfoJson = Map<String, dynamic>.from(rawInfo);
      // raceSync already carries raceInfo. Do not forward an additional
      // raceInfo event, since it could asynchronously reset the UI snapshot.
      final incomingRaceId = raceInfoJson['raceID']?.toString();
      if (incomingRaceId != null && incomingRaceId != _currentRaceId) {
        _currentRaceId = incomingRaceId;
        _raceHistory.clear();
      }

      final rawLaps = data['laps'];
      if (rawLaps is! List) {
        print('Ignoring raceSync without laps list');
        return;
      }

      final restored = <LapData>[];
      for (final item in rawLaps) {
        if (item is! Map) continue;
        restored.add(LapData.fromJson(Map<String, dynamic>.from(item)));
      }
      restored.sort((a, b) => a.lapNumber.compareTo(b.lapNumber));

      _raceHistory
        ..clear()
        ..addAll(restored);

      FlutterForegroundTask.sendDataToMain({
        ...data,
        'type': 'raceSync',
        'raceInfo': raceInfoJson,
        'laps': restored.map((lap) => lap.toJson()).toList(),
      });

      print('Restored ${restored.length} historical laps (no TTS).');
    } catch (e, stack) {
      print('Error applying raceSync: $e');
      print(stack);
    }
  }

  void _handleLapData(Map<String, dynamic> jsonData) async {
    try {
      final lapData = LapData.fromJson(jsonData);

      if (_raceHistory.any((lap) => lap.lapNumber == lapData.lapNumber)) {
        print('Ignoring duplicate lap ${lapData.lapNumber}');
        return;
      }
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
      final incomingRaceId = jsonData['raceID']?.toString();
      if (incomingRaceId != null && incomingRaceId != _currentRaceId) {
        _raceHistory.clear();
        _currentRaceId = incomingRaceId;
      }

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
      final receivedAt = DateTime.now();

      print(
        '[TIMER DEBUG] Background received start command at '
        '${receivedAt.toIso8601String()}',
      );

      final raceTime = RaceTime.fromJson(jsonData);

      print(
        '[TIMER DEBUG] Parsed start time: '
        '${raceTime.startTime.toIso8601String()}',
      );

      final message = {...raceTime.toJson(), 'type': 'startRaceTimer'};

      print(
        '[TIMER DEBUG] Sending start command to UI at '
        '${DateTime.now().toIso8601String()}',
      );

      FlutterForegroundTask.sendDataToMain(message);
    } catch (e, stack) {
      print("Error handling start race time: $e");
      print(stack);
    }
  }
}

void _handleFinishRace(Map<String, dynamic> jsonData) {
  try {
    final raceFinished = RaceFinished.fromJson(jsonData);

    final message = {...raceFinished.toJson(), 'type': 'raceFinished'};

    FlutterForegroundTask.sendDataToMain(message);

    print('Race finished message forwarded to UI: $message');
  } catch (e, stack) {
    print('Error handling race finished info:');
    print(e);
    print(stack);
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

  static void disconnect() {
    FlutterForegroundTask.sendDataToTask({'type': 'disconnect'});
  }

  static void requestRaceHistory() {
    FlutterForegroundTask.sendDataToTask({'type': 'getRaceHistory'});
  }

  static Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();

    print("Foreground service stop result: $result");
  }
}
