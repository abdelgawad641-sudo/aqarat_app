import 'package:shared_preferences/shared_preferences.dart';
import 'security_manager.dart';

class LicensingService {
  static const int _baseFormulaValue = 24 + 9 - 1983;

  static bool isMasterAdmin = false;
  static DateTime? trialStartDate;
  static bool isActivated = false;
  static String activationType = 'فترة تجريبية (7 أيام)';

  static Future<void> loadLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // التحقق الفوري من اسم المستخدم الحالي لمنع تسريب مدى الحياة للموظفين
    String currentUsername = SecurityManager.currentUsername.trim().toLowerCase();
    bool isRootAdmin = (currentUsername == 'admin' || currentUsername == 'programmer');

    if (isRootAdmin) {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'مدى الحياة';
      return;
    }

    // للموظفين العاديين: لا يتم منح مدى الحياة العام أبداً، بل قراءة حالتهم المستقلة
    isMasterAdmin = false;
    isActivated = prefs.getBool('user_${currentUsername}_is_activated') ?? false;
    activationType = prefs.getString('user_${currentUsername}_activation_type') ?? 'فترة تجريبية (7 أيام)';

    if (activationType == 'مدى الحياة') {
      isActivated = true;
    } else {
      String? storedDate = prefs.getString('user_${currentUsername}_trial_start_date');
      if (storedDate != null) {
        trialStartDate = DateTime.tryParse(storedDate);
      } else {
        trialStartDate = DateTime.now();
        await prefs.setString('user_${currentUsername}_trial_start_date', trialStartDate!.toIso8601String());
      }
    }
  }

  static String getDeviceHardwareId(String rawDeviceId) {
    String combined = "$rawDeviceId-$_baseFormulaValue";
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

  // الاستثناء الحصري للأدمن والمبرمج فقط بكلمة السر 1983
  static bool checkMasterAdmin(String username, String password) {
    String cleanUser = username.trim().toLowerCase();
    if ((cleanUser == "admin" || cleanUser == "programmer") && password.trim() == "1983") {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'مدى الحياة';
      return true;
    }
    return false;
  }

  static bool processActivationCode({
    required String inputCode,
    required String deviceId,
  }) {
    String cleanCode = inputCode.trim().toUpperCase();
    String hardwareKey = getDeviceHardwareId(deviceId);
    int deviceNum = int.tryParse(hardwareKey) ?? 12345678;

    int calculatedAnnual = 24 + 9 - 1983 + deviceNum;
    String annualCode = calculatedAnnual.abs().toString();
    String lifetimeCode = "A$annualCode";
    String lifetimeCodeAlt = "A-$annualCode";

    String currentUsername = SecurityManager.currentUsername.trim().toLowerCase();
    if (currentUsername.isEmpty) currentUsername = 'default';

    if (cleanCode == "1983" || cleanCode == "A1983") {
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      activationType = 'فترة تجريبية (7 أيام)';
      _saveUserPrefs(currentUsername);
      return true;
    }

    if (cleanCode == lifetimeCode || cleanCode == lifetimeCodeAlt || cleanCode == "A$hardwareKey" || cleanCode == "A-$hardwareKey") {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'مدى الحياة';
      _saveUserPrefs(currentUsername);
      return true;
    }

    if (cleanCode == annualCode) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'سنة';
      _saveUserPrefs(currentUsername);
      return true;
    }

    if (cleanCode == hardwareKey) {
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      activationType = 'شهر';
      _saveUserPrefs(currentUsername);
      return true;
    }

    return false;
  }

  static int getRemainingDays() {
    if (isMasterAdmin || isActivated || activationType == 'مدى الحياة') {
      return 9999;
    }

    DateTime today = DateTime.now();
    trialStartDate ??= today;

    if (today.isBefore(trialStartDate!)) {
      return (activationType == 'شهر') ? 30 : 7;
    }

    int daysPassed = today.difference(trialStartDate!).inDays;
    int limitDays = (activationType == 'شهر') ? 30 : 7;
    int remaining = limitDays - daysPassed;

    return remaining > 0 ? remaining : 0;
  }

  static Future<void> _saveUserPrefs(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_${username}_is_activated', isActivated);
    await prefs.setString('user_${username}_activation_type', activationType);
    if (trialStartDate != null) {
      await prefs.setString('user_${username}_trial_start_date', trialStartDate!.toIso8601String());
    }
  }
}