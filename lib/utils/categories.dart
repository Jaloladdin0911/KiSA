import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kategoriya metama'lumotlari (ikonka + rang) — karta, modal va
/// statistika ekranlari shu yagona manbadan foydalanadi.
class CategoryMeta {
  CategoryMeta._();

  static const Map<String, IconData> _icons = {
    // Xarajat
    'Oziq-ovqat': Icons.restaurant_rounded,
    'Kafe/Restoran': Icons.local_cafe_rounded,
    'Transport': Icons.directions_car_rounded,
    "Yoqilg'i": Icons.local_gas_station_rounded,
    'Kommunal': Icons.bolt_rounded,
    'Aloqa': Icons.wifi_rounded,
    "Ko'ngilochar": Icons.movie_rounded,
    'Ijara': Icons.home_rounded,
    'Kiyim': Icons.checkroom_rounded,
    "Sog'liq": Icons.favorite_rounded,
    "Ta'lim": Icons.school_rounded,
    'Sport': Icons.fitness_center_rounded,
    "Go'zallik": Icons.spa_rounded,
    'Bolalar': Icons.child_care_rounded,
    "Uy-ro'zg'or": Icons.cleaning_services_rounded,
    "Sovg'alar": Icons.card_giftcard_rounded,
    'Sayohat': Icons.flight_takeoff_rounded,
    'Soliq': Icons.receipt_long_rounded,
    'Qarz': Icons.request_quote_rounded,
    // Daromad
    'Ish haqi': Icons.work_rounded,
    'Bonus': Icons.emoji_events_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Biznes': Icons.business_center_rounded,
    'Investitsiya': Icons.trending_up_rounded,
    'Dividend': Icons.account_balance_rounded,
    'Ijara daromad': Icons.home_work_rounded,
    'Sotuv': Icons.sell_rounded,
    'Qarz qaytarish': Icons.assignment_return_rounded,
    "Sovg'a": Icons.redeem_rounded,
    // Umumiy
    'Boshqa': Icons.category_rounded,
  };

  static const Map<String, Color> _colors = {
    // Xarajat
    'Oziq-ovqat': AppColors.brand,
    'Kafe/Restoran': Color(0xFFFF922B),
    'Transport': AppColors.info,
    "Yoqilg'i": Color(0xFFE8590C),
    'Kommunal': AppColors.warning,
    'Aloqa': Color(0xFF4DABF7),
    "Ko'ngilochar": Color(0xFFE64980),
    'Ijara': AppColors.violet,
    'Kiyim': Color(0xFF15AABF),
    "Sog'liq": AppColors.expense,
    "Ta'lim": Color(0xFF20C997),
    'Sport': Color(0xFF40C057),
    "Go'zallik": Color(0xFFF06595),
    'Bolalar': Color(0xFFFAB005),
    "Uy-ro'zg'or": Color(0xFF748FFC),
    "Sovg'alar": Color(0xFFD6336C),
    'Sayohat': Color(0xFF22B8CF),
    'Soliq': Color(0xFFFA5252),
    'Qarz': Color(0xFFE67700),
    // Daromad
    'Ish haqi': Color(0xFF37B24D),
    'Bonus': Color(0xFFF76707),
    'Freelance': Color(0xFF1098AD),
    'Biznes': Color(0xFF7048E8),
    'Investitsiya': Color(0xFF0CA678),
    'Dividend': Color(0xFF3B5BDB),
    'Ijara daromad': AppColors.violet,
    'Sotuv': Color(0xFF2F9E44),
    'Qarz qaytarish': Color(0xFF12B886),
    "Sovg'a": Color(0xFFE64980),
    // Umumiy
    'Boshqa': Color(0xFF868E96),
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
    'business': Icons.business_center_rounded,
    'health': Icons.favorite_rounded,
    'baby': Icons.child_friendly_rounded,
    'gift': Icons.card_giftcard_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'pet': Icons.pets_rounded,
    'fitness': Icons.fitness_center_rounded,
    'camera': Icons.photo_camera_rounded,
    'bike': Icons.two_wheeler_rounded,
    'gaming': Icons.sports_esports_rounded,
    'music': Icons.music_note_rounded,
    'watch': Icons.watch_rounded,
    'furniture': Icons.chair_rounded,
    'renovation': Icons.handyman_rounded,
    'investment': Icons.trending_up_rounded,
    'emergency': Icons.health_and_safety_rounded,
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
