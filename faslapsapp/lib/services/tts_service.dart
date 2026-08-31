import 'package:flutter_tts/flutter_tts.dart';
import '../race_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  TtsService._privateConstructor();
  static final TtsService instance = TtsService._privateConstructor();
  late final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;

  double speechRate = 0.5;
  double volume = 1.0;
  double pitch = 1.0;

  Future<void> initializeTTS() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    speechRate = prefs.getDouble('speechRate') ?? 0.5;
    volume = prefs.getDouble('volume') ?? 1.0;
    pitch = prefs.getDouble('pitch') ?? 1.0;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(speechRate);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);

    _isInitialized = true;

    print(
      "TTS Initialized with rate: $speechRate, volume: $volume, pitch: $pitch",
    );
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initializeTTS();
    }

    await _tts.speak(text);
  }

  Future<void> announceLap(RaceData lap) async {
    String speech =
        "Lap ${lap.lapNumber}. "
        "Time ${lap.lapTimeSeconds.toStringAsFixed(2)} seconds. "
        "Position ${lap.racePosition}.";

    await speak(speech);
  }

  Future<void> setSpeechRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    speechRate = rate;
    await _tts.setSpeechRate(speechRate);
    await prefs.setDouble('speechRate', speechRate);
  }

  Future<void> setVolume(double newVolume) async {
    final prefs = await SharedPreferences.getInstance();
    volume = newVolume;
    await prefs.setDouble('volume', volume);
    await _tts.setVolume(volume);
  }

  Future<void> setPitch(double newPitch) async {
    final prefs = await SharedPreferences.getInstance();
    pitch = newPitch;
    await prefs.setDouble('pitch', pitch);
    await _tts.setPitch(pitch);
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _tts.stop();
    }
  }

  // Future<void> dispose() async {
  //   await _tts.stop();
  // }
}
