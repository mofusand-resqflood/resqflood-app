class BlockedRoad {
  final String id;
  final String roadName;
  final String note;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime? verifiedAt;

  BlockedRoad({
    required this.id,
    required this.roadName,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.verifiedAt,
  });

  factory BlockedRoad.fromJson(Map<String, dynamic> json) {
    return BlockedRoad(
      id: json['id'] ?? '',
      roadName: json['road_name'] ?? 'Unknown Road',
      note: json['note'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
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
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}