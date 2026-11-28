import 'dart:convert';

enum OfflineItemStatus {
  pending,
  syncing,
  synced,
  failed;

  static OfflineItemStatus fromString(String value) {
    return OfflineItemStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => OfflineItemStatus.pending,
    );
  }
}

class OfflineItem {
  final int? id;
  final String clientId;
  final String requestType;
  final String payload;
  final OfflineItemStatus status;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;

  const OfflineItem({
    this.id,
    required this.clientId,
    required this.requestType,
    required this.payload,
    this.status = OfflineItemStatus.pending,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastError,
  });

  Map<String, dynamic> get decodedPayload {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  bool isReadyToSync(DateTime now) {
    if (status == OfflineItemStatus.synced ||
        status == OfflineItemStatus.syncing) {
      return false;
    }
    if (nextRetryAt == null) return true;
    return !now.isBefore(nextRetryAt!);
  }

  OfflineItem copyWith({
    int? id,
    String? clientId,
    String? requestType,
    String? payload,
    OfflineItemStatus? status,
    DateTime? createdAt,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return OfflineItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      requestType: requestType ?? this.requestType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt:
      clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'request_type': requestType,
      'payload': payload,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'last_error': lastError,
    };
  }

  factory OfflineItem.fromMap(Map<String, dynamic> map) {
    return OfflineItem(
      id: map['id'] as int?,
      clientId: (map['client_id'] as String?) ?? 'legacy-${map['id']}',
      requestType: map['request_type'] as String,
      payload: map['payload'] as String,
      status: OfflineItemStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: (map['retry_count'] as int?) ?? 0,
      nextRetryAt: map['next_retry_at'] != null
          ? DateTime.tryParse(map['next_retry_at'] as String)
          : null,
      lastError: map['last_error'] as String?,
    );
  }
}
