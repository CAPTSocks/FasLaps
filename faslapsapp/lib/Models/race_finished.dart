class RaceFinished {
  String type;
  DateTime endTime;
  int elapsedRaceTIme;

  RaceFinished({
    required this.type,
    required this.endTime,
    required this.elapsedRaceTIme,
  });

  factory RaceFinished.fromJson(Map<String, dynamic> json) {
    return RaceFinished(
      type: json['type'] as String,
      endTime: DateTime.parse(json['endTime'] as String),
      elapsedRaceTIme: (json['elapsedRaceTIme'] as num).toInt(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'endTime': endTime.toIso8601String(),
      'elapsedRaceTIme' : elapsedRaceTIme,
    };
  }
}