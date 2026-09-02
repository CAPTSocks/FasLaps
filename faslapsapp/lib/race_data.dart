class RaceData {
  String raceData;
  int lapNumber;
  double lapTimeSeconds;
  double bestLapTimeSeconds;
  int racePosition;

  RaceData({
    required this.raceData,
    required this.lapNumber,
    required this.lapTimeSeconds,
    required this.bestLapTimeSeconds,
    required this.racePosition,
  });

  factory RaceData.fromJson(Map<String, dynamic> json) {
    return RaceData(
      raceData: json['raceData'] as String,
      lapNumber: json['lapNumber'] as int,
      lapTimeSeconds: (json['lapTimeSeconds'] as num).toDouble(),
      bestLapTimeSeconds: (json['bestLapTimeSeconds'] as num).toDouble(),
      racePosition: json['racePosition'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceData': raceData,
      'lapNumber': lapNumber,
      'lapTimeSeconds': lapTimeSeconds,
      'bestLapTimeSeconds': bestLapTimeSeconds,
      'racePosition': racePosition,
    };
  }
}