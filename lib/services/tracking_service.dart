import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_request.dart';
import 'tracking_request_cache.dart';

class TrackingService {
  TrackingService._();

  static final TrackingService instance = TrackingService._();

  final TrackingRequestCache _cache = TrackingRequestCache();

  SupabaseClient get _client => Supabase.instance.client;

  /// Streams the signed-in resident's latest active request.
  ///
  /// A cached request is emitted first when available. The live Supabase
  /// stream then replaces it with fresh data or clears it when no active
  /// request remains.
  Stream<SosRequest?> watchActiveRequest() async* {
    final user = _client.auth.currentUser;

    if (user == null) {
      yield null;
      return;
    }

    final userId = user.id;
    SosRequest? lastKnown;

    try {
      lastKnown = await _cache.read(userId);

      if (lastKnown != null && lastKnown.isActive) {
        yield lastKnown;
      }

      final requestStream = _client
          .from('requests')
          .stream(primaryKey: ['id'])
          .eq('resident_id', userId);

      await for (final rows in requestStream) {
        final activeRequests =
            rows
                .map((row) => SosRequest.fromJson(row))
                .where((request) => request.isActive)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (activeRequests.isEmpty) {
          lastKnown = null;
          await _cache.clear(userId);
          yield null;
          continue;
        }

        final latest = activeRequests.first;
        lastKnown = latest;
        await _cache.write(userId, latest);
        yield latest;
      }
    } catch (_) {
      // Keep the last confirmed request visible if the live stream fails.
      if (lastKnown != null && lastKnown.isActive) {
        yield lastKnown;
      } else {
        rethrow;
      }
    }
  }
}
