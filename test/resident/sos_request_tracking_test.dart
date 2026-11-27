import 'dart:async';

import 'package:flutter/material.dart';
import 'package:resqflood_app/core/app_routes.dart';
import 'package:resqflood_app/features/resident/dashboard/widgets/active_request_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resqflood_app/models/sos_request.dart';
import 'package:resqflood_app/services/tracking_request_cache.dart';
import 'package:resqflood_app/services/tracking_service.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 26, 10);

  SosRequest makeRequest(String status, {int? eta}) {
    return SosRequest(
      emergencyType: 'Flood',
      description: 'Water entering house',
      location: 'Test location',
      peopleAffected: 3,
      medicalEmergency: false,
      createdAt: createdAt,
      id: 'request-123',
      residentId: 'resident-123',
      status: status,
      lastKnownEtaMinutes: eta,
    );
  }

  group('SosRequest active status', () {
    test('all in-progress statuses are active', () {
      for (final status in SosRequest.activeStatuses) {
        expect(makeRequest(status).isActive, isTrue, reason: status);
      }
    });

    test('completed statuses are not active', () {
      for (final status in SosRequest.completedStatuses) {
        expect(makeRequest(status).isActive, isFalse, reason: status);
      }
    });

    test('local SOS form request is not treated as active server request', () {
      final localRequest = SosRequest(
        emergencyType: 'Flood',
        description: 'Help',
        location: 'Home',
        peopleAffected: 2,
        medicalEmergency: false,
        createdAt: createdAt,
      );

      expect(localRequest.isActive, isFalse);
    });
  });

  group('SosRequest ETA label', () {
    test('shows unavailable when ETA is null', () {
      expect(makeRequest('pending').etaLabel, 'ETA not available yet');
    });

    test('shows less than one minute for zero', () {
      expect(makeRequest('on_the_way', eta: 0).etaLabel, 'Less than 1 minute');
    });

    test('formats one minute', () {
      expect(makeRequest('on_the_way', eta: 1).etaLabel, 'About 1 minute');
    });

    test('formats multiple minutes', () {
      expect(makeRequest('on_the_way', eta: 12).etaLabel, 'About 12 minutes');
    });
  });

  test('tracking cache excludes private request details', () {
    final request = makeRequest('assigned', eta: 15);
    final cache = request.toTrackingCache();

    expect(cache['id'], 'request-123');
    expect(cache['status'], 'assigned');
    expect(cache['last_known_eta_minutes'], 15);
    expect(cache.containsKey('description'), isFalse);
    expect(cache.containsKey('location'), isFalse);
    expect(cache.containsKey('medical_emergency'), isFalse);
    expect(cache.containsKey('people_affected'), isFalse);
  });

  test('fromJson maps database tracking fields', () {
    final request = SosRequest.fromJson({
      'id': 'request-456',
      'resident_id': 'resident-456',
      'help_type': 'Flood',
      'description': 'Water rising',
      'people_count': 4,
      'status': 'on_the_way',
      'last_known_eta_minutes': 8,
      'created_at': createdAt.toIso8601String(),
      'updated_at': createdAt.toIso8601String(),
    });

    expect(request.id, 'request-456');
    expect(request.residentId, 'resident-456');
    expect(request.emergencyType, 'Flood');
    expect(request.peopleAffected, 4);
    expect(request.status, 'on_the_way');
    expect(request.lastKnownEtaMinutes, 8);
    expect(request.isActive, isTrue);
  });

  group('TrackingRequestCache', () {
    late TrackingRequestCache cache;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cache = TrackingRequestCache();
    });

    test('persists and restores an active request', () async {
      await cache.write('resident-123', makeRequest('assigned', eta: 15));

      final restored = await cache.read('resident-123');

      expect(restored, isNotNull);
      expect(restored!.id, 'request-123');
      expect(restored.residentId, 'resident-123');
      expect(restored.status, 'assigned');
      expect(restored.lastKnownEtaMinutes, 15);
      expect(restored.isActive, isTrue);
      expect(restored.isCached, isTrue);
    });

    test('does not restore a completed request', () async {
      await cache.write('resident-123', makeRequest('rescued'));

      final restored = await cache.read('resident-123');

      expect(restored, isNull);
    });

    test('clears a resident cache entry', () async {
      await cache.write('resident-123', makeRequest('on_the_way', eta: 8));

      await cache.clear('resident-123');

      expect(await cache.read('resident-123'), isNull);
    });

    test('keeps cache entries isolated by resident ID', () async {
      await cache.write('resident-123', makeRequest('assigned', eta: 15));

      expect(await cache.read('resident-456'), isNull);
      expect((await cache.read('resident-123'))?.id, 'request-123');
    });
  });

  group('ActiveRequestCard visibility', () {
    Future<void> pumpCard(
      WidgetTester tester,
      Stream<SosRequest?> requestStream,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActiveRequestCard(requestStream: requestStream)),
        ),
      );
      await tester.pump();
    }

    for (final status in [
      'pending',
      'acknowledged',
      'assigned',
      'on_the_way',
      'on_scene',
      'transporting',
    ]) {
      testWidgets('shows card for active status: $status', (tester) async {
        final request = makeRequest(status, eta: 12);

        await pumpCard(tester, Stream.value(request));

        expect(find.text('Active emergency request'), findsOneWidget);
        expect(find.text(request.statusLabel), findsOneWidget);
        expect(find.text('Last-known ETA: About 12 minutes'), findsOneWidget);
        expect(find.text('View request'), findsOneWidget);
      });
    }

    for (final status in ['rescued', 'closed', 'cancelled']) {
      testWidgets('hides card for completed status: $status', (tester) async {
        await pumpCard(tester, Stream.value(makeRequest(status)));

        expect(find.text('Active emergency request'), findsNothing);
        expect(find.text('View request'), findsNothing);
      });
    }

    testWidgets('hides card when there is no active request', (tester) async {
      await pumpCard(tester, Stream.value(null));

      expect(find.text('Active emergency request'), findsNothing);
      expect(find.text('View request'), findsNothing);
    });
  });

  group('ActiveRequestCard navigation', () {
    testWidgets('card tap opens the Active Request screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.activeRequest: (_) =>
                const Scaffold(body: Text('Active Request destination')),
          },
          home: Scaffold(
            body: ActiveRequestCard(
              requestStream: Stream<SosRequest?>.value(
                makeRequest('assigned', eta: 12),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('View request'));
      await tester.pumpAndSettle();

      expect(find.text('Active Request destination'), findsOneWidget);
    });
  });
  group('TrackingService resilience', () {
    test('cache failures do not prevent live request delivery', () async {
      final requestStreamReady = Completer<void>();
      final resultCompleter = Completer<SosRequest>();

      final controller = StreamController<List<Map<String, dynamic>>>(
        onListen: () {
          requestStreamReady.complete();
        },
      );

      final service = TrackingService.forTesting(
        cache: _FailingTrackingCache(),
        requestStreamFactory: (userId) {
          return controller.stream;
        },
        userIdStreamFactory: () {
          return Stream<String?>.value('resident-123');
        },
      );

      final subscription = service.watchActiveRequest().listen(
        (request) {
          if (request != null && !resultCompleter.isCompleted) {
            resultCompleter.complete(request);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!resultCompleter.isCompleted) {
            resultCompleter.completeError(error, stackTrace);
          }
        },
      );

      try {
        await requestStreamReady.future.timeout(const Duration(seconds: 5));

        controller.add([
          {
            'id': 'server-request-1',
            'resident_id': 'resident-123',
            'help_type': 'Flood',
            'status': 'on_the_way',
            'last_known_eta_minutes': 7,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(result.id, 'server-request-1');
        expect(result.isActive, isTrue);
        expect(result.isCached, isFalse);
        expect(result.lastConfirmedAt, isNotNull);
      } finally {
        await subscription.cancel();

        await controller.close();
      }
    });
  });
  group('TrackingService review regressions', () {
    test('first live stream error reconnects and subscribes again', () async {
      final secondReady = Completer<void>();
      final secondController = StreamController<List<Map<String, dynamic>>>(
        onListen: () {
          if (!secondReady.isCompleted) secondReady.complete();
        },
      );
      final errorReceived = Completer<Object>();
      var attempts = 0;

      final service = TrackingService.forTesting(
        cache: _FailingTrackingCache(),
        requestStreamFactory: (userId) {
          attempts++;
          if (attempts == 1) {
            return Stream<List<Map<String, dynamic>>>.error(
              StateError('First connection failed'),
            );
          }
          return secondController.stream;
        },
        userIdStreamFactory: () => Stream<String?>.value('resident-123'),
        reconnectDelay: const Duration(milliseconds: 10),
      );

      final subscription = service.watchActiveRequest().listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          if (!errorReceived.isCompleted) errorReceived.complete(error);
        },
      );

      try {
        expect(
          await errorReceived.future.timeout(const Duration(seconds: 5)),
          isA<StateError>(),
        );
        await secondReady.future.timeout(const Duration(seconds: 5));
        expect(attempts, 2);
      } finally {
        await subscription.cancel();
        await secondController.close();
      }
    });

    test('live request is emitted as cached after a stream error', () async {
      final streamReady = Completer<void>();
      final liveReceived = Completer<SosRequest>();
      final cachedReceived = Completer<SosRequest>();
      final controller = StreamController<List<Map<String, dynamic>>>(
        onListen: () {
          if (!streamReady.isCompleted) streamReady.complete();
        },
      );

      final service = TrackingService.forTesting(
        cache: _FailingTrackingCache(),
        requestStreamFactory: (_) => controller.stream,
        userIdStreamFactory: () => Stream<String?>.value('resident-123'),
      );

      final subscription = service.watchActiveRequest().listen((request) {
        if (request == null) return;
        if (!request.isCached && !liveReceived.isCompleted) {
          liveReceived.complete(request);
        } else if (request.isCached && !cachedReceived.isCompleted) {
          cachedReceived.complete(request);
        }
      });

      try {
        await streamReady.future.timeout(const Duration(seconds: 5));
        controller.add([
          {
            'id': 'server-request-1',
            'resident_id': 'resident-123',
            'help_type': 'Flood',
            'status': 'on_the_way',
            'last_known_eta_minutes': 7,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);

        final live = await liveReceived.future.timeout(
          const Duration(seconds: 5),
        );
        expect(live.isCached, isFalse);

        controller.addError(StateError('Connection interrupted'));

        final fallback = await cachedReceived.future.timeout(
          const Duration(seconds: 5),
        );
        expect(fallback.id, 'server-request-1');
        expect(fallback.isCached, isTrue);
      } finally {
        await subscription.cancel();
        await controller.close();
      }
    });

    test('server empty result emits null when cache clearing fails', () async {
      final streamReady = Completer<void>();
      final clearedOnServer = Completer<void>();
      var nullEvents = 0;

      final controller = StreamController<List<Map<String, dynamic>>>(
        onListen: () {
          if (!streamReady.isCompleted) streamReady.complete();
        },
      );

      final service = TrackingService.forTesting(
        cache: _FailingTrackingCache(),
        requestStreamFactory: (_) => controller.stream,
        userIdStreamFactory: () => Stream<String?>.value('resident-123'),
      );

      final subscription = service.watchActiveRequest().listen((request) {
        if (request == null) {
          nullEvents++;
          // The first null clears the previous account's display.
          // The second null is the server-confirmed empty result.
          if (nullEvents >= 2 && !clearedOnServer.isCompleted) {
            clearedOnServer.complete();
          }
        }
      });

      try {
        await streamReady.future.timeout(const Duration(seconds: 5));
        controller.add([]);
        await clearedOnServer.future.timeout(const Duration(seconds: 5));
        expect(nullEvents, greaterThanOrEqualTo(2));
      } finally {
        await subscription.cancel();
        await controller.close();
      }
    });

    test('account switch clears the previous resident request', () async {
      final authController = StreamController<String?>();
      final firstReady = Completer<void>();
      final secondReady = Completer<void>();
      final firstRequestReceived = Completer<void>();
      final secondRequestReceived = Completer<void>();
      final previousRequestCleared = Completer<void>();

      StreamController<List<Map<String, dynamic>>>? firstController;
      StreamController<List<Map<String, dynamic>>>? secondController;

      final receivedIds = <String?>[];
      var sawFirstRequest = false;

      final service = TrackingService.forTesting(
        cache: _FailingTrackingCache(),
        requestStreamFactory: (userId) {
          if (userId == 'resident-123') {
            firstController = StreamController<List<Map<String, dynamic>>>(
              onListen: () {
                if (!firstReady.isCompleted) firstReady.complete();
              },
            );
            return firstController!.stream;
          }

          secondController = StreamController<List<Map<String, dynamic>>>(
            onListen: () {
              if (!secondReady.isCompleted) secondReady.complete();
            },
          );
          return secondController!.stream;
        },
        userIdStreamFactory: () => authController.stream,
      );

      final subscription = service.watchActiveRequest().listen((request) {
        if (request == null) {
          if (sawFirstRequest && !previousRequestCleared.isCompleted) {
            previousRequestCleared.complete();
          }
          return;
        }

        receivedIds.add(request.id);
        if (request.id == 'first-account-request') {
          sawFirstRequest = true;
          if (!firstRequestReceived.isCompleted) {
            firstRequestReceived.complete();
          }
        }
        if (request.id == 'second-account-request' &&
            !secondRequestReceived.isCompleted) {
          secondRequestReceived.complete();
        }
      });

      try {
        authController.add('resident-123');
        await firstReady.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw StateError('Timed out waiting for first account stream'),
        );

        firstController!.add([
          {
            'id': 'first-account-request',
            'resident_id': 'resident-123',
            'help_type': 'Flood',
            'status': 'assigned',
            'last_known_eta_minutes': 8,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        await firstRequestReceived.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw StateError('Timed out waiting for first account request'),
        );

        authController.add('resident-456');
        await previousRequestCleared.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw StateError(
            'Timed out waiting for old account request to clear',
          ),
        );
        await secondReady.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw StateError('Timed out waiting for second account stream'),
        );

        // A late event from the old stream must not reach the new account.
        firstController!.add([
          {
            'id': 'stale-old-account-request',
            'resident_id': 'resident-123',
            'help_type': 'Flood',
            'status': 'on_scene',
            'last_known_eta_minutes': 2,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(receivedIds, isNot(contains('stale-old-account-request')));

        secondController!.add([
          {
            'id': 'second-account-request',
            'resident_id': 'resident-456',
            'help_type': 'Flood',
            'status': 'acknowledged',
            'last_known_eta_minutes': 12,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        await secondRequestReceived.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw StateError('Timed out waiting for second account request'),
        );
        expect(receivedIds, contains('second-account-request'));
      } finally {
        await subscription.cancel();
        await authController.close();
        await firstController?.close();
        await secondController?.close();
      }
    });
  });
}

class _FailingTrackingCache implements TrackingRequestCacheStore {
  @override
  Future<SosRequest?> read(String userId) {
    return Future<SosRequest?>.error(StateError('Cache read failed'));
  }

  @override
  Future<void> write(String userId, SosRequest request) {
    return Future<void>.error(StateError('Cache write failed'));
  }

  @override
  Future<void> clear(String userId) {
    return Future<void>.error(StateError('Cache clear failed'));
  }
}
