import 'dart:convert';

enum OfflineItemType {
  sos('sos'),
  update('update'),
  roadReport('road_report');

  final String value;
  const OfflineItemType(this.value);

  static OfflineItemType fromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'sos':
        return OfflineItemType.sos;
      case 'update':
        return OfflineItemType.update;
      case 'road_report':
        return OfflineItemType.roadReport;
      default:
        throw ArgumentError(
          'Unsupported OfflineItemType "$raw". Expected one of: sos, update, road_report.',
        );
    }
  }
}

class OfflineItem {
  final int? id;
  final OfflineItemType type;
  final Map<String, dynamic> payload;
  final String status;
  final DateTime createdAt;

  const OfflineItem({
    this.id,
    required this.type,
    required this.payload,
    this.status = 'pending',
    required this.createdAt,
  });

  String get encodedPayload => jsonEncode(payload);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'request_type': type.value,
      'payload': encodedPayload,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OfflineItem.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];
    Map<String, dynamic> decodedPayload;

    if (rawPayload is String) {
      final decoded = jsonDecode(rawPayload);
      decodedPayload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } else if (rawPayload is Map<String, dynamic>) {
      decodedPayload = rawPayload;
    } else {
      decodedPayload = <String, dynamic>{};
    }

    return OfflineItem(
      id: map['id'] as int?,
      type: OfflineItemType.fromString(map['request_type'] as String),
      payload: decodedPayload,
      status: (map['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  OfflineItem copyWith({
    int? id,
    OfflineItemType? type,
    Map<String, dynamic>? payload,
    String? status,
    DateTime? createdAt,
  }) {
    return OfflineItem(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
