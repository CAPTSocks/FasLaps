class LapData {
  String type;
  int lapNumber;
  double lapTimeSeconds;
  double bestLapTimeSeconds;
  int racePosition;

  LapData({
    required this.type,
    required this.lapNumber,
    required this.lapTimeSeconds,
    required this.bestLapTimeSeconds,
    required this.racePosition,
  });

  factory LapData.fromJson(Map<String, dynamic> json) {
    return LapData(
      type: json['type'] as String,
      lapNumber: json['lapNumber'] as int,
      lapTimeSeconds: (json['lapTimeSeconds'] as num).toDouble(),
      bestLapTimeSeconds: (json['bestLapTimeSeconds'] as num).toDouble(),
      racePosition: json['racePosition'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'lapNumber': lapNumber,
      'lapTimeSeconds': lapTimeSeconds,
      'bestLapTimeSeconds': bestLapTimeSeconds,
      'racePosition': racePosition,
    };
  }
}