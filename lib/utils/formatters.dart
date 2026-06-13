// Pul va sana formatlash — butun ilova uchun yagona manba.
// Moliyaviy ilovada aniqlik muhim, shuning uchun summalar to'liq
// ko'rsatiladi (masalan "1 250 000 UZS"), faqat grafik kabi tor
// joylarda ixcham ko'rinish ("1.25M") ishlatiladi.

class Money {
  Money._();

  static const Map<String, String> symbols = {
    'UZS': "so'm",
    'USD': '\$',
    'EUR': '€',
    'RUB': '₽',
  };

  static bool _hasDecimals(String code) => code == 'USD' || code == 'EUR';

  /// To'liq summa: "1 250 000 so'm" yoki "-$1 250.50"
  static String format(
    double amount,
    String currency, {
    bool showSign = false,
    bool symbolFirst = false,
  }) {
    final isNeg = amount < 0;
    final abs = amount.abs();
    final digits = _hasDecimals(currency) ? 2 : 0;
    final number = _group(abs, digits);
    final sym = symbols[currency] ?? currency;

    final sign = showSign ? (isNeg ? '−' : '+') : (isNeg ? '−' : '');

    if (currency == 'USD' || currency == 'EUR' || symbolFirst) {
      return '$sign$sym$number';
    }
    return '$sign$number $sym';
  }

  /// Ixcham ko'rinish — grafik o'qlari va tor kartalar uchun.
  static String compact(double amount, String currency) {
    final abs = amount.abs();
    final sign = amount < 0 ? '−' : '';
    final sym = symbols[currency] ?? currency;
    String n;
    if (abs >= 1000000000) {
      n = '${_trim(abs / 1000000000)}B';
    } else if (abs >= 1000000) {
      n = '${_trim(abs / 1000000)}M';
    } else if (abs >= 1000) {
      n = '${_trim(abs / 1000)}K';
    } else {
      n = abs.toStringAsFixed(0);
    }
    if (currency == 'USD' || currency == 'EUR') return '$sign$sym$n';
    return '$sign$n $sym';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Minglik xonalar ajratilgan raqam: 1250000 -> "1 250 000"
  static String _group(double value, int decimals) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ', // nozik bo'shliq
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }
}

/// Sana formatlash.
class DateFmt {
  DateFmt._();

  static String short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
