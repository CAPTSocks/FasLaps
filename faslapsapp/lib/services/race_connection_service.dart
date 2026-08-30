import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../race_data.dart';
import 'tts_service.dart';

enum ConnectionStatus { connected, disconnected, connectionError }

class RaceConnectionService {
  RaceConnectionService._privateConstructor();

  static final RaceConnectionService instance =
      RaceConnectionService._privateConstructor();

  final TtsService _ttsService = TtsService.instance;

  WebSocketChannel? _socketChannel;
  StreamSubscription? _subscription;

  final List<RaceData> _raceHistory = [];

  final StreamController<List<RaceData>> _raceHistoryController =
      StreamController<List<RaceData>>.broadcast();

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  Stream<List<RaceData>> get raceHistoryStream => _raceHistoryController.stream;

  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  List<RaceData> get raceHistory => List.unmodifiable(_raceHistory);

  bool get isConnected => _socketChannel != null;

  Future<void> connect(String serverAddress) async {
    // Prevent multiple connections.
    if (_socketChannel != null) {
      return;
    }

    try {
      await _ttsService.initializeTTS();

      String webSocketAddress = serverAddress;

      // If the user/server QR code only gives us an IP address
      // or IP:port, add the WebSocket scheme.
      if (!webSocketAddress.startsWith('ws://') &&
          !webSocketAddress.startsWith('wss://')) {
        webSocketAddress = 'ws://$webSocketAddress:5000/mobile';
      }

      print("Connecting to: $webSocketAddress");

      _socketChannel = WebSocketChannel.connect(Uri.parse(webSocketAddress));

      await _sendUserName();

      _subscription = _socketChannel!.stream.listen(
        _handleMessage,

        onDone: () {
          print("WebSocket disconnected");

          _socketChannel = null;

          _statusController.add(ConnectionStatus.disconnected);
        },

        onError: (error) {
          print("WebSocket error: $error");

          _socketChannel = null;

          _statusController.add(ConnectionStatus.connectionError);
        },
      );

      _statusController.add(ConnectionStatus.connected);
    } catch (e, stack) {
      print("Connection Error:");
      print(e);
      print(stack);

      _socketChannel = null;

      _statusController.add(ConnectionStatus.connectionError);
    }
  }

  Future<void> _sendUserName() async {
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

    _socketChannel?.sink.add(json);
  }

  void _handleMessage(dynamic event) {
    print("Received: $event");

    if (event is! String) {
      print("Received non-string WebSocket message.");
      return;
    }

    try {
      final Map<String, dynamic> jsonData = jsonDecode(event);

      final RaceData raceData = RaceData.fromJson(jsonData);

      _raceHistory.add(raceData);

      // Send a copy so outside code cannot modify
      // our internal list.
      _raceHistoryController.add(List.unmodifiable(_raceHistory));

      _ttsService.announceLap(raceData);
    } catch (e, stack) {
      print("JSON Error:");
      print(e);
      print(stack);
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _socketChannel?.sink.close();
    _socketChannel = null;

    _statusController.add(ConnectionStatus.disconnected);
  }

  void clearRaceHistory() {
    _raceHistory.clear();

    _raceHistoryController.add(List.unmodifiable(_raceHistory));
  }
}
