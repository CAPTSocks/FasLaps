import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../lap_data.dart';
import '../race_info.dart';
import '../saved_race.dart';

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
        .map(
          (race) => SavedRace.fromJson(
            Map<String, dynamic>.from(race),
          ),
        )
        .toList();
  }

  static Future<SavedRace?> findRace(String raceId) async {
    final races = await loadRaces();

    try {
      return races.firstWhere(
        (race) => race.raceId == raceId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveRace(
    RaceInfo raceInfo,
    List<LapData> laps,
  ) async {
    final races = await loadRaces();

    final newRace = SavedRace(
      raceId: raceInfo.raceId,
      raceName: raceInfo.raceName,
      raceDate: raceInfo.raceDate,
      raceHeat: raceInfo.raceHeat,
      laps: List<LapData>.from(laps),
    );

    final existingIndex = races.indexWhere(
      (race) => race.raceId == raceInfo.raceId,
    );

    if (existingIndex >= 0) {
      // Race already exists, so update it.
      races[existingIndex] = newRace;
    } else {
      // This is a new race.
      races.add(newRace);
    }

    final jsonList = races
        .map((race) => race.toJson())
        .toList();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(jsonList),
    );
  }

  static Future<void> deleteRace(String raceId) async {
    final races = await loadRaces();

    races.removeWhere(
      (race) => race.raceId == raceId,
    );

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