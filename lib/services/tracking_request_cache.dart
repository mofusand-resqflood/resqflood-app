import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sos_request.dart';

abstract interface class TrackingRequestCacheStore {
  Future<SosRequest?> read(String userId);
  Future<void> write(String userId, SosRequest request);
  Future<void> clear(String userId);
}

class TrackingRequestCache implements TrackingRequestCacheStore {
  String _cacheKey(String userId) => 'rqf307.active_request.v1.$userId';

  @override
  Future<SosRequest?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(userId);
    final raw = prefs.getString(key);

    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cached = SosRequest.fromJson(decoded, fromCache: true);

      // Never restore data whose resident ownership cannot be verified.
      if (cached.residentId != userId || !cached.isActive) {
        try {
          await prefs.remove(key);
        } catch (_) {
          // Cache cleanup is best-effort.
        }
        return null;
      }

      return cached;
    } catch (_) {
      try {
        await prefs.remove(key);
      } catch (_) {
        // Cache cleanup must never prevent live tracking.
      }
      return null;
    }
  }

  @override
  Future<void> write(String userId, SosRequest request) async {
    if (request.residentId != userId) {
      throw ArgumentError('Tracking cache resident ID does not match its key.');
    }

    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(request.toTrackingCache());
    await prefs.setString(_cacheKey(userId), json);
  }

  @override
  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(userId));
  }
}