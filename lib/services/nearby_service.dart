import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shelter.dart';

class NearbyService {
  static const _cacheKey = 'cached_open_shelters';

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    // Note: For Flutter Web/Chrome, this might prompt the browser for location
    return await Geolocator.getCurrentPosition();
  }

  Stream<List<Shelter>> getOpenShelters() async* {
    final userLocation = await _getCurrentLocation();

    // Fallback to Shah Alam if location fails (useful for testing)
    final double userLat = userLocation?.latitude ?? 3.0738;
    final double userLng = userLocation?.longitude ?? 101.5183;

    // Stream from Supabase where status is 'open'
    final stream = Supabase.instance.client
        .from('shelters')
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .map((data) {
      final shelters = data.map((json) => Shelter.fromJson(json)).toList();

      // Calculate distance for each shelter
      for (var shelter in shelters) {
        final distance = Geolocator.distanceBetween(
            userLat, userLng, shelter.latitude, shelter.longitude
        );
        // We can add distance to the shelter object or sort directly
      }

      // Sort by distance
      shelters.sort((a, b) {
        final distA = Geolocator.distanceBetween(userLat, userLng, a.latitude, a.longitude);
        final distB = Geolocator.distanceBetween(userLat, userLng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      _cacheShelters(shelters);
      return shelters;
    });

    yield* stream;
  }

  Future<void> _cacheShelters(List<Shelter> shelters) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(shelters.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);
  }

  Future<List<Shelter>> getCachedShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Shelter.fromJson(e)).toList();
    }
    return [];
  }
}
