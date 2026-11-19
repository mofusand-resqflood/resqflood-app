import 'package:flutter_test/flutter_test.dart';
import 'package:resqflood_app/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResidentLocation', () {
    test('asLastKnown keeps the fix and marks it cached', () {
      final captured = DateTime.utc(2026, 11, 18, 9, 30);
      final fresh = ResidentLocation(
        latitude: 1.5371,
        longitude: 103.6590,
        accuracyMeters: 12.5,
        capturedAt: captured,
        isLastKnown: false,
      );

      final cached = fresh.asLastKnown();

      expect(cached.isLastKnown, isTrue);
      expect(cached.latitude, fresh.latitude);
      expect(cached.longitude, fresh.longitude);
      expect(cached.accuracyMeters, fresh.accuracyMeters);
      expect(cached.capturedAt, captured);
    });
  });

  group('LocationResult', () {
    test('hasLocation is false without a location', () {
      const result = LocationResult(
        location: null,
        issue: LocationIssue.permissionDenied,
      );

      expect(result.hasLocation, isFalse);
    });

    test('hasLocation is true with a cached location', () {
      final result = LocationResult(
        location: ResidentLocation(
          latitude: 1.4927,
          longitude: 103.7414,
          accuracyMeters: 30,
          capturedAt: DateTime.utc(2026, 11, 18, 8),
          isLastKnown: true,
        ),
        issue: LocationIssue.permissionDeniedForever,
      );

      expect(result.hasLocation, isTrue);
    });
  });

  group('LocationService cached fallback', () {
    test('falls back to the cached fix when live GPS is unavailable', () async {
      final captured = DateTime.utc(2026, 11, 18, 8);
      SharedPreferences.setMockInitialValues({
        'resident_last_latitude': 1.4927,
        'resident_last_longitude': 103.7414,
        'resident_last_accuracy': 30.0,
        'resident_last_captured_at': captured.millisecondsSinceEpoch,
      });

      final result = await LocationService().getCurrentLocation(
        requestPermission: false,
      );

      expect(result.hasLocation, isTrue);
      final location = result.location!;
      expect(location.latitude, closeTo(1.4927, 1e-9));
      expect(location.longitude, closeTo(103.7414, 1e-9));
      expect(location.isLastKnown, isTrue);
      expect(location.capturedAt.toUtc(), captured);
      expect(
        result.issue,
        isNotNull,
        reason: 'the caller must still learn that live GPS failed',
      );
    });

    test('reports an issue and no location when nothing is cached', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final result = await LocationService().getCurrentLocation(
        requestPermission: false,
      );

      expect(result.hasLocation, isFalse);
      expect(result.issue, isNotNull);
    });
  });
}
