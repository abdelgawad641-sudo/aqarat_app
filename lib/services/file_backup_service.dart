import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import 'google_drive_service.dart';

class FileBackupService {

  /// إنشاء وتحديث النسخة الاحتياطية محلياً وعلى Google Drive بصمت تام
  static Future<bool> backupToFile(BuildContext context) async {
    try {
      // 1. حفظ البيانات محلياً أولاً
      await LocalStorageService.saveLocally();

      // 2. الرفع والتحديث التلقائي على Google Drive في الخلفية
      bool driveSuccess = await GoogleDriveService.uploadBackupToDrive();

      String userEmail = await LocalStorageService.getStoredEmail();
      if (userEmail.isEmpty) userEmail = 'مستخدم المنظومة';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driveSuccess
                  ? 'تم النسخ الاحتياطي وتحديث Google Drive بنجاح ($userEmail)!'
                  : 'تم الحفظ محلياً بنجاح (فشل الاتصال بجوجل درايف لعدم توفر الشبكة).',
            ),
            backgroundColor: driveSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي الشامل: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل النسخ الاحتياطي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// استعادة البيانات من أحدث نسخة (محلياً أو من Google Drive)
  static Future<bool> restoreFromFile(BuildContext context) async {
    try {
      // محاولة الاستعادة من Google Drive أولاً، وإذا لم يتوفر يتم الاستعادة محلياً
      bool success = await GoogleDriveService.restoreBackupFromDrive();
      if (!success) {
        success = await LocalStorageService.loadLocally();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'تمت استعادة البيانات بنجاح!'
                  : 'لا توجد نسخة احتياطية محفوظة لاستعادتها.',
            ),
            backgroundColor: success ? Colors.blue : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return success;
    } catch (e) {
      debugPrint('خطأ أثناء الاستعادة الشاملة: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء استعادة البيانات.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}