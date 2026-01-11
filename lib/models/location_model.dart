const String sqlTableLocations = 'locations';

class LocationFields {
  static const String id = '_id';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const timestamp = 'timestamp';

  static final List<String> values = [id, latitude, longitude, timestamp];
}

class LocationModel {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const LocationModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  LocationModel copy({
    int? id,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) => LocationModel(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    timestamp: timestamp ?? this.timestamp,
  );

  static LocationModel fromJson(Map<String, Object?> json) => LocationModel(
    id: json[LocationFields.id] as int?,
    latitude: json[LocationFields.latitude] as double,
    longitude: json[LocationFields.longitude] as double,
    timestamp: DateTime.parse(json[LocationFields.timestamp] as String),
  );

  Map<String, Object?> toJson() => {
    LocationFields.id: id,
    LocationFields.latitude: latitude,
    LocationFields.longitude: longitude,
    LocationFields.timestamp: timestamp.toIso8601String(),
  };
}
