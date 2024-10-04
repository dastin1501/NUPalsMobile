import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Save userId
  static Future<void> saveUserId(String userId) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('userId', userId);
  }

  // Get userId
  static Future<String?> getUserId() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('userId');
  }

  // Remove userId
  static Future<void> removeUserId() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove('userId');
  }
}
