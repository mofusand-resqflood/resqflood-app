import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sos_request.dart';

class TrackingRequestCache {
  String _cacheKey(String userId) => 'rqf307.active_request.v1.$userId';

  Future<SosRequest?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(userId);
    final raw = prefs.getString(key);

    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cached = SosRequest.fromJson(decoded, fromCache: true);

      if (cached.isActive) return cached;

      await prefs.remove(key);
      return null;
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> write(String userId, SosRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(request.toTrackingCache(cachedAt: DateTime.now()));
    await prefs.setString(_cacheKey(userId), json);
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(userId));
  }
}
