import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_request.dart';
import 'tracking_request_cache.dart';

typedef ActiveRequestStreamFactory =
    Stream<List<Map<String, dynamic>>> Function(String userId);

class TrackingService {
  TrackingService._()
    : _cache = TrackingRequestCache(),
      _requestStreamFactory = _createLiveRequestStream,
      _currentUserId = _getCurrentUserId,
      _reconnectDelay = const Duration(seconds: 3);

  TrackingService.forTesting({
    required TrackingRequestCacheStore cache,
    required ActiveRequestStreamFactory requestStreamFactory,
    required String? Function() currentUserId,
    Duration reconnectDelay = const Duration(milliseconds: 10),
  }) : _cache = cache,
       _requestStreamFactory = requestStreamFactory,
       _currentUserId = currentUserId,
       _reconnectDelay = reconnectDelay;

  static final TrackingService instance = TrackingService._();

  final TrackingRequestCacheStore _cache;
  final ActiveRequestStreamFactory _requestStreamFactory;
  final String? Function() _currentUserId;
  final Duration _reconnectDelay;

  static String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static Stream<List<Map<String, dynamic>>> _createLiveRequestStream(
    String userId,
  ) {
    return Supabase.instance.client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('resident_id', userId);
  }

  Future<void> _safeWrite(String userId, SosRequest request) async {
    try {
      await _cache.write(userId, request);
    } catch (_) {
      // Persistence is best-effort; live tracking remains authoritative.
    }
  }

  Future<void> _safeClear(String userId) async {
    try {
      await _cache.clear(userId);
    } catch (_) {
      // A failed cache cleanup must not hide server-confirmed completion.
    }
  }

  Stream<SosRequest?> watchActiveRequest() async* {
    final userId = _currentUserId();

    if (userId == null) {
      yield null;
      return;
    }

    SosRequest? lastKnown;

    try {
      final cached = await _cache.read(userId);
      if (cached != null && cached.isActive) {
        lastKnown = cached.asCached();
        yield lastKnown;
      }
    } catch (_) {
      // Cache read failure must not prevent the live stream from starting.
    }

    while (true) {
      try {
        await for (final rows in _requestStreamFactory(userId)) {
          final activeRequests =
              rows
                  .map((row) => SosRequest.fromJson(row))
                  .where((request) => request.isActive)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (activeRequests.isEmpty) {
            lastKnown = null;
            await _safeClear(userId);
            yield null;
            continue;
          }

          final latest = activeRequests.first.withServerConfirmation();
          lastKnown = latest;

          await _safeWrite(userId, latest);
          yield latest;
        }
      } catch (_) {
        // Reconnect below while retaining the last confirmed request.
      }

      if (lastKnown != null && lastKnown.isActive) {
        yield lastKnown.asCached();
      }

      await Future<void>.delayed(_reconnectDelay);
    }
  }
}
