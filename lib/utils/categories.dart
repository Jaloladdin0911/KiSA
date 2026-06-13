import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kategoriya metama'lumotlari (ikonka + rang) — karta, modal va
/// statistika ekranlari shu yagona manbadan foydalanadi.
class CategoryMeta {
  CategoryMeta._();

  static const Map<String, IconData> _icons = {
    'Oziq-ovqat': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Kommunal': Icons.bolt_rounded,
    "Ko'ngilochar": Icons.movie_rounded,
    'Ijara': Icons.home_rounded,
    'Kiyim': Icons.checkroom_rounded,
    "Sog'liq": Icons.favorite_rounded,
    "Ta'lim": Icons.school_rounded,
    'Boshqa': Icons.category_rounded,
    'Ish haqi': Icons.work_rounded,
    'Bonus': Icons.card_giftcard_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Ijara daromad': Icons.home_work_rounded,
    "Sovg'a": Icons.redeem_rounded,
  };

  static const Map<String, Color> _colors = {
    'Oziq-ovqat': AppColors.brand,
    'Transport': AppColors.info,
    'Kommunal': AppColors.warning,
    "Ko'ngilochar": Color(0xFFE64980),
    'Ijara': AppColors.violet,
    'Kiyim': Color(0xFF15AABF),
    "Sog'liq": AppColors.expense,
    "Ta'lim": Color(0xFF20C997),
    'Boshqa': Color(0xFF868E96),
    'Ish haqi': Color(0xFF37B24D),
    'Bonus': Color(0xFFF76707),
    'Freelance': Color(0xFF1098AD),
    'Ijara daromad': AppColors.violet,
    "Sovg'a": Color(0xFFE64980),
  };

  static IconData icon(String key) => _icons[key] ?? Icons.receipt_long_rounded;
  static Color color(String key) => _colors[key] ?? const Color(0xFF868E96);
}

/// Maqsad ikonlari — endi emoji o'rniga Material ikonlar saqlanadi.
/// Eski (emoji bilan saqlangan) maqsadlar ham to'g'ri ko'rsatiladi.
class GoalIcons {
  GoalIcons._();

  static const Map<String, IconData> _byKey = {
    'target': Icons.track_changes_rounded,
    'home': Icons.home_rounded,
    'car': Icons.directions_car_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'phone': Icons.smartphone_rounded,
    'education': Icons.school_rounded,
    'wedding': Icons.diamond_rounded,
    'vacation': Icons.beach_access_rounded,
    'savings': Icons.savings_rounded,
  };

  // Eski emoji qiymatlarini yangi kalitlarga moslash
  static const Map<String, String> _legacyEmoji = {
    '🎯': 'target',
    '🏠': 'home',
    '🚗': 'car',
    '✈️': 'flight',
    '💻': 'laptop',
    '📱': 'phone',
    '🎓': 'education',
    '💍': 'wedding',
    '🏖️': 'vacation',
    '💰': 'savings',
  };

  static List<String> get keys => _byKey.keys.toList();

  static IconData data(String stored) {
    if (_byKey.containsKey(stored)) return _byKey[stored]!;
    final mapped = _legacyEmoji[stored];
    if (mapped != null) return _byKey[mapped]!;
    return Icons.track_changes_rounded;
  }
}
