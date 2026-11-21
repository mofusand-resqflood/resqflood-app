import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationIssue {
  locationServicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  currentLocationUnavailable,
}

class ResidentLocation {
  const ResidentLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.isLastKnown,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
  final bool isLastKnown;

  ResidentLocation asLastKnown() {
    return ResidentLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      capturedAt: capturedAt,
      isLastKnown: true,
    );
  }
}

class LocationResult {
  const LocationResult({required this.location, this.issue});

  /// May contain a cached location even when [issue] is non-null.
  final ResidentLocation? location;
  final LocationIssue? issue;

  bool get hasLocation => location != null;
}

class LocationService {
  static const Duration _locationTimeout = Duration(seconds: 15);

  static const String _latitudeKey = 'resident_last_latitude';
  static const String _longitudeKey = 'resident_last_longitude';
  static const String _accuracyKey = 'resident_last_accuracy';
  static const String _capturedAtKey = 'resident_last_captured_at';

  /// Requests permission if needed, then attempts to get a fresh GPS position.
  ///
  /// If the fresh position cannot be obtained, returns the most recent cached
  /// app or device location, if available. [LocationResult.issue] explains
  /// why the fresh location could not be obtained.
  Future<LocationResult> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();

      if (!servicesEnabled) {
        final permission = await Geolocator.checkPermission();

        return await _withLastKnownLocation(
          LocationIssue.locationServicesDisabled,
          canReadDeviceLocation: _hasLocationPermission(permission),
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return await _withLastKnownLocation(
          LocationIssue.permissionDeniedForever,
          canReadDeviceLocation: false,
        );
      }

      if (permission == LocationPermission.denied) {
        return await _withLastKnownLocation(
          LocationIssue.permissionDenied,
          canReadDeviceLocation: false,
        );
      }

      if (!_hasLocationPermission(permission)) {
        return await _withLastKnownLocation(
          LocationIssue.permissionDenied,
          canReadDeviceLocation: false,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      );

      final location = ResidentLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
        isLastKnown: false,
      );

      await _saveLocation(location);

      return LocationResult(location: location);
    } on TimeoutException {
      return _withLastKnownLocation(
        LocationIssue.currentLocationUnavailable,
        canReadDeviceLocation: true,
      );
    } catch (_) {
      return _withLastKnownLocation(
        LocationIssue.currentLocationUnavailable,
        canReadDeviceLocation: true,
      );
    }
  }

  /// Opens the relevant device setting from the GPS tile.
  Future<bool> openSettingsFor(LocationIssue issue) async {
    try {
      if (issue == LocationIssue.locationServicesDisabled) {
        return await Geolocator.openLocationSettings();
      }

      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<LocationResult> _withLastKnownLocation(
    LocationIssue issue, {
    required bool canReadDeviceLocation,
  }) async {
    final storedLocation = await _readStoredLocation();
    ResidentLocation? deviceLocation;

    if (canReadDeviceLocation) {
      try {
        final position = await Geolocator.getLastKnownPosition();

        if (position != null) {
          deviceLocation = ResidentLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
            capturedAt: position.timestamp,
            isLastKnown: true,
          );
        }
      } catch (_) {
        // The saved app location can still be used if the platform lookup
        // is unavailable.
      }
    }

    final candidates = <ResidentLocation>[?storedLocation, ?deviceLocation];

    if (candidates.isEmpty) {
      return LocationResult(location: null, issue: issue);
    }

    candidates.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    return LocationResult(
      location: candidates.first.asLastKnown(),
      issue: issue,
    );
  }

  Future<ResidentLocation?> _readStoredLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final latitude = preferences.getDouble(_latitudeKey);
      final longitude = preferences.getDouble(_longitudeKey);
      final accuracy = preferences.getDouble(_accuracyKey);
      final capturedAtMilliseconds = preferences.getInt(_capturedAtKey);

      if (latitude == null ||
          longitude == null ||
          capturedAtMilliseconds == null) {
        return null;
      }

      return ResidentLocation(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracy ?? 0,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMilliseconds),
        isLastKnown: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocation(ResidentLocation location) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setDouble(_latitudeKey, location.latitude);
      await preferences.setDouble(_longitudeKey, location.longitude);
      await preferences.setDouble(_accuracyKey, location.accuracyMeters);
      await preferences.setInt(
        _capturedAtKey,
        location.capturedAt.millisecondsSinceEpoch,
      );
    } catch (_) {
      // A storage failure should not discard the fresh GPS result.
    }
  }

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
