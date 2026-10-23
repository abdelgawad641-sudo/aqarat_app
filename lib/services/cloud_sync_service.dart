import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../app_data.dart';
import 'local_storage_service.dart';

class CloudSyncService {

  // تهيئة قواعد البيانات لدعم العمل أوفلاين والمزامنة اللحظية
  static void initOfflineSupport() {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (e) {
      debugPrint('تنبيه: قواعد بيانات أوفلاين مفعلة مسبقاً.');
    }
  }

  // رفع وحفظ البيانات على السحابة المركزية (Firebase Realtime Database)
  static Future<bool> syncToCloud({bool isAuto = false}) async {
    try {
      String companyEmail = await LocalStorageService.getStoredEmail();
      if (companyEmail.isEmpty || !companyEmail.contains('@')) {
        if (!isAuto) debugPrint('فشل المزامنة السحابية: لا يوجد إيميل شركة صالح مسجل.');
        return false;
      }

      // تنظيف الإيميل ليكون مساراً صحيحاً في Firebase
      String safeEmailKey = companyEmail.replaceAll('.', '_').replaceAll('@', '_at_');

      // تحويل كافة بيانات AppData إلى صيغة JSON
      String jsonData = jsonEncode(AppData.storage);

      // الاتصال الفعلي بقاعدة بيانات Firebase
      DatabaseReference ref = FirebaseDatabase.instance.ref("companies_storage/$safeEmailKey");
      
      // إبقاء المسار متزامن في الخلفية أوفلاين وأونلاين
      ref.keepSynced(true);

      await ref.set({
        'data': jsonData,
        'last_updated': DateTime.now().toIso8601String(),
        'email': companyEmail,
      });

      if (!isAuto) {
        debugPrint('تم رفع البيانات أونلاين بنجاح إلى Firebase.');
      }
      return true;
    } catch (e) {
      if (!isAuto) debugPrint('خطأ أثناء المزامنة مع السحابة: $e');
      return false;
    }
  }

  // استعادة وسحب أحدث نسخة سحابية حقيقية من Firebase
  static Future<bool> syncFromCloud({bool isAuto = false}) async {
    try {
      String companyEmail = await LocalStorageService.getStoredEmail();
      if (companyEmail.isEmpty || !companyEmail.contains('@')) {
        return false;
      }

      String safeEmailKey = companyEmail.replaceAll('.', '_').replaceAll('@', '_at_');

      // جلب البيانات من Firebase فعلياً
      DatabaseReference ref = FirebaseDatabase.instance.ref("companies_storage/$safeEmailKey");
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> rawData = Map<String, dynamic>.from(snapshot.value as Map);
        if (rawData.containsKey('data')) {
          String jsonData = rawData['data'];
          Map<String, dynamic> decodedData = jsonDecode(jsonData);

          // تحديث AppData.storage مع تحويل النوع بدقة لتفادي خطأ السطر 78
          decodedData.forEach((key, value) {
            if (value is List) {
              AppData.storage[key] = List<Map<String, String>>.from(
                value.map((item) => Map<String, String>.from(
                  (item as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
                ))
              );
            }
          });

          // حفظها محلياً على الجهاز فوراً
          await LocalStorageService.saveLocally();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في استعادة النسخة السحابية: $e');
      return false;
    }
  }

  // دالة تنفيذ المزامنة مع تنبيهات الواجهة
  static Future<void> performCloudSync(BuildContext context, {bool isAuto = false}) async {
    bool success = await syncToCloud(isAuto: isAuto);

    if (!isAuto && context.mounted) {
      String frequency = await LocalStorageService.getBackupFrequency();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'تم مزامنة ورفع البيانات أونلاين بنجاح إلى السحابة!\n(نظام التحديث: $frequency)'
              : 'فشل الاتصال بالسحابة المركزية، تأكد من الاتصال بالإنترنت.'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // دالة الحفظ اللحظي المزدوج (محلي + سحابي في الخلفية)
  static Future<void> saveAndSyncInstant() async {
    await LocalStorageService.saveLocally();
    syncToCloud(isAuto: true);
  }
}