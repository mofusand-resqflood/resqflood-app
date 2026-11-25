import 'package:shared_preferences/shared_preferences.dart';

class AuthRoleCache {
  static String _key(String userId) => 'auth_role_$userId';

  static Future<void> save(String userId, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), role);
    } catch (_) {
      // A cache failure must not block authentication.
    }
  }

  static Future<String?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key(userId));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {
      // A cache failure must not block sign out.
    }
  }
}
