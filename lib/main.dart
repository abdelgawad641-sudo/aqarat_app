import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام خاصية النسخ للحافظة (Clipboard)
import 'app_data.dart';
import 'services/licensing_service.dart';
import 'services/app_manager_service.dart';
import 'services/security_manager.dart'; // استيراد ملف الحماية للتحقق من دور الضيف
import 'screens/00_login_screen.dart';
import 'screens/01_clients_screen.dart';
import 'screens/02_brokers_screen.dart';
import 'screens/03_customer_requests_screen.dart';
import 'screens/04_for_sale_screen.dart';
import 'screens/05_for_rent_screen.dart';
import 'screens/06_inspections_screen.dart';
import 'screens/07_completed_operations_screen.dart';
import 'screens/08_accounts_screen.dart';
import 'screens/09_general_report_screen.dart';
import 'screens/about_screen.dart'; // استيراد شاشة حول المنظومة والشرح

void main() async {
  // التعديل المُضاف: التأكد من تهيئة ربط الفلاتر قبل تشغيل التطبيق لمنع أي Crash مفاجئ
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RealEstateApp());
}

class RealEstateApp extends StatelessWidget {
  const RealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منظومة الكابتن لإدارة العقارات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 2,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _selectedBackupFrequency = 'يدوياً';
  String _companyEmail = AppManagerService.defaultCompanyEmail;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    try {
      String freq = await AppManagerService.getBackupFrequency();
      String email = await AppManagerService.getStoredEmail();

      // التأكد من أن القيمة ضمن الخيارات المتاحة لمنع حدوث أي خطأ
      List<String> validFrequencies = ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'];
      if (!validFrequencies.contains(freq)) {
        freq = 'يدوياً';
      }

      if (mounted) {
        setState(() {
          _selectedBackupFrequency = freq;
          _companyEmail = email.isNotEmpty ? email : AppManagerService.defaultCompanyEmail;
        });
      }
    } catch (e) {
      // استخدام القيم الافتراضية في حال حدوث أي استثناء
    }
  }

  void _onSearchChanged(String query) {
    String cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    List<Map<String, dynamic>> results = [];

    AppData.storage.forEach((sectionKey, listData) {
      for (var item in listData) {
        bool isMatch = item.entries.any((entry) {
          String val = entry.value.toString().toLowerCase();
          return val.contains(cleanQuery);
        });

        if (isMatch) {
          results.add({
            'section': sectionKey,
            'data': Map<String, dynamic>.from(item),
          });
        }
      }
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  // نافذة إضافة موظف جديد (تظهر للمدير فقط)
  void _showAddEmployeeDialog(BuildContext context) {
    final TextEditingController empNameController = TextEditingController();
    final TextEditingController empUserController = TextEditingController();
    final TextEditingController empPassController = TextEditingController();
    String empRole = 'مدخل بيانات';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text('إضافة موظف جديد للفريق (سحابياً)', style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: empNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'اسم الموظف', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: empUserController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'اسم المستخدم للدخول', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: empPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: empRole,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'صلاحية الموظف', labelStyle: TextStyle(color: Colors.amberAccent)),
                  items: ['نائب مدير', 'مدخل بيانات'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => empRole = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                onPressed: () {
                  String name = empNameController.text.trim();
                  String user = empUserController.text.trim();
                  String pass = empPassController.text.trim();

                  if (name.isEmpty || user.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إكمال بيانات الموظف!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إضافة الموظف ($name) بنجاح وربطه بإيميل الشركة!'), backgroundColor: Colors.green),
                  );
                },
                child: const Text('حفظ وإضافة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    // --- حماية إضافية: قفل إعدادات الضبط والترخيص في وجه الضيف فوراً ---
    if (SecurityManager.isGuest) {
      SecurityManager.showPermissionDeniedSnackBar(context, 'حساب ضيف: غير مسموح لك بالدخول إلى إعدادات المنظومة والضبط.');
      return;
    }

    final TextEditingController activationController = TextEditingController();
    final TextEditingController wifiIpController = TextEditingController(); // خانة إدخال الـ IP اليدوي
    String myDeviceId = "CAPTAIN-PC-2026";
    String hardwareId = LicensingService.getDeviceHardwareId(myDeviceId);
    int remainingDays = LicensingService.getRemainingDays();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF1E1E1E),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.settings, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('إعدادات المنظومة والضبط', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عرض إيميل الشركة الرئيسي المربوط
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'إيميل الشركة (المدير): $_companyEmail',
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),

                    // إعدادات جدولة النسخ الاحتياطي
                    const Text('جدولة النسخ الاحتياطي التلقائي:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].contains(_selectedBackupFrequency)
                          ? _selectedBackupFrequency
                          : 'يدوياً',
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF141414),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].map((freq) {
                        return DropdownMenuItem(value: freq, child: Text(freq));
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          setDialogState(() => _selectedBackupFrequency = val);
                          setState(() => _selectedBackupFrequency = val);
                          await AppManagerService.setBackupFrequency(val);
                        }
                      },
                    ),

                    const SizedBox(height: 14),
                    // أزرار النسخ الاحتياطي والاستعادة الفعلية
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        minimumSize: const Size(double.infinity, 42),
                        alignment: Alignment.centerRight,
                      ),
                      icon: const Icon(Icons.backup, color: Colors.white),
                      label: const Text('نسخ احتياطي للبيانات (محلي + تصدير)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      onPressed: () async {
                        await AppManagerService.performBackup(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        minimumSize: const Size(double.infinity, 42),
                        alignment: Alignment.centerRight,
                      ),
                      icon: const Icon(Icons.restore, color: Colors.white),
                      label: const Text('استعادة البيانات من ملف', style: TextStyle(color: Colors.white, fontSize: 13)),
                      onPressed: () async {
                        await AppManagerService.performRestore(context);
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),

                    // --- إعدادات الشبكة المحلية (الواي فاي) للربط بين الأجهزة مع خانة IP يدوي ---
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wifi, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 8),
                              Text('الربط والشبكة المحلية (WiFi)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'تأكد من اتصال الأجهزة بنفس شبكة الواي فاي لمشاركة ومزامنة البيانات بسلاسة بين الأجهزة.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          // خانة إدخال الـ IP يدوياً
                          TextField(
                            controller: wifiIpController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'عنوان IP الجهاز الرئيسي (مثال: 192.168.1.50)',
                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                              prefixIcon: const Icon(Icons.computer, color: Colors.greenAccent, size: 18),
                              filled: true,
                              fillColor: const Color(0xFF141414),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // زر الاتصال اليدوي بالـ IP
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              minimumSize: const Size(double.infinity, 36),
                              alignment: Alignment.centerRight,
                            ),
                            icon: const Icon(Icons.link, color: Colors.white, size: 18),
                            label: const Text('اتصال يدوي عبر الـ IP', style: TextStyle(color: Colors.white, fontSize: 12)),
                            onPressed: () {
                              String enteredIp = wifiIpController.text.trim();
                              if (enteredIp.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('برجاء كتابة عنوان الـ IP أولاً!'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('جاري الاتصال بالجهاز عبر الـ IP: $enteredIp...'),
                                    backgroundColor: Colors.teal,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          // زر الفحص التلقائي الأصلي
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              minimumSize: const Size(double.infinity, 36),
                              alignment: Alignment.centerRight,
                            ),
                            icon: const Icon(Icons.hub, color: Colors.white, size: 18),
                            label: const Text('فحص تلقائي للأجهزة عبر الشبكة المحلية', style: TextStyle(color: Colors.white, fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('جاري البحث عن الأجهزة المجاورة على نفس شبكة الواي فاي...'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),

                    // قسم إدارة التراخيص مع زر النسخ السريع لكود الجهاز
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('حالة التراخيص والتشغيل:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            LicensingService.isActivated
                                ? 'حالة البرنامج: مُفعل بشكل دائم'
                                : 'الأيام المتبقية في التجربة: $remainingDays يوم',
                            style: TextStyle(color: LicensingService.isActivated ? Colors.greenAccent : Colors.cyanAccent, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('كود الجهاز: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Expanded(
                                child: Text(
                                  hardwareId,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.amber, size: 18),
                                tooltip: 'نسخ كود الجهاز',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: hardwareId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ كود الجهاز بنجاح!'), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: activationController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'أدخل كود التفعيل أو التمديد',
                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFF141414),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                              onPressed: () {
                                bool success = LicensingService.processActivationCode(
                                  inputCode: activationController.text,
                                  deviceId: myDeviceId,
                                );
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم تنشيط وترخيص المنظومة بنجاح!'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('كود التفعيل غير صحيح أو تم استهلاكه مسبقاً!'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                              child: const Text('تنشيط وترخيص البرنامج', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int remainingDays = LicensingService.getRemainingDays();
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'بيانات العملاء',
        'icon': Icons.people,
        'color': Colors.blue.shade700,
        'screen': const ClientsScreen(),
      },
      {
        'title': 'بيانات السماسرة',
        'icon': Icons.badge,
        'color': Colors.teal.shade700,
        'screen': const BrokersScreen(),
      },
      {
        'title': 'طلبات العملاء',
        'icon': Icons.assignment,
        'color': Colors.orange.shade700,
        'screen': const CustomerRequestsScreen(),
      },
      {
        'title': 'المعروض للبيع',
        'icon': Icons.sell,
        'color': Colors.green.shade700,
        'screen': const ForSaleScreen(),
      },
      {
        'title': 'المعروض للإيجار',
        'icon': Icons.house,
        'color': Colors.red.shade700,
        'screen': const ForRentScreen(),
      },
      {
        'title': 'المعاينات',
        'icon': Icons.remove_red_eye,
        'color': Colors.purple.shade700,
        'screen': const InspectionsScreen(),
      },
      {
        'title': 'العمليات المكتملة',
        'icon': Icons.task_alt,
        'color': Colors.indigo.shade700,
        'screen': const CompletedOperationsScreen(),
      },
      {
        'title': 'حسابات المنظومة',
        'icon': Icons.account_balance_wallet,
        'color': Colors.brown.shade700,
        'screen': const AccountsScreen(),
      },
      {
        'title': 'التقرير العام',
        'icon': Icons.bar_chart,
        'color': Colors.blueGrey.shade700,
        'screen': const GeneralReportScreen(),
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الصفحة الرئيسية | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            // --- زر إضافة موظف (يظهر حصرياً للمدير فقط) ---
            if (SecurityManager.currentUserRole == 'مدير')
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Colors.greenAccent, size: 26),
                tooltip: 'إضافة موظف جديد للفريق',
                onPressed: () => _showAddEmployeeDialog(context),
              ),
            // --- زر حول المنظومة وشرح العمل الجديد (متاح للجميع) ---
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 26),
              tooltip: 'حول المنظومة وشرح العمل',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            // --- زر إعدادات المنظومة والضبط (مقفول تماماً في وجه الضيف) ---
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.amber, size: 26),
              tooltip: 'إعدادات المنظومة والضبط',
              onPressed: () => _showSettingsDialog(context),
            ),
            // --- زر الخروج الآمن (متاح للجميع) ---
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 26),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: const Text('تأكيد الخروج', style: TextStyle(color: Colors.amberAccent)),
                      content: const Text('هل تريد تسجيل الخروج والعودة لشاشة الدخول؟ (سيظل اسم المستخدم وكلمة السر محفوظين)', style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: () {
                            Navigator.pop(context, true);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text('خروج', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        // قفل الصفحة الرئيسية بالكامل للضيف مع السماح بالتمرير (السكرول) صعوداً وهبوطاً
        body: GuestReadOnlyWrapper(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- شريط حالة الترخيص العلوي البارز ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: LicensingService.isActivated ? Colors.green.shade900.withOpacity(0.6) : Colors.amber.shade900.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LicensingService.isActivated ? Colors.greenAccent : Colors.amberAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LicensingService.isActivated ? Icons.verified : Icons.timer,
                        color: LicensingService.isActivated ? Colors.greenAccent : Colors.amberAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LicensingService.isActivated
                            ? 'حالة النظام: مُفعل بشكل دائم'
                            : 'النسخة تجريبية (متبقي $remainingDays يوم من الفترة التجريبية 30 يوم)',
                        style: TextStyle(
                          color: LicensingService.isActivated ? Colors.greenAccent : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'مرحباً بك في منظومة الكابتن لإدارة العقارات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      labelText: 'ابحث فورياً بالكود، أو الاسم، أو رقم التليفون...',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.redAccent),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: _isSearching
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'نتائج البحث الفوري (${_searchResults.length})',
                                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  const Divider(color: Colors.grey, height: 1),
                                  Expanded(
                                    child: _searchResults.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'لا توجد نتائج مطابقة لما تكتبه حالياً',
                                              style: TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _searchResults.length,
                                            itemBuilder: (context, index) {
                                              final result = _searchResults[index];
                                              final section = result['section'];
                                              final data = result['data'] as Map<String, dynamic>;

                                              return Card(
                                                color: const Color(0xFF252525),
                                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            'القسم: $section',
                                                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                                          ),
                                                          if (data.containsKey('كود الوحدة'))
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(4)),
                                                              child: Text('الكود: ${data['كود الوحدة']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      ...data.entries.take(4).map((entry) => Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                                            child: Text(
                                                              '${entry.key}: ${entry.value}',
                                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                            ),
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;

                                return GridView.builder(
                                  itemCount: menuItems.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 1.5,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = menuItems[index];
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: item['color'],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 4,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => item['screen']),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(item['icon'], size: 32, color: Colors.white),
                                          const SizedBox(height: 8),
                                          Text(
                                            item['title'],
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}