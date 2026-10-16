class RaceFinished {
  String type;
  DateTime endTime;

  RaceFinished({
    required this.type,
    required this.endTime,
  });

  factory RaceFinished.fromJson(Map<String, dynamic> json) {
    return RaceFinished(
      type: json['type'] as String,
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'endTime': endTime.toIso8601String(),
    };
  }
}