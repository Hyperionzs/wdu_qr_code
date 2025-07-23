import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  static String username = '';
  static String userId = '';
  static String token = '';
  static bool isLoggedIn = false;

  static Future<void> setUserData(String name, String id, String apiToken) async {
    username = name;
    userId = id; // Set the user ID
    token = apiToken;
    isLoggedIn = true;
    await _saveToPrefs(name, id, apiToken);
  }

  static Future<void> _saveToPrefs(String name, String id, String apiToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    await prefs.setString('userId', id); // Save user ID to preferences
    await prefs.setString('token', apiToken);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<bool> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    userId = prefs.getString('userId') ?? ''; // Load user ID from preferences
    token = prefs.getString('token') ?? '';
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<void> clearUserData() async {
    username = '';
    userId = ''; // Clear user ID
    token = '';
    isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('userId'); // Remove user ID from preferences
    await prefs.remove('token');
    await prefs.setBool('isLoggedIn', false);
  }
}