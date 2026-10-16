import 'package:shared_preferences/shared_preferences.dart';

class LicensingService {
  // المعادلة السرية الثابتة: 24 + 9 - 1983 = -1950
  static const int _secretFormula = 24 + 9 - 1983;

  static bool isMasterAdmin = false;
  static DateTime? trialStartDate;
  static bool isActivated = false;
  static String activationType = 'فترة تجريبية (شهر)';

  // تحميل الحالة المحلية للتفعيل مع فحص الأمان ضد التلاعب بالتاريخ
  static Future<void> loadLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isActivated = prefs.getBool('is_activated') ?? false;
    isMasterAdmin = prefs.getBool('is_master_admin') ?? false;
    activationType = prefs.getString('activation_type') ?? 'فترة تجريبية (شهر)';

    String? storedDate = prefs.getString('trial_start_date');
    if (storedDate != null) {
      trialStartDate = DateTime.tryParse(storedDate);
    } else {
      trialStartDate = DateTime.now();
      await prefs.setString('trial_start_date', trialStartDate!.toIso8601String());
    }

    // [حماية إضافية]: رصد التلاعب بالتاريخ (إذا تم إرجاع تاريخ الجهاز قبل تاريخ البداية المسجل)
    if (!isActivated && !isMasterAdmin && trialStartDate != null) {
      if (DateTime.now().isBefore(trialStartDate!)) {
        // تم التلاعب بالتاريخ وإرجاعه للوراء، قفل الفترة فوراً
        trialStartDate = DateTime.now().subtract(const Duration(days: 35));
      }
    }
  }

  // توليد كود رقم الجهاز بناءً على المعادلة ورقم الجهاز
  static String getDeviceHardwareId(String rawDeviceId) {
    String combined = "$rawDeviceId-$_secretFormula";
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = 31 * hash + combined.codeUnitAt(i);
      hash = hash & hash;
    }
    String numericOnly = hash.abs().toString();
    if (numericOnly.length < 10) {
      numericOnly = numericOnly.padRight(10, '5');
    }
    return numericOnly.substring(0, 10);
  }

  // التحقق من الأدمن الرئيسي (admin / 1983)
  static bool checkMasterAdmin(String username, String password) {
    if (username.trim() == "admin" && password.trim() == "1983") {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'أدمن رئيسي (مفتوح)';
      _saveToPrefs();
      return true;
    }
    return false;
  }

  // فحص كود التفعيل وأكواد النظام
  static bool processActivationCode({
    required String inputCode,
    required String deviceId,
  }) {
    String cleanCode = inputCode.trim().toUpperCase();
    String hardwareKey = getDeviceHardwareId(deviceId);

    // حساب ناتج المعادلة السنوية (سيريال الجهاز + 24 + 9 - 1983)
    int parsedKey = int.tryParse(hardwareKey) ?? 12345678;
    String annualCode = (parsedKey + _secretFormula).abs().toString();

    // 1. كود إعادة الضبط (ريست الشهر): A1983 يصفر العداد ويمنح شهراً جديداً
    if (cleanCode == "A1983") {
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      activationType = 'فترة تجريبية (شهر)';
      _saveToPrefs();
      return true;
    }

    // 2. التفعيل مدى الحياة: يبدأ بحرف A متبوعاً بناتج معادلة كود الجهاز
    if (cleanCode == "A$annualCode" || cleanCode == "A-$annualCode" || cleanCode == "A$hardwareKey" || cleanCode == "A-$hardwareKey") {
      isActivated = true;
      activationType = 'تفعيل مدى الحياة';
      _saveToPrefs();
      return true;
    }

    // 3. التفعيل السنوي: ناتج المعادلة الحسابية المرتبطة بسيريال الجهاز
    if (cleanCode == annualCode) {
      isActivated = true;
      activationType = 'تفعيل سنوي';
      _saveToPrefs();
      return true;
    }

    // 4. الفترة التجريبية (شهر): إدخال سيريال الجهاز العادي
    if (cleanCode == hardwareKey) {
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      activationType = 'فترة تجريبية (شهر)';
      _saveToPrefs();
      return true;
    }

    return false;
  }

  // حساب الأيام المتبقية مع التدقيق ضد التلاعب بالوقت
  static int getRemainingDays() {
    if (isMasterAdmin || isActivated) {
      return activationType == 'تفعيل مدى الحياة' ? 9999 : 365;
    }

    DateTime today = DateTime.now();
    trialStartDate ??= today;

    // فحص تلاعب الوقت الفوري
    if (today.isBefore(trialStartDate!)) {
      return 0; // انتهت الفترة فورا نتيجة تغيير وقت الجهاز
    }

    int daysPassed = today.difference(trialStartDate!).inDays;
    int remaining = 30 - daysPassed;

    return remaining > 0 ? remaining : 0;
  }

  // حفظ الحالة محلياً باستخدام SharedPreferences
  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', isActivated);
    await prefs.setBool('is_master_admin', isMasterAdmin);
    await prefs.setString('activation_type', activationType);
    if (trialStartDate != null) {
      await prefs.setString('trial_start_date', trialStartDate!.toIso8601String());
    }
  }
}