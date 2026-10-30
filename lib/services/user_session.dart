import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'logged_in_user_id';
  static const String _userNameKey = 'logged_in_user_name';
  static const String _userEmailKey = 'logged_in_user_email';

  static Future<void> saveUser({
    required int userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}
