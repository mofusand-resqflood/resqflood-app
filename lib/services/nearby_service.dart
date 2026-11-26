import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shelter.dart';

class NearbyService {
  static const _cacheKey = 'cached_open_shelters';

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Stream<List<Shelter>> getOpenShelters() async* {
    final userLocation = await _getCurrentLocation();

    // Fallback to Shah Alam if location fails
    final double userLat = userLocation?.latitude ?? 3.0738;
    final double userLng = userLocation?.longitude ?? 101.5183;

    final stream = Supabase.instance.client
        .from('shelters')
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .map<List<Shelter>>((data) {
      final List<Shelter> shelters = data.map<Shelter>((json) {
        final double lat = (json['latitude'] ?? 0.0).toDouble();
        final double lng = (json['longitude'] ?? 0.0).toDouble();
        final dist = Geolocator.distanceBetween(userLat, userLng, lat, lng);

        return Shelter.fromJson(json, distance: dist);
      }).toList();

      shelters.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
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
      final userLocation = await _getCurrentLocation();
      final double userLat = userLocation?.latitude ?? 3.0738;
      final double userLng = userLocation?.longitude ?? 101.5183;

      final List<Shelter> shelters = decoded.map((e) {
        final base = Shelter.fromJson(e);
        // Recalculate distance for cached items
        final dist = Geolocator.distanceBetween(userLat, userLng, base.latitude, base.longitude);
        return Shelter.fromJson(e, distance: dist);
      }).toList();

      shelters.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      return shelters;
    }
    return [];
  }
}