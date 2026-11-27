class SosRequest {
  final String emergencyType;
  final String description;
  final String location;
  final int peopleAffected;
  final bool medicalEmergency;
  final DateTime createdAt;

  final String? id;
  final String? residentId;
  final String status;
  final int? lastKnownEtaMinutes;
  final DateTime? updatedAt;

  final bool isCached;
  final DateTime? lastConfirmedAt;

  const SosRequest({
    required this.emergencyType,
    required this.description,
    required this.location,
    required this.peopleAffected,
    required this.medicalEmergency,
    required this.createdAt,
    this.id,
    this.residentId,
    this.status = 'pending',
    this.lastKnownEtaMinutes,
    this.updatedAt,
    this.isCached = false,
    this.lastConfirmedAt,
  });

  static const Set<String> activeStatuses = {
    'pending',
    'acknowledged',
    'assigned',
    'on_the_way',
    'on_scene',
    'transporting',
  };

  static const Set<String> completedStatuses = {
    'rescued',
    'closed',
    'cancelled',
  };

  bool get isActive => id != null && activeStatuses.contains(status);

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Request received';
      case 'acknowledged':
        return 'Request acknowledged';
      case 'assigned':
        return 'Response team assigned';
      case 'on_the_way':
        return 'Team on the way';
      case 'on_scene':
        return 'Team at your location';
      case 'transporting':
        return 'Transport in progress';
      case 'rescued':
        return 'Rescue completed';
      case 'closed':
        return 'Request closed';
      case 'cancelled':
        return 'Request cancelled';
      default:
        return 'Request status unavailable';
    }
  }

  String get etaLabel {
    final eta = lastKnownEtaMinutes;
    if (eta == null) return 'ETA not available yet';
    if (eta == 0) return 'Less than 1 minute';
    if (eta == 1) return 'About 1 minute';
    return 'About $eta minutes';
  }

  /// Marks a server response as freshly confirmed.
  SosRequest withServerConfirmation({DateTime? confirmedAt}) {
    return SosRequest(
      emergencyType: emergencyType,
      description: description,
      location: location,
      peopleAffected: peopleAffected,
      medicalEmergency: medicalEmergency,
      createdAt: createdAt,
      id: id,
      residentId: residentId,
      status: status,
      lastKnownEtaMinutes: lastKnownEtaMinutes,
      updatedAt: updatedAt,
      isCached: false,
      lastConfirmedAt: confirmedAt ?? DateTime.now(),
    );
  }

  /// Returns the last-known request with an explicit stale-data marker.
  SosRequest asCached() {
    return SosRequest(
      emergencyType: emergencyType,
      description: description,
      location: location,
      peopleAffected: peopleAffected,
      medicalEmergency: medicalEmergency,
      createdAt: createdAt,
      id: id,
      residentId: residentId,
      status: status,
      lastKnownEtaMinutes: lastKnownEtaMinutes,
      updatedAt: updatedAt,
      isCached: true,
      lastConfirmedAt: lastConfirmedAt,
    );
  }

  factory SosRequest.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      return DateTime.tryParse(value.toString()) ?? fallback;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final now = DateTime.now();
    final created = parseDate(json['created_at'], now);

    return SosRequest(
      id: json['id']?.toString(),
      residentId: json['resident_id']?.toString(),
      emergencyType:
          (json['help_type'] ?? json['emergency_type'] ?? 'Emergency')
              .toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      peopleAffected:
          parseInt(json['people_count'] ?? json['people_affected']) ?? 0,
      medicalEmergency: json['medical_emergency'] == true,
      createdAt: created,
      status: (json['status'] ?? 'pending').toString(),
      lastKnownEtaMinutes: parseInt(json['last_known_eta_minutes']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      isCached: fromCache || json['is_cached'] == true,
      lastConfirmedAt: json['cached_at'] == null
          ? null
          : DateTime.tryParse(json['cached_at'].toString()),
    );
  }

  /// Stores only the minimum information needed to show last-known tracking.
  /// Descriptions, medical details and location data are deliberately excluded.
  Map<String, dynamic> toTrackingCache({DateTime? cachedAt}) {
    return {
      'id': id,
      'resident_id': residentId,
      'status': status,
      'last_known_eta_minutes': lastKnownEtaMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cached_at': (lastConfirmedAt ?? cachedAt ?? DateTime.now())
          .toIso8601String(),
    };
  }
}
