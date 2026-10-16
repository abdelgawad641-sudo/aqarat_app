import 'package:flutter/material.dart';

class SecurityManager {
  // إيميل الدعم الفني الرئيسي الخاص بك كمبرمج (الماستر)
  static const String programmerSupportEmail = 'captain.support640@gmail.com';

  // متغيرات حفظ المستخدم والدور الحالي وإيميل الشركة المربوط
  static String currentUserRole = 'مدير';
  static String currentUsername = '';
  static String currentCompanyEmail = ''; // إيميل الشركة الرئيسي المعرف الموحد للشركة

  // فحص هل المستخدم الحالي هو المبرمج (الماستر كي) أو مالك إيميل الدعم
  static bool get isProgrammer =>
      currentUsername.toLowerCase() == 'admin' ||
          currentUsername.toLowerCase() == 'programmer' ||
          currentCompanyEmail.toLowerCase() == programmerSupportEmail ||
          currentUserRole == 'مبرمج';

  // فحص هل المستخدم الحالي ضيف؟
  static bool get isGuest => currentUserRole == 'ضيف' && !isProgrammer;

  // إرجاع معرّف الشركة السحابي النظيف للربط بالسيرفر (استبدال الرموز الخاصة)
  static String get tenantCompanyId {
    if (isProgrammer) {
      return 'master_programmer_server'; // سيرفر الدعم الفني الرئيسي الخاص بك
    }
    if (currentCompanyEmail.isEmpty) {
      return 'default_company';
    }
    // تحويل الإيميل لمسار آمن في قاعدة البيانات
    return currentCompanyEmail
        .toLowerCase()
        .replaceAll('.', '_')
        .replaceAll('@', '_')
        .replaceAll('#', '')
        .replaceAll('\$', '')
        .replaceAll('[', '')
        .replaceAll(']', '');
  }

  // فحص صلاحية الوصول إلى الشاشات والجداول
  static bool canAccessScreen(String screenTitle) {
    if (isProgrammer || currentUserRole == 'مدير') {
      return true;
    }

    if (isGuest) {
      return false;
    }

    if (currentUserRole == 'نائب مدير') {
      List<String> allowedForViceManager = [
        'بيانات العملاء',
        'العملاء',
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'المعروض للإيجار',
        'الإيجار',
        'المعاينات',
        'المعاينة',
        'العمليات المكتملة',
        'العمليات',
      ];
      return allowedForViceManager.contains(screenTitle);
    }

    if (currentUserRole == 'مدخل بيانات') {
      List<String> allowedForDataEntry = [
        'بيانات العملاء',
        'العملاء',
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'المعروض للإيجار',
        'الإيجار',
        'المعاينات',
        'المعاينة',
      ];
      return allowedForDataEntry.contains(screenTitle);
    }

    return false;
  }

  static bool checkActionPermission(BuildContext context, {required String actionName}) {
    if (isProgrammer) return true;
    if (isGuest) {
      showPermissionDeniedSnackBar(context, 'حساب ضيف: مسموح بالتصفح والمشاهدة فقط ولا يمكنك $actionName.');
      return false;
    }
    return true;
  }

  static void showPermissionDeniedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// أداة الحماية العازلة للضيف
class GuestReadOnlyWrapper extends StatelessWidget {
  final Widget child;
  final bool enableMessageOnTap;

  const GuestReadOnlyWrapper({
    super.key,
    required this.child,
    this.enableMessageOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!SecurityManager.isGuest) {
      return child;
    }

    return GestureDetector(
      onTap: enableMessageOnTap
          ? () {
        SecurityManager.showPermissionDeniedSnackBar(
          context,
          'حساب ضيف: الوضع للعرض والمشاهدة فقط (Read-Only)',
        );
      }
          : null,
      child: AbsorbPointer(
        absorbing: true,
        child: Opacity(
          opacity: 0.85,
          child: child,
        ),
      ),
    );
  }
}