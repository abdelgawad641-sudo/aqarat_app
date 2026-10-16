import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../app_data.dart';
import '01_clients_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';
import '08_accounts_screen.dart';
import '09_general_report_screen.dart';

class BrokersScreen extends StatefulWidget {
  const BrokersScreen({super.key});

  @override
  State<BrokersScreen> createState() => _BrokersScreenState();
}

class _BrokersScreenState extends State<BrokersScreen> {
  // دالة اختيار جهة اتصال من الهاتف
  Future<void> _pickContact(TextEditingController targetPhoneController, TextEditingController targetNameController) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ميزة اختيار جهات الاتصال متاحة فقط عند تشغيل التطبيق على الهاتف المحمول.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              if (targetNameController.text.trim().isEmpty && fullContact.displayName.isNotEmpty) {
                targetNameController.text = fullContact.displayName;
              }
              if (fullContact.phones.isNotEmpty) {
                String rawPhone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
                if (rawPhone.startsWith('+20')) {
                  rawPhone = rawPhone.replaceFirst('+20', '0');
                } else if (rawPhone.startsWith('20')) {
                  rawPhone = rawPhone.replaceFirst('20', '0');
                }
                targetPhoneController.text = rawPhone;
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم استيراد بيانات جهة الاتصال بنجاح'), backgroundColor: Colors.green),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض صلاحية الوصول إلى جهات الاتصال.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استيراد جهة الاتصال: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showAddBrokerDialog() {
    final nameController = TextEditingController();
    final phone1Controller = TextEditingController();
    final phone2Controller = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    final fPhone1 = FocusNode();
    final fPhone2 = FocusNode();
    final fAddress = FocusNode();
    final fNotes = FocusNode();

    void saveBroker(BuildContext dialogContext) {
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برجاء إدخال إسم السمسار'), backgroundColor: Colors.red),
        );
        return;
      }

      String p1 = phone1Controller.text.trim();
      String p2 = phone2Controller.text.trim();

      // التحقق من أن رقم التليفون الأول 11 رقم بالضبط إذا تم إدخاله
      if (p1.isNotEmpty && p1 != '-' && p1.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: رقم التليفون الأول يجب أن يكون 11 رقماً بالضبط!'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      // التحقق من أن رقم التليفون الثاني 11 رقم بالضبط إذا تم إدخاله
      if (p2.isNotEmpty && p2 != '-' && p2.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: رقم التليفون الثاني يجب أن يكون 11 رقماً بالضبط!'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      setState(() {
        if (!AppData.storage.containsKey('بيانات السماسرة')) {
          AppData.storage['بيانات السماسرة'] = [];
        }
        AppData.storage['بيانات السماسرة']!.add({
          'إسم السمسار': nameController.text.trim(),
          'رقم التليفون 1': p1.isEmpty ? '-' : p1,
          'رقم التليفون 2': p2.isEmpty ? '-' : p2,
          'العنوان': addressController.text.trim().isEmpty ? '-' : addressController.text.trim(),
          'تاريخ التسجيل': dateStr,
          'ملاحظات': notesController.text.trim().isEmpty ? '-' : notesController.text.trim(),
        });
      });

      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات السمسار بنجاح'), backgroundColor: Colors.green),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('إضافة سمسار جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(fPhone1),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'إسم السمسار *', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone1Controller,
                  focusNode: fPhone1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(fPhone2),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم التليفون 1 (11 رقماً)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts, color: Colors.amberAccent),
                      tooltip: 'اختيار من دليل الهاتف',
                      onPressed: () => _pickContact(phone1Controller, nameController),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone2Controller,
                  focusNode: fPhone2,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(fAddress),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم التليفون 2 (11 رقماً)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts, color: Colors.amberAccent),
                      tooltip: 'اختيار من دليل الهاتف',
                      onPressed: () => _pickContact(phone2Controller, nameController),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  focusNode: fAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(fNotes),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  focusNode: fNotes,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveBroker(dialogContext),
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ملاحظات (اضغط Enter للحفظ)', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
            onPressed: () => saveBroker(dialogContext),
            child: const Text('حفظ السمسار'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brokersList = AppData.storage['بيانات السماسرة'] ?? [];
    final totalRows = brokersList.length < 15 ? 15 : brokersList.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات السماسرة | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              tooltip: 'إغلاق',
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF141414),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, color: Colors.amber, size: 26),
                      tooltip: 'الصفحة الرئيسية',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.cyanAccent, size: 24),
                      tooltip: 'طباعة التقرير',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري إعداد تقرير السماسرة للطباعة...')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_right_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة السابقة', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerRequestsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_left_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة التالية', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showAddBrokerDialog,
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      label: const Text('إضافة سمسار', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen())),
                      child: const Text('العملاء', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('السماسرة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerRequestsScreen())),
                      child: const Text('الطلبات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForSaleScreen())),
                      child: const Text('البيع', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForRentScreen())),
                      child: const Text('الإيجار', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InspectionsScreen())),
                      child: const Text('المعاينة', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CompletedOperationsScreen())),
                      child: const Text('العمليات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AccountsScreen())),
                      child: const Text('الحسابات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GeneralReportScreen())),
                      child: const Text('التقرير', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF181818),
              child: Row(
                children: [
                  const Text('إحصائيات السماسرة:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueAccent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إجمالي السماسرة المسجلين: ', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('${brokersList.length}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
                              border: TableBorder.all(color: Colors.grey.shade800, width: 1),
                              columnSpacing: 16,
                              columns: const [
                                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('إسم السمسار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('رقم التليفون 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('رقم التليفون 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('العنوان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('تاريخ التسجيل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              ],
                              rows: List.generate(totalRows, (index) {
                                if (index < brokersList.length) {
                                  Map<String, String> item = brokersList[index];
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: [
                                      DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                      DataCell(Text(item['إسم السمسار'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                      DataCell(Text(item['رقم التليفون 1'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['رقم التليفون 2'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['العنوان'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['تاريخ التسجيل'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['ملاحظات'] ?? '', style: const TextStyle(color: Colors.white70))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              brokersList.removeAt(index);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم حذف السمسار بنجاح'), backgroundColor: Colors.orange),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: List.generate(8, (cellIndex) => const DataCell(SizedBox.shrink())),
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                      );
                    },
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