
import 'lap_data.dart';

class SavedRace {
  final String raceId;
  final String raceName;
  final DateTime raceDate;
  final String raceHeat;
  final List<LapData> laps;
  final String raceType;
  final int raceDurationSeconds;

  SavedRace({
    required this.raceId,
    required this.raceName,
    required this.raceDate,
    required this.raceHeat,
    required this.laps,
    required this.raceType,
    this.raceDurationSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'raceDate': raceDate.toIso8601String(),
      'raceHeat': raceHeat,
      'laps': laps.map((lap) => lap.toJson()).toList(),
      'raceType': raceType,
      'raceDurationSeconds': raceDurationSeconds,
    };
  }

  factory SavedRace.fromJson(Map<String, dynamic> json) {
    return SavedRace(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceDate: DateTime.parse(json['raceDate'] as String),
      raceHeat: json['raceHeat'] as String,
      laps: (json['laps'] as List)
          .map(
            (lap) => LapData.fromJson(
              Map<String, dynamic>.from(lap),
            ),
          )
          .toList(),
      raceType: json['raceType'] as String,
      raceDurationSeconds:
          (json['raceDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
