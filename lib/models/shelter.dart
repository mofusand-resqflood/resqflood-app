class Shelter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int capacity;
  final int currentOccupancy;
  final String status;
  final double? distance; // Optional field for UI

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
    this.distance,
  });

  int get freePlaces => capacity - currentOccupancy;

  // Notice the {double? distance} here
  factory Shelter.fromJson(Map<String, dynamic> json, {double? distance}) {
    return Shelter(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Shelter',
      address: json['address'] ?? 'No address',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      capacity: (json['capacity'] ?? 0).toInt(),
      currentOccupancy: (json['current_occupancy'] ?? 0).toInt(),
      status: json['status'] ?? 'closed',
      distance: distance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'status': status,
    };
  }
}