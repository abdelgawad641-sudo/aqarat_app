import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../app_data.dart';
import 'local_storage_service.dart';

class GoogleDriveAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleDriveAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService {
  // متغير لحفظ واستهداف إيميل Google Drive المخصص من الإعدادات
  static String userDriveEmail = '';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static const String _fileName = 'aqarat_auto_backup.json';

  /// تسجيل الدخول واختيار حساب Google (مثل تجربة الواتساب تماماً)
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // تجربة تسجيل الدخول واختيار الحساب
      final account = await _googleSignIn.signIn();
      if (account != null) {
        userDriveEmail = account.email;
        debugPrint('تم تسجيل الدخول بحساب Google Drive: ${account.email}');
      }
      return account;
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول لجوجل درايف: $e');
      return null;
    }
  }

  /// رفع أو تحديث النسخة الاحتياطية على Google Drive (تحديث نفس الملف)
  static Future<bool> uploadBackupToDrive() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;

      // إذا لم يكن المسجل مفعل أو تحتاجه يختار الحساب زي الواتساب
      account ??= await signIn();

      if (account == null) {
        debugPrint('لم يتم اختيار أو تسجيل الدخول بحساب Google');
        return false;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleDriveAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // 1. حفظ أحدث نسخة بيانات محلياً أولاً
      await LocalStorageService.saveLocally();

      // 2. تحويل البيانات إلى JSON وبايتات
      String jsonData = jsonEncode(AppData.storage);
      var bytes = utf8.encode(jsonData);

      // 3. البحث عن ملف النسخة الاحتياطية الموحد لمنع التكرار
      final query = "name = '$_fileName' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // تحديث الملف الموجود حالياً
        final existingFileId = fileList.files!.first.id!;

        var media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );

        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('تم تحديث النسخة الاحتياطية على Google Drive بنجاح للحساب: ${account.email}');
      } else {
        // إنشاء ملف النسخة الاحتياطية لأول مرة
        var driveFile = drive.File();
        driveFile.name = _fileName;
        driveFile.description = 'Aqarat App Automatic Backup File';

        var media = drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/json',
        );

        await driveApi.files.create(driveFile, uploadMedia: media);
        debugPrint('تم إنشاء ورفع النسخة الاحتياطية الأولى على Google Drive للحساب: ${account.email}');
      }

      return true;
    } catch (e) {
      debugPrint('خطأ أثناء رفع النسخة الاحتياطية لـ Google Drive: $e');
      return false;
    }
  }

  /// استعادة أحدث نسخة احتياطية من Google Drive
  static Future<bool> restoreBackupFromDrive() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await signIn();

      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleDriveAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final query = "name = '$_fileName' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('لا يوجد ملف نسخة احتياطية باسم $_fileName على Google Drive لهذا الحساب');
        return false;
      }

      final fileId = fileList.files!.first.id!;

      drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      List<int> dataBytes = [];
      await for (var chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      String jsonString = utf8.decode(dataBytes);
      Map<String, dynamic> decodedData = jsonDecode(jsonString);

      // استعادة البيانات وضبط الهيكل الداخلي
      AppData.storage.clear();
      decodedData.forEach((key, value) {
        if (value is List) {
          List<Map<String, String>> cleanList = [];
          for (var item in value) {
            if (item is Map) {
              Map<String, String> cleanMap = {};
              item.forEach((k2, v2) {
                cleanMap[k2.toString()] = v2.toString();
              });
              cleanList.add(cleanMap);
            }
          }
          AppData.storage[key.toString()] = cleanList;
        }
      });

      await LocalStorageService.saveLocally();

      debugPrint('تمت استعادة البيانات بنجاح من Google Drive للحساب: ${account.email}');
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء الاستعادة من Google Drive: $e');
      return false;
    }
  }
}