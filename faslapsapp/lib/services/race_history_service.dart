import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../saved_race.dart';
import '../lap_data.dart';

class RaceHistoryService {
  static const String _storageKey = 'savedRaces';

  static Future<List<SavedRace>> loadRaces() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData = prefs.getString(_storageKey);

    if (savedData == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(savedData);

    return jsonList
        .map((race) => SavedRace.fromJson(
              Map<String, dynamic>.from(race),
            ))
        .toList();
  }

  static Future<void> saveRace(List<LapData> laps) async {
    final races = await loadRaces();

    final newRace = SavedRace(
      date: DateTime.now(),
      laps: List<LapData>.from(laps),
    );

    races.add(newRace);

    final jsonList = races
        .map((race) => race.toJson())
        .toList();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(jsonList),
    );
  }

  static Future<void> deleteRace(int index) async {
    final races = await loadRaces();

    if (index < 0 || index >= races.length) {
      return;
    }

    races.removeAt(index);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        races.map((race) => race.toJson()).toList(),
      ),
    );
  }

  static Future<void> clearRaces() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_storageKey);
  }
}