import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/app_manager_service.dart';
import '../services/security_manager.dart'; // استيراد ملف الأمان لضبط الدور
import '../services/licensing_service.dart'; // استيراد ملف الترخيص لتفعيل الأدمن

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false; // تفعيل مربع الحفظ

  final FocusNode _gmailFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _companyEmailController = TextEditingController(); // إيميل الشركة الموحد الجديد
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _newFirstNameController = TextEditingController();
  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();

  String selectedSecurityQuestion = 'ما هي مدينة ميلادك؟';
  String selectedRole = 'مدخل بيانات';

  final List<String> securityQuestions = [
    'ما هي مدينة ميلادك؟',
    'ما هو اسمك الأفضل في الطفولة؟',
    'ما هو اسم حيوانك الأليف الأول؟'
  ];

  final List<String> rolesList = ['مدير', 'نائب مدير', 'مدخل بيانات'];

  static final Map<String, Map<String, String>> _appUsers = {
    'admin': {
      'company': 'شركة ماهي البهوتي للاستثمار العقاري',
      'firstName': 'الكابتن عبد الجواد',
      'password': '1983',
      'role': 'مدير',
      'license': 'مدى الحياة',
      'question': 'ما هي مدينة ميلادك؟',
      'answer': 'القاهرة',
    },
    'programmer': {
      'company': 'الدعم الفني للمبرمج',
      'firstName': 'المبرمج الرئيسي',
      'password': '1983',
      'role': 'مدير',
      'license': 'مدى الحياة',
      'question': 'ما هي مدينة ميلادك؟',
      'answer': 'القاهرة',
    }
  };

  static String mainCompanyName = 'شركة ماهي البهوتي للتسويق العقاري';
  static String subAppName = 'منظومة الكابتن للتسويق العقاري';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    await AppManagerService.loadLocally();
    String storedEmail = await AppManagerService.getStoredEmail();

    // استرجاع بيانات الحفظ لو كانت مفعلة مسبقاً
    final prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? false;
    String savedUser = prefs.getString('saved_username') ?? '';
    String savedPass = prefs.getString('saved_password') ?? '';

    setState(() {
      _gmailController.text = storedEmail;
      _rememberMe = remember;
      if (remember) {
        _usernameController.text = savedUser;
        _passwordController.text = savedPass;
      }
    });
  }

  void _login() async {
    String gmail = _gmailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المستخدم وكلمة السر!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // التحقق الفعلي من حساب الأدمن عبر خدمة LicensingService وتخطي العداد وتفعيل النسخة البرو
    if (LicensingService.checkMasterAdmin(username, password)) {
      _executeSuccessfulLogin(username, 'admin@gmail.com');
      return;
    }

    if (gmail.isEmpty || !gmail.contains('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال جيميل الشركة الرئيسي بشكل صحيح!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_appUsers.containsKey(username) && _appUsers[username]!['password'] == password) {
      await AppManagerService.loginWithEmail(gmail);
      _executeSuccessfulLogin(username, gmail);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المستخدم أو كلمة السر غير صحيحة!'), backgroundColor: Colors.red),
      );
    }
  }

  // دخول الضيف
  void _loginAsGuest() {
    SecurityManager.currentUserRole = 'ضيف'; // تحديد دور الضيف ليعمل Read-Only
    _executeSuccessfulLogin('guest', 'guest@system.com', isGuest: true);
  }

  void _executeSuccessfulLogin(String username, String gmail, {bool isGuest = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // حفظ أو مسح بيانات الدخول حسب حالة زر الحفظ
    if (_rememberMe && !isGuest) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
    }

    // ربط اسم المستخدم الحالي بملف SecurityManager للتحقق من الماستر كي
    SecurityManager.currentUsername = username;

    String role = isGuest ? 'ضيف' : (_appUsers[username]!['role'] ?? 'مدخل بيانات');
    if (!isGuest) {
      SecurityManager.currentUserRole = role; // تعيين الدور الفعلي للمستخدم
    }

    String fName = isGuest ? 'زائر (تصفح فقط)' : (_appUsers[username]!['firstName'] ?? '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مرحباً بك يا $fName ($role) - تم التفعيل بنجاح'), backgroundColor: isGuest ? Colors.blue : Colors.green),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showRegisterDialog() {
    _companyEmailController.clear();
    _companyNameController.clear();
    _newFirstNameController.clear();
    _newUsernameController.clear();
    _newPasswordController.clear();
    _securityAnswerController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Text('تسجيل مستخدم وتنشيط المنظومة (للإدارة فقط)', style: TextStyle(color: Colors.amberAccent, fontSize: 15)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _companyEmailController,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'إيميل الشركة المشترك (الموحد)', labelStyle: TextStyle(color: Colors.cyanAccent)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _companyNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'اسم الشركة أو المكتب العقاري', labelStyle: TextStyle(color: Colors.amberAccent)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newFirstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'الاسم الأول للمستخدم', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newUsernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'اسم المستخدم للدخول', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'الصلاحية (مدير / نائب مدير / مدخل بيانات)', labelStyle: TextStyle(color: Colors.amberAccent)),
                        items: rolesList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedSecurityQuestion,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'سؤال الأمان للاستعادة', labelStyle: TextStyle(color: Colors.grey)),
                        items: securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSecurityQuestion = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _securityAnswerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'إجابة سؤال الأمان', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: () async {
                      String compEmail = _companyEmailController.text.trim();
                      String comp = _companyNameController.text.trim();
                      String fName = _newFirstNameController.text.trim();
                      String uName = _newUsernameController.text.trim();
                      String pass = _newPasswordController.text.trim();
                      String ans = _securityAnswerController.text.trim();

                      if (compEmail.isEmpty || comp.isEmpty || uName.isEmpty || pass.isEmpty || fName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إكمال إيميل الشركة وجميع البيانات المطلوبة!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      // حفظ وتعيين إيميل الشركة المشترك محلياً
                      await AppManagerService.loginWithEmail(compEmail);

                      mainCompanyName = comp;
                      _appUsers[uName] = {
                        'company': comp,
                        'firstName': fName,
                        'password': pass,
                        'role': selectedRole,
                        'license': 'فترة تجريبية 30 يوم',
                        'question': selectedSecurityQuestion,
                        'answer': ans,
                      };

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء الحساب وتنشيط الفترة التجريبية (30 يوم) بنجاح!'), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text('حفظ وتسجيل', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController recoverUserCtrl = TextEditingController();
    final TextEditingController recoverAnswerCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text('استعادة كلمة السر', style: TextStyle(color: Colors.amberAccent)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: recoverUserCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'اسم المستخدم', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: recoverAnswerCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'إجابة سؤال الأمان', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'كلمة السر الجديدة', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                onPressed: () {
                  String u = recoverUserCtrl.text.trim();
                  String a = recoverAnswerCtrl.text.trim();
                  String np = newPassCtrl.text.trim();

                  if (_appUsers.containsKey(u) && _appUsers[u]!['answer'] == a) {
                    _appUsers[u]!['password'] = np;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تغيير كلمة السر بنجاح!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اسم المستخدم أو إجابة سؤال الأمان غير صحيحة!'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('تحديث كلمة السر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF141414)),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/logo.jpg',
                          height: 85,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.domain,
                            size: 60,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mainCompanyName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amber, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subAppName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _gmailController,
                        focusNode: _gmailFocus,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_usernameFocus);
                        },
                        decoration: InputDecoration(
                          labelText: 'جيميل الشركة الرئيسي (حساب المدير)',
                          labelStyle: const TextStyle(color: Colors.amberAccent),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.mark_email_read, color: Colors.cyanAccent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_passwordFocus);
                        },
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.person, color: Colors.amber),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'كلمة السر',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.amber,
                            checkColor: Colors.black,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'حفظ اسم المستخدم وكلمة السر',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _login,
                          child: const Text('دخول للسيستم', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.cyanAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _loginAsGuest,
                          child: const Text('دخول كضيف (تصفح فقط)', style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('نسيت كلمة السر؟', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: _showRegisterDialog,
                            child: const Text('تسجيل حساب جديد', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}