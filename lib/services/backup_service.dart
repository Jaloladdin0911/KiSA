import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// To'liq zaxira nusxa (JSON) — offline ilovada telefon almashtirilganda yoki
/// yo'qolganda ma'lumotni saqlab qolishning yagona yo'li.
class BackupService {
  BackupService._();

  static String _fileName() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'kisa_zaxira_${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Zaxirani faylga yozib, ulashish oynasini ochadi (Telegram, Drive,
  /// "Fayllarga saqlash"...). Brauzerda fayl yuklab olinadi.
  static Future<void> share(Map<String, dynamic> backup) async {
    final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent(' ').convert(backup)));
    final name = _fileName();

    final XFile xfile;
    if (kIsWeb) {
      xfile = XFile.fromData(bytes, mimeType: 'application/json', name: name);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      xfile = XFile(file.path, mimeType: 'application/json');
    }
    await Share.shareXFiles([xfile], subject: 'KiSA — zaxira nusxa');
  }

  /// Foydalanuvchiga JSON fayl tanlatadi va uni o'qiydi. Bekor qilinsa null.
  /// Fayl JSON obyekt bo'lmasa [FormatException] otiladi.
  static Future<Map<String, dynamic>?> pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = res?.files.single.bytes;
    if (bytes == null) return null;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('Not a JSON object');
    return Map<String, dynamic>.from(decoded);
  }
}
