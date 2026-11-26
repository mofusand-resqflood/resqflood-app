class SosRequest {
  final String emergencyType;
  final String description;
  final String location;
  final int peopleAffected;
  final bool medicalEmergency;
  final DateTime createdAt;

  const SosRequest({
    required this.emergencyType,
    required this.description,
    required this.location,
    required this.peopleAffected,
    required this.medicalEmergency,
    required this.createdAt,
  });
}
