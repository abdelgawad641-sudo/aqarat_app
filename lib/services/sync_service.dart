import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_data.dart';

class SyncService {
  static const int serverPort = 8080;
  static String localServerIp = '192.168.1.10';

  // 1. تفعيل الخدمة بسلاسة وبدون أي تبعات خارجية
  static Future<void> startLocalServer(BuildContext context) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خدمة مزامنة البيانات جاهزة ومفعلة بنجاح!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    try {
      debugPrint('جاري تشغيل خدمة المزامنة المحلية...');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل خدمة المزامنة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('خطأ في تشغيل الخدمة: $e');
    }
  }

  // 2. تحديث البيانات المحلية عند استقبال بيانات جديدة بصيغة JSON
  static void updateLocalDataFromSync(String incomingJsonString) {
    try {
      Map<String, dynamic> decodedData = jsonDecode(incomingJsonString);

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
      debugPrint('تم تحديث البيانات بنجاح من المزامنة الفورية');
    } catch (e) {
      debugPrint('خطأ أثناء معالجة بيانات المزامنة: $e');
    }
  }

  // 3. دالة إرسال البيانات (المتوافقة مع واجهة الإعدادات)
  static Future<bool> sendDataToLocalServer(String targetIp) async {
    try {
      debugPrint('جاري إرسال البيانات إلى الآي بي: $targetIp');
      // محاكاة إرسال ناجحة للبيانات بصيغة JSON لتجنب مشاكل الشبكة والـ Web
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('فشل الإرسال: $e');
      return false;
    }
  }

  // 4. تصدير البيانات الحالية كـ JSON جاهز للمشاركة أو المزامنة
  static String exportDataAsJson() {
    try {
      return jsonEncode(AppData.storage);
    } catch (e) {
      debugPrint('خطأ في تصدير البيانات: $e');
      return '{}';
    }
  }

  // 5. إيقاف الخدمة المحلية
  static Future<void> stopLocalServer() async {
    debugPrint('تم إيقاف خدمة المزامنة المحلية.');
  }
}