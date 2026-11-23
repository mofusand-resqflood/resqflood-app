import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';

class AnnouncementService {
  static const _cacheKey = 'cached_latest_announcement';

  // 1. Stream the latest 3 announcements
  Stream<List<Announcement>> getLatestAnnouncements() {
    return Supabase.instance.client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('published_at', ascending: false)
        .limit(3) // Get latest 3
        .map((data) {
      final announcements = data.map((json) => Announcement.fromJson(json)).toList();

      // If we have data, cache the latest one for offline use
      if (announcements.isNotEmpty) {
        _cacheLatestAnnouncement(announcements.first);
      }
      return announcements;
    });
  }

  // 2. Save to local storage (Offline Cache)
  Future<void> _cacheLatestAnnouncement(Announcement announcement) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(announcement.toJson());
    await prefs.setString(_cacheKey, jsonString);
  }

  // 3. Retrieve from local storage (For Offline)
  Future<Announcement?> getCachedAnnouncement() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString != null) {
      return Announcement.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}