import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../l10n/app_strings.dart';

/// Tranzaksiyalarni CSV faylga eksport qilib, ulashish oynasini ochadi.
/// Offline ilova uchun zaxira/eksport imkoniyati.
class ExportService {
  static const _typeLabels = {
    'income': 'Kirim',
    'expense': 'Chiqim',
    'transfer': "O'tkazma",
    'exchange': 'Ayirboshlash',
  };

  static String _csvField(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static Future<void> exportTransactions(
      List<TransactionModel> txs, AppStrings s) async {
    final buf = StringBuffer();
    buf.writeln('Sana,Tur,Kategoriya,Hisob,Valyuta,Summa,Izoh');

    final sorted = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    for (final t in sorted) {
      final date =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      final type = _typeLabels[t.type] ?? t.type;
      final cat = t.isMovement ? '' : s.cat(t.category);
      final place = t.place == 'card' ? 'Karta' : 'Naqd';
      final row = [
        date,
        type,
        _csvField(cat),
        place,
        t.currency,
        t.amount.toStringAsFixed(2),
        _csvField(t.note),
      ].join(',');
      buf.writeln(row);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kisa_tranzaksiyalar.csv');
    await file.writeAsString(buf.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'KiSA — tranzaksiyalar',
    );
  }
}
