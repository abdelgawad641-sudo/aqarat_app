import 'package:shared_preferences/shared_preferences.dart';

class AppStorageManager {
  static String currentUserRole = 'ضيف';
  static String currentUsername = '';
  static String currentEmail = '';

  static Future<void> setCurrentUser({
    required String username,
    required String role,
    required String email,
  }) async {
    currentUsername = username;
    currentUserRole = role;
    currentEmail = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_username', username);
    await prefs.setString('current_role', role);
    await prefs.setString('current_email', email);
  }

  static Future<void> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_username');
      await prefs.remove('current_role');

      currentUsername = '';
      currentUserRole = 'ضيف';
      currentEmail = prefs.getString('current_email') ?? '';
    } catch (_) {}
  }

  static Future<String> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_email') ?? '';
  }

  static Future<void> loginWithEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_gmail', email);
    currentEmail = email;
  }

  static bool isGuestOrReadOnly() {
    return currentUserRole == 'ضيف';
  }

  static Future<void> autoSaveAllData() async {
    try {} catch (_) {}
  }
}