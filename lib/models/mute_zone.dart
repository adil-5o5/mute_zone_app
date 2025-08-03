import 'dart:math';

class MuteZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;

  MuteZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 50.0, // Default 50 meters
    this.isActive = true,
  });

  factory MuteZone.fromJson(Map<String, dynamic> json) {
    return MuteZone(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? 50.0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isActive': isActive,
    };
  }

  // Calculate distance between this zone and a given location
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double lat1Rad = latitude * pi / 180;
    double lat2Rad = lat * pi / 180;
    double deltaLatRad = (lat - latitude) * pi / 180;
    double deltaLngRad = (lng - longitude) * pi / 180;

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Check if a location is within this mute zone
  bool isLocationInZone(double lat, double lng) {
    return distanceTo(lat, lng) <= radius;
  }

  MuteZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
  }) {
    return MuteZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
    );
  }
}