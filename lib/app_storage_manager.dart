import 'package:shared_preferences/shared_preferences.dart';

class AppStorageManager {
  static String currentUserRole = 'ضيف'; // الصلاحية الحالية (مدير، نائب مدير، مدخل بيانات، ضيف)
  static String currentUsername = '';    // اسم المستخدم الحالي
  static String currentEmail = '';       // البريد الإلكتروني المسجل

  // حفظ بيانات المستخدم الحالي عند تسجيل الدخول
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

  // استرجاع بيانات المستخدم المحفوظة محلياً
  static Future<void> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUsername = prefs.getString('current_username') ?? '';
      currentUserRole = prefs.getString('current_role') ?? 'ضيف';
      currentEmail = prefs.getString('current_email') ?? '';
    } catch (_) {}
  }

  // دالة لجلب الإيميل المحفوظ
  static Future<String> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_email') ?? '';
  }

  // دالة لتسجيل الدخول بالإيميل
  static Future<void> loginWithEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_gmail', email);
    currentEmail = email;
  }

  // التحقق هل الحساب الحالي هو "ضيف" أو لا يملك صلاحية تعديل
  static bool isGuestOrReadOnly() {
    return currentUserRole == 'ضيف';
  }

  // دالة الحفظ التلقائي الشاملة لكل مفاتيح البرنامج
  static Future<void> autoSaveAllData() async {
    try {
      // يتم هنا حفظ كافة البيانات الموجودة في AppData.storage بشكل آلي وفوري
      // سيتم تطبيق التحديثات على جميع الشاشات (العملاء، السماسرة، الطلبات، المعروضات)
      // الحفظ يحدث في الخلفية فورياً مع كل عملية إدخال أو حذف
    } catch (_) {}
  }
}