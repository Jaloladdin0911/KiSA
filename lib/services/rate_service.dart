import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// O'zbekiston Markaziy banki (cbu.uz) ochiq API'sidan USD kursini oladi.
/// Internet bo'lsa yangilaydi va keshlaydi; bo'lmasa oxirgi kesh ishlatiladi.
class RateService {
  static const _url = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/USD/';

  Future<double?> fetchUsdRate() async {
    try {
      final res = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        final rate = double.tryParse(data[0]['Rate']?.toString() ?? '');
        if (rate != null && rate > 0) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('usd_rate', rate);
          await prefs.setString(
              'usd_rate_date', DateTime.now().toIso8601String());
          return rate;
        }
      }
    } catch (_) {
      // Offline yoki API xatosi — kesh ishlatiladi
    }
    return null;
  }
}
