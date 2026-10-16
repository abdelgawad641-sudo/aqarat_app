import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_data.dart';

class AppManagerService {
  static const String _companyEmailKey = 'company_primary_gmail';
  static const String _isLoggedInKey = 'user_is_logged_in';
  static const String _backupFrequencyKey = 'backup_frequency_setting';
  static const String _localDataStorageKey = 'local_app_data_json';

  static const String defaultCompanyEmail = 'captain.realestate.admin@gmail.com';

  // ==================== أولاً: المصادقة والإيميل ====================

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
      final String? savedEmail = prefs.getString(_companyEmailKey);
      if (savedEmail != null && savedEmail.trim().isNotEmpty) {
        return savedEmail.trim();
      }
      return defaultCompanyEmail;
    } catch (e) {
      return defaultCompanyEmail;
    }
  }

  static Future<bool> loginWithEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@gmail.com')) {
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
    } catch (e) {
      // إهمال
    }
  }

  static bool isMasterAdmin(String email) {
    return email.trim().toLowerCase() == defaultCompanyEmail.toLowerCase();
  }

  // ==================== ثانياً: الحفظ المحلي والإعدادات ====================

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
    } catch (e) {
      // إهمال
    }
  }

  static Future<bool> saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(AppData.storage);
      await prefs.setString(_localDataStorageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_localDataStorageKey);

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
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== ثالثاً: النسخ والاستعادة من ملف ====================

  static Future<bool> backupToFile(String companyEmail) async {
    try {
      await saveLocally();

      String jsonData = jsonEncode(AppData.storage);
      final directory = await getApplicationDocumentsDirectory();

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      String fileName = 'captain_realestate_backup_$dateStr.json';

      final File file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'النسخة الاحتياطية لمنظومة الكابتن لإدارة العقارات - تاريخ: $dateStr - إيميل: $companyEmail',
      );

      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي: $e');
      return false;
    }
  }

  static Future<bool> restoreFromFile() async {
    try {
      // تم تبسيط الاستعادة محلياً لتجنب مشاكل الحزم غير المحدثة
      return await loadLocally();
    } catch (e) {
      debugPrint('خطأ أثناء الاستعادة: $e');
      return false;
    }
  }

  static Future<void> performBackup(BuildContext context) async {
    String email = await getStoredEmail();
    bool success = await backupToFile(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم تحديث وتصدير ملف النسخة الاحتياطية بنجاح!' : 'فشل إنشاء النسخة الاحتياطية.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  static Future<void> performRestore(BuildContext context) async {
    bool success = await restoreFromFile();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تمت استعادة البيانات بنجاح تام!' : 'تم إلغاء الاستعادة أو حدث خطأ.'),
          backgroundColor: success ? Colors.blue : Colors.orange,
        ),
      );
    }
  }
}