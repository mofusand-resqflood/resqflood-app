class BlockedRoad {
  final String id;
  final String roadName;
  final String note;
  final double latitude;
  final double longitude;
  final String status;

  BlockedRoad({
    required this.id,
    required this.roadName,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory BlockedRoad.fromJson(Map<String, dynamic> json) {
    return BlockedRoad(
      id: json['id'] ?? '',
      roadName: json['road_name'] ?? 'Unknown Road',
      note: json['note'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'road_name': roadName,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
