class FuelData {
  String type;
  int fuelLevel;

  FuelData({
    required this.type,
    required this.fuelLevel,
  });

  factory FuelData.fromJson(Map<String, dynamic> json) {
    return FuelData(
      type: json['type'] as String,
      fuelLevel: json['fuelLevel'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fuelLevel': fuelLevel,
    };
  }
}