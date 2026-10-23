import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_data.dart';

class LocalStorageService {
  static const String _isLoggedInKey = 'user_is_logged_in';
  static const String _companyEmailKey = 'company_primary_gmail';
  static const String _personalGmailKey = 'user_personal_gmail';
  static const String _backupFrequencyKey = 'backup_frequency_setting';
  static const String _appUsersMapKey = 'saved_app_users_map';

  static Future<String> _getStorageKey() async {
    String email = await getStoredEmail();
    if (email.isEmpty) email = 'default_user';
    return 'local_app_data_${email.toLowerCase()}';
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) {
        return '';
      }
      return prefs.getString(_companyEmailKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<bool> savePersonalGmail(String personalGmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_personalGmailKey, personalGmail.trim());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getPersonalGmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_personalGmailKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<bool> loginWithEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_companyEmailKey, trimmedEmail);
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_companyEmailKey);
      await prefs.remove(_personalGmailKey);
    } catch (e) {}
  }

  static bool isMasterAdmin(String email) {
    const String masterAdminEmail = 'admin@aqarat.com';
    const String programmerEmail = 'captain.support640@gmail.com';
    String lowerEmail = email.trim().toLowerCase();
    return lowerEmail == masterAdminEmail.toLowerCase() || lowerEmail == programmerEmail.toLowerCase();
  }

  static Future<bool> saveAppUsers(Map<String, Map<String, String>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(users);
      await prefs.setString(_appUsersMapKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, Map<String, String>>> loadAppUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_appUsersMapKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        Map<String, dynamic> decoded = jsonDecode(jsonString);
        Map<String, Map<String, String>> result = {};
        decoded.forEach((key, value) {
          if (value is Map) {
            result[key] = value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
          }
        });
        return result;
      }
    } catch (e) {}
    return {};
  }

  static Future<bool> saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey = await _getStorageKey();
      String jsonString = jsonEncode(AppData.storage);
      await prefs.setString(storageKey, jsonString);
      debugPrint('تم الحفظ المحلي بنجاح تحت المفتاح: $storageKey');
      return true;
    } catch (e) {
      debugPrint('خطأ في الحفظ المحلي: $e');
      return false;
    }
  }

  static Future<bool> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey = await _getStorageKey();
      String? jsonString = prefs.getString(storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        Map<String, dynamic> decodedData = jsonDecode(jsonString);

        AppData.storage.clear();
        decodedData.forEach((key, value) {
          if (value is List) {
            AppData.storage[key] = value.map((item) {
              if (item is Map) {
                return item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
              }
              return <String, String>{};
            }).toList();
          }
        });
        debugPrint('تم استرجاع البيانات محلياً بنجاح من المفتاح: $storageKey');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في الاسترجاع المحلي: $e');
      return false;
    }
  }

  static Future<String> getBackupFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_backupFrequencyKey) ?? 'يدوياً';
    } catch (e) {
      return 'يدوياً';
    }
  }

  static Future<void> setBackupFrequency(String frequency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupFrequencyKey, frequency);
    } catch (e) {}
  }
}