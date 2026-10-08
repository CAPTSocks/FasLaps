class RaceTime {
  String type;
  DateTime startTime;

  RaceTime({
    required this.type,
    required this.startTime,
  });

  factory RaceTime.fromJson(Map<String, dynamic> json) {
    return RaceTime(
      type: json['type'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startTime': startTime.toIso8601String(),
    };
  }
}