import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_request.dart';
import 'tracking_request_cache.dart';

typedef ActiveRequestStreamFactory =
    Stream<List<Map<String, dynamic>>> Function(String userId);

typedef AuthUserIdStreamFactory = Stream<String?> Function();

class TrackingService {
  TrackingService._()
    : _cache = TrackingRequestCache(),
      _requestStreamFactory = _createLiveRequestStream,
      _userIdStreamFactory = _authUserIdChanges,
      _reconnectDelay = const Duration(seconds: 3);

  TrackingService.forTesting({
    required this._cache,
    required this._requestStreamFactory,
    required this._userIdStreamFactory,
    this._reconnectDelay = const Duration(milliseconds: 10),
  });

  static final TrackingService instance = TrackingService._();

  final TrackingRequestCacheStore _cache;
  final ActiveRequestStreamFactory _requestStreamFactory;
  final AuthUserIdStreamFactory _userIdStreamFactory;
  final Duration _reconnectDelay;

  static Stream<String?> _authUserIdChanges() {
    return Supabase.instance.client.auth.onAuthStateChange
        .map((state) => state.session?.user.id)
        .distinct();
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

  Stream<SosRequest?> watchActiveRequest() {
    return Stream<SosRequest?>.multi((controller) {
      StreamSubscription<String?>? authSubscription;
      StreamSubscription<SosRequest?>? requestSubscription;
      var generation = 0;

      Future<void> switchUser(String? userId) async {
        final currentGeneration = ++generation;

        // Clear the previous resident's information immediately.
        controller.add(null);

        final previousSubscription = requestSubscription;
        requestSubscription = null;

        // Do not block the new account while the old stream shuts down.
        // Generation checks prevent any late events from reaching the listener.
        unawaited(previousSubscription?.cancel());

        if (generation != currentGeneration || userId == null) {
          return;
        }

        // Restore only a cache entry that belongs to this resident.
        SosRequest? initialRequest;

        try {
          final cached = await _cache.read(userId);

          if (generation != currentGeneration) return;

          if (cached != null &&
              cached.isActive &&
              cached.residentId == userId) {
            initialRequest = cached.asCached();
            controller.add(initialRequest);
          }
        } catch (_) {
          // Cache failures must not prevent live tracking.
        }

        if (generation != currentGeneration) return;

        final nextSubscription =
            _watchUser(userId, initialRequest: initialRequest).listen(
              (request) {
                if (generation == currentGeneration) {
                  controller.add(request);
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                if (generation == currentGeneration) {
                  controller.addError(error, stackTrace);
                }
              },
            );

        if (generation == currentGeneration) {
          requestSubscription = nextSubscription;
        } else {
          await nextSubscription.cancel();
        }
      }

      authSubscription = _userIdStreamFactory().listen(
        (userId) {
          unawaited(switchUser(userId));
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        generation++;

        await authSubscription?.cancel();

        final activeRequestSubscription = requestSubscription;
        requestSubscription = null;

        if (activeRequestSubscription != null) {
          unawaited(activeRequestSubscription.cancel());
        }
      };
    });
  }

  Stream<SosRequest?> _watchUser(
    String userId, {
    SosRequest? initialRequest,
  }) async* {
    SosRequest? lastKnown = initialRequest;

    while (true) {
      var emittedCachedFallback = false;

      try {
        await for (final rows in _requestStreamFactory(userId)) {
          final activeRequests =
              rows
                  .map((row) => SosRequest.fromJson(row))
                  .where(
                    (request) =>
                        request.isActive && request.residentId == userId,
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (activeRequests.isEmpty) {
            lastKnown = null;
            yield null;
            await _safeClear(userId);
            continue;
          }

          final latest = activeRequests.first.withServerConfirmation();
          lastKnown = latest;

          // Deliver server-confirmed data before attempting local persistence.
          yield latest;
          await _safeWrite(userId, latest);
        }
      } catch (error, stackTrace) {
        // Preserve the last confirmed request when live updates fail.
        if (lastKnown != null && lastKnown.isActive) {
          yield lastKnown.asCached();
          emittedCachedFallback = true;
        } else {
          // Let the UI show a retry message while reconnection continues.
          yield* Stream<SosRequest?>.error(error, stackTrace);
        }
      }

      if (!emittedCachedFallback && lastKnown != null && lastKnown.isActive) {
        yield lastKnown.asCached();
      }

      await Future<void>.delayed(_reconnectDelay);
    }
  }
}
