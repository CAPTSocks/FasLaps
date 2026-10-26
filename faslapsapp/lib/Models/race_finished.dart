class RaceFinished {
  String type;
  DateTime endTime;
  int elapsedRaceTime;

  RaceFinished({
    required this.type,
    required this.endTime,
    required this.elapsedRaceTime,
  });

  factory RaceFinished.fromJson(Map<String, dynamic> json) {
    return RaceFinished(
      type: json['type'] as String,
      endTime: DateTime.parse(json['endTime'] as String),
      elapsedRaceTime: (json['elapsedRaceTime'] as num).toInt(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'endTime': endTime.toIso8601String(),
      'elapsedRaceTime' : elapsedRaceTime,
    };
  }
}