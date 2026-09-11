import 'lap_data.dart';

class SavedRace {
  final DateTime date;
  final List<LapData> laps;

  SavedRace({
    required this.date,
    required this.laps,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'laps': laps.map((lap) => lap.toJson()).toList(),
    };
  }

  factory SavedRace.fromJson(Map<String, dynamic> json) {
    return SavedRace(
      date: DateTime.parse(json['date'] as String),
      laps: (json['laps'] as List)
          .map(
            (lap) => LapData.fromJson(
              Map<String, dynamic>.from(lap),
            ),
          )
          .toList(),
    );
  }
}