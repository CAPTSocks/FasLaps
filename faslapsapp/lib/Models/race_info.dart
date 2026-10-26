class RaceInfo {
  final String type;
  final String raceId;
  final String raceName;
  final DateTime raceDate;
  final String raceHeat;
  final String raceType;
  final bool showFuelBar;
  final bool canPauseRace;
  final bool isMinuteRace;
  final int raceLength;

  RaceInfo({
    required this.type,
    required this.raceId,
    required this.raceName,
    required this.raceDate,
    required this.raceHeat,
    required this.raceType,
    required this.showFuelBar,
    required this.canPauseRace,
    required this.isMinuteRace,
    required this.raceLength,
  });

  factory RaceInfo.fromJson(Map<String, dynamic> json) {
    return RaceInfo(
      type: json['type'] as String,
      raceId: json['raceID'] as String,
      raceName: json['raceName'] as String,
      raceDate: DateTime.parse(json['raceDate'] as String),
      raceHeat: json['raceHeat'] as String,
      raceType: json['raceType'] as String,
      showFuelBar: json['showFuelBar'] as bool,
      canPauseRace: json['canPauseRace'] as bool,
      isMinuteRace: json['isMinuteRace'] as bool,
      raceLength: json['raceLength'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'raceID': raceId,
      'raceName': raceName,
      'raceDate': raceDate.toIso8601String(),
      'raceHeat': raceHeat,
      'raceType' : raceType,
      'showFuelBar' : showFuelBar,
      'canPauseRace' : canPauseRace,
      'isMinuteRace' : isMinuteRace,
      'raceLength' : raceLength,
    };
  }
}
