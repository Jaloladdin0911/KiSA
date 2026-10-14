import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/recurring_model.dart';
import '../l10n/app_strings.dart';
import '../utils/categories.dart';
import 'local_database.dart';
import 'rate_service.dart';
import 'notification_service.dart';

/// Butun ilova holati — to'liq lokal (offline). Ma'lumotlar qurilmada Hive'da
/// saqlanadi, internetga (Firebase) bog'liq emas. Faqat valyuta kursi onlayn
/// olinadi (cbu.uz) va keshlanadi; u ham offline'da xatosiz ishlaydi.
class AppProvider extends ChangeNotifier {
  static const _userId = 'local_user';

  final LocalDatabase _local = LocalDatabase();
  final RateService _rate = RateService();

  List<TransactionModel> _transactions = [];
  List<GoalModel> _goals = [];
  String _currency = 'UZS';
  String _themeMode = 'light'; // 'system' | 'light' | 'dark'
  double _monthlyBudget = 0.0;
  Map<String, double> _categoryBudgets = {};
  List<RecurringModel> _recurring = [];
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  String? _pinHash;
  int _pinFails = 0;
  DateTime? _pinLockedUntil;
  bool _notificationsEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _isLoading = true;
  String _language = 'uz';
  String _userName = 'Foydalanuvchi';
  String? _phone;
  bool _isLoggedIn = false;
  double _usdRate = 0;
  DateTime? _rateDate;

  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  String get currency => _currency;
  String get themeMode => _themeMode;

  /// Hozir qorong'i tema qo'llanadimi. 'system' rejimida telefon
  /// sozlamasiga ergashadi (main.dart o'zgarishni kuzatib turadi).
  bool get isDarkMode => _themeMode == 'system'
      ? WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark
      : _themeMode == 'dark';
  double get monthlyBudget => _monthlyBudget;
  Map<String, double> get categoryBudgets => _categoryBudgets;
  double get totalCategoryBudget =>
      _categoryBudgets.values.fold(0.0, (a, b) => a + b);
  List<RecurringModel> get recurring => _recurring;
  bool get pinEnabled => _pinEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);
  bool get isLoading => _isLoading;
  String get language => _language;
  AppStrings get s => AppStrings(_language);
  String get userId => _userId;
  String get userName => _userName;
  String? get phone => _phone;

  /// Bu qurilmada oldin ro'yxatdan o'tilganmi (telefon raqam saqlanganmi).
  bool get isRegistered => _phone != null;

  /// Ro'yxatdan o'tilgan, hozir sessiya ochiqmi (Kirish/Chiqish holati).
  bool get isLoggedIn => _isLoggedIn;
  double get usdRate => _usdRate;
  DateTime? get rateDate => _rateDate;

  // ── Hamyon balanslari ──────────────────────────────────────────────────────
  // Har bir hamyon = (joy: naqd/karta) × (valyuta: UZS/USD). Har xil valyuta
  // qo'shilmaydi — balanslar har doim valyuta bo'yicha alohida hisoblanadi.

  /// Bitta hamyon (joy + valyuta) balansi. Kirim qo'shadi, chiqim ayiradi,
  /// o'tkazma/ayirboshlash manbadan ayirib, qabul qiluvchiga qo'shadi.
  double balanceOf(String place, String currency) {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == 'income') {
        if (t.place == place && t.currency == currency) sum += t.amount;
      } else if (t.type == 'expense') {
        if (t.place == place && t.currency == currency) sum -= t.amount;
      } else if (t.type == 'adjust') {
        // Ishorali summa: + yoki −
        if (t.place == place && t.currency == currency) sum += t.amount;
      } else {
        // transfer / exchange
        if (t.place == place && t.currency == currency) sum -= t.amount;
        final toP = t.toPlace ?? t.place;
        final toC = t.toCurrency ?? t.currency;
        final toA = t.toAmount ?? t.amount;
        if (toP == place && toC == currency) sum += toA;
      }
    }
    return sum;
  }

  /// Hamyon qoldig'ini haqiqiy summaga moslaydi: farqni 'adjust' amali
  /// sifatida yozadi (statistikaga ta'sir qilmaydi). Farq bo'lmasa — hech narsa.
  Future<bool> setActualBalance(
      String place, String currency, double actual) async {
    final diff = actual - balanceOf(place, currency);
    if (diff.abs() < 0.005) return false;
    await addTransaction(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      type: 'adjust',
      amount: double.parse(diff.toStringAsFixed(2)),
      category: 'adjust',
      date: DateTime.now(),
      note: '',
      place: place,
      currency: currency,
    ));
    return true;
  }

  /// Umumiy boylik so'mda: barcha hamyonlar, USD — CBU kursi bo'yicha.
  double get netWorthUzs =>
      currencyBalance('UZS') + toUzs(currencyBalance('USD'), 'USD');

  /// Valyuta bo'yicha jami (naqd + karta).
  double currencyBalance(String currency) =>
      balanceOf('cash', currency) + balanceOf('card', currency);

  /// Asosiy valyuta balansi (orqaga moslik uchun).
  double get balance => currencyBalance(_currency);

  /// Summani so'mga o'giradi (CBU kursi bo'yicha). Kurs hali noma'lum bo'lsa
  /// USD summa hisobga olinmaydi (0) — taxminiy son ko'rsatgandan ko'ra yaxshi.
  double toUzs(double amount, String currency) {
    if (currency == 'UZS') return amount;
    if (currency == 'USD' && _usdRate > 0) return amount * _usdRate;
    return 0;
  }

  /// Bu oydagi barcha xarajatlar so'mda (USD kurs bo'yicha qo'shiladi) —
  /// so'mda belgilangan byudjet bilan solishtirish uchun.
  double expenseThisMonthInUzs() =>
      expenseThisMonth('UZS') + toUzs(expenseThisMonth('USD'), 'USD');

  Iterable<TransactionModel> _monthTx(String currency, String type) {
    final now = DateTime.now();
    return _transactions.where((t) =>
        t.type == type &&
        t.currency == currency &&
        t.date.month == now.month &&
        t.date.year == now.year);
  }

  double incomeThisMonth(String currency) =>
      _monthTx(currency, 'income').fold(0.0, (s, t) => s + t.amount);

  double expenseThisMonth(String currency) =>
      _monthTx(currency, 'expense').fold(0.0, (s, t) => s + t.amount);

  Map<String, double> expenseByCategory(String currency) {
    final Map<String, double> result = {};
    for (final t in _transactions
        .where((t) => t.type == 'expense' && t.currency == currency)) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }

  List<Map<String, dynamic>> last6MonthsData(String currency) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      return {
        'month': month,
        'income': _transactions
            .where((t) =>
                t.type == 'income' &&
                t.currency == currency &&
                t.date.month == month.month &&
                t.date.year == month.year)
            .fold(0.0, (s, t) => s + t.amount),
        'expense': _transactions
            .where((t) =>
                t.type == 'expense' &&
                t.currency == currency &&
                t.date.month == month.month &&
                t.date.year == month.year)
            .fold(0.0, (s, t) => s + t.amount),
      };
    });
  }

  // ── Statistika (so'mda, USD kurs bo'yicha qo'shiladi) ──────────────────────

  /// [from, to) oralig'idagi [type] ('income' | 'expense') amallari.
  Iterable<TransactionModel> inRange(String type, DateTime from, DateTime to,
          {String? category}) =>
      _transactions.where((t) =>
          t.type == type &&
          (category == null || t.category == category) &&
          !t.date.isBefore(from) &&
          t.date.isBefore(to));

  /// [from, to) oralig'ida kategoriya bo'yicha jami (so'mda).
  Map<String, double> categoryTotals(String type, DateTime from, DateTime to) {
    final result = <String, double>{};
    for (final t in inRange(type, from, to)) {
      final v = toUzs(t.amount, t.currency);
      if (v > 0) result[t.category] = (result[t.category] ?? 0) + v;
    }
    return result;
  }

  /// Oxirgi [count] oy bo'yicha kirim va chiqim (so'mda), eskisidan yangisiga.
  List<({DateTime month, double income, double expense})> monthlyTotals(
      {int count = 6}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final from = DateTime(now.year, now.month - (count - 1 - i), 1);
      final to = DateTime(from.year, from.month + 1, 1);
      double sum(String type) => inRange(type, from, to)
          .fold(0.0, (s, t) => s + toUzs(t.amount, t.currency));
      return (month: from, income: sum('income'), expense: sum('expense'));
    });
  }

  /// AI tahlili uchun — bitta valyutadagi faqat kirim/chiqim amallari.
  List<TransactionModel> transactionsInCurrency(String currency) =>
      _transactions
          .where((t) =>
              (t.type == 'income' || t.type == 'expense') &&
              t.currency == currency)
          .toList();

  /// Ilovani ishga tushiradi. Biror bosqich xato bersa ham ilova ochiladi —
  /// aks holda foydalanuvchi splash ekranida qotib qolardi.
  Future<void> init() async {
    try {
      await _init();
    } catch (e, st) {
      debugPrint('AppProvider.init xatosi: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'UZS';
    // Eski versiyada faqat 'dark_mode' (bool) saqlangan bo'lishi mumkin
    _themeMode = prefs.getString('theme_mode') ??
        ((prefs.getBool('dark_mode') ?? false) ? 'dark' : 'light');
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    final cb = prefs.getString('category_budgets');
    if (cb != null) {
      try {
        final m = jsonDecode(cb) as Map<String, dynamic>;
        _categoryBudgets =
            m.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }
    final rec = prefs.getString('recurring');
    if (rec != null) {
      try {
        _recurring = [];
        for (final e in jsonDecode(rec) as List) {
          try {
            _recurring
                .add(RecurringModel.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {} // buzilgan shablon o'tkazib yuboriladi
        }
      } catch (_) {}
    }
    _loadCustomCategories(prefs.getString('custom_categories'));
    _pinEnabled = prefs.getBool('pin_enabled') ?? false;
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _pinHash = prefs.getString('pin_hash');
    _pinFails = prefs.getInt('pin_fails') ?? 0;
    final lu = prefs.getString('pin_locked_until');
    _pinLockedUntil = lu != null ? DateTime.tryParse(lu) : null;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    _reminderHour = prefs.getInt('reminder_hour') ?? 20;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    if (_notificationsEnabled) {
      NotificationService.scheduleDaily(_reminderHour, _reminderMinute)
          .catchError((_) {});
    }
    _language = prefs.getString('language') ?? 'uz';
    _userName = prefs.getString('user_name') ?? 'Foydalanuvchi';
    _phone = prefs.getString('phone');
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _usdRate = prefs.getDouble('usd_rate') ?? 0;
    final rd = prefs.getString('usd_rate_date');
    _rateDate = rd != null ? DateTime.tryParse(rd) : null;

    await _loadFromLocal();

    // Takroriy to'lovlardan muddati kelganlarini avtomatik yaratamiz
    await _processRecurring();

    // Kursni fonda yangilash (offline bo'lsa kesh qoladi, xatosiz tushadi)
    _refreshRate();
  }

  /// CBU'dan kursni yangilaydi; muvaffaqiyatli bo'lsa true.
  Future<bool> _refreshRate() async {
    final r = await _rate.fetchUsdRate();
    if (r == null) return false;
    _usdRate = r;
    _rateDate = DateTime.now();
    notifyListeners();
    return true;
  }

  Future<bool> refreshRate() => _refreshRate();

  Future<void> setUsdRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('usd_rate', value);
    await prefs.setString('usd_rate_date', DateTime.now().toIso8601String());
    _usdRate = value;
    _rateDate = DateTime.now();
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    _transactions = await _local.getTransactions(_userId);
    _goals = await _local.getGoals(_userId);
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel t) async {
    await _local.insertTransaction(t);
    _transactions.insert(0, t);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _local.insertTransaction(t);
    final idx = _transactions.indexWhere((x) => x.id == t.id);
    if (idx != -1) {
      _transactions[idx] = t;
    } else {
      _transactions.add(t);
    }
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _local.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> addGoal(GoalModel goal) async {
    await _local.insertGoal(goal);
    _goals.add(goal);
    notifyListeners();
  }

  Future<void> updateGoal(GoalModel updated) async {
    await _local.updateGoal(updated);
    final idx = _goals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _goals[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _local.deleteGoal(id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    notifyListeners();
  }

  // ── Ro'yxatdan o'tish / Kirish / Chiqish ────────────────────────────────────
  // Backend/SMS yo'q — telefon raqam faqat shu qurilmada lokal saqlanadi va
  // "Kirish"da o'sha raqamga taqqoslanadi (haqiqiy tasdiqlash emas).

  /// Birinchi marta ro'yxatdan o'tish — ism va telefon raqamni saqlaydi,
  /// sessiyani ochiq deb belgilaydi.
  Future<void> register(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('phone', phone);
    await prefs.setBool('is_logged_in', true);
    _userName = name;
    _phone = phone;
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Kiritilgan raqam saqlangan raqamga mos kelsa sessiyani ochadi va true
  /// qaytaradi; mos kelmasa hech narsa o'zgartirmay false qaytaradi.
  Future<bool> login(String phone) async {
    if (_phone == null || _phone != phone) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  /// Sessiyani yopadi — ma'lumotlar (tranzaksiya, maqsad, profil) saqlanib
  /// qoladi, faqat qayta "Kirish" talab qilinadi.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Ro'yxatdan o'tgan foydalanuvchi telefon raqamini Sozlamalardan
  /// tahrirlashi uchun.
  Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);
    _phone = phone;
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', c);
    _currency = c;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    _language = lang;
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) => setThemeMode(v ? 'dark' : 'light');

  Future<void> setThemeMode(String mode) async {
    if (!const ['system', 'light', 'dark'].contains(mode)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    _themeMode = mode;
    notifyListeners();
  }

  /// Tizim temasi o'zgarganda (main.dart chaqiradi) — 'system' rejimida qayta chizish.
  void onPlatformBrightnessChanged() {
    if (_themeMode == 'system') notifyListeners();
  }

  Future<void> setMonthlyBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', amount);
    _monthlyBudget = amount;
    notifyListeners();
  }

  // ── Kategoriya byudjetlari ──────────────────────────────────────────────────

  Future<void> _saveCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_budgets', jsonEncode(_categoryBudgets));
  }

  Future<void> setCategoryBudget(String category, double limit) async {
    _categoryBudgets[category] = limit;
    await _saveCategoryBudgets();
    notifyListeners();
  }

  Future<void> deleteCategoryBudget(String category) async {
    _categoryBudgets.remove(category);
    await _saveCategoryBudgets();
    notifyListeners();
  }

  // ── Foydalanuvchi kategoriyalari ────────────────────────────────────────────
  // Reestr CategoryMeta.custom da (AppStrings va ikonka/rang shu yerdan oladi).

  List<CustomCategory> customCategories(String type) => CategoryMeta.custom
      .values
      .where((c) => c.type == type && !c.archived)
      .toList();

  void _loadCustomCategories(String? raw) {
    CategoryMeta.custom.clear();
    if (raw == null) return;
    try {
      for (final e in jsonDecode(raw) as List) {
        try {
          final c = CustomCategory.fromJson(Map<String, dynamic>.from(e));
          CategoryMeta.custom[c.key] = c;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_categories',
        jsonEncode(CategoryMeta.custom.values.map((c) => c.toJson()).toList()));
  }

  /// Yangi kategoriya yaratadi va kalitini qaytaradi.
  Future<String> addCategory({
    required String name,
    required String type,
    required String icon,
    required int color,
  }) async {
    final key = 'c_${DateTime.now().microsecondsSinceEpoch}';
    CategoryMeta.custom[key] = CustomCategory(
        key: key, name: name.trim(), type: type, icon: icon, colorValue: color);
    await _saveCustomCategories();
    notifyListeners();
    return key;
  }

  /// Kategoriyani tanlash ro'yxatlaridan olib tashlaydi (arxivlaydi). Eski
  /// amallar o'z nomi va ikonkasi bilan ko'rinishda qoladi. [restore] — undo.
  Future<void> archiveCategory(String key, {bool restore = false}) async {
    final c = CategoryMeta.custom[key];
    if (c == null) return;
    CategoryMeta.custom[key] = c.copyWith(archived: !restore);
    await _saveCustomCategories();
    notifyListeners();
  }

  // ── Takroriy to'lovlar ──────────────────────────────────────────────────────

  Future<void> _saveRecurring() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'recurring', jsonEncode(_recurring.map((r) => r.toJson()).toList()));
  }

  /// Muddati kelgan takroriy to'lovlarni tranzaksiyaga aylantiradi (catch-up).
  Future<void> _processRecurring() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    bool changed = false;
    int counter = 0;
    for (var i = 0; i < _recurring.length; i++) {
      final r = _recurring[i];
      var next = r.nextDate;
      // Bir ochilishda maksimal 370 ta yaratamiz (runaway oldini olish)
      int guard = 0;
      while (!next.isAfter(todayDate) && guard < 370) {
        await _local.insertTransaction(TransactionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${counter++}',
          userId: _userId,
          type: r.type,
          amount: r.amount,
          category: r.category,
          date: next,
          note: r.note,
          place: r.place,
          currency: r.currency,
        ));
        next = r.advance(next);
        changed = true;
        guard++;
      }
      // Juda ko'p o'tkazib yuborilgan bo'lsa, qolganini yaratmasdan kelajakka o'tamiz
      while (!next.isAfter(todayDate)) {
        next = r.advance(next);
      }
      if (next != r.nextDate) _recurring[i] = r.copyWith(nextDate: next);
    }
    if (changed) {
      await _saveRecurring();
      await _loadFromLocal();
    }
  }

  Future<void> addRecurring(RecurringModel r) async {
    _recurring.add(r);
    await _saveRecurring();
    await _processRecurring();
    notifyListeners();
  }

  /// "Bekor qilish" — o'chirilgan shablonni o'sha holatida qaytaradi
  /// (o'tkazib yuborilgan sanalar uchun qayta amal yaratmaydi).
  Future<void> restoreRecurring(RecurringModel r) async {
    if (_recurring.any((x) => x.id == r.id)) return;
    _recurring.add(r);
    await _saveRecurring();
    notifyListeners();
  }

  Future<void> deleteRecurring(String id) async {
    _recurring.removeWhere((r) => r.id == id);
    await _saveRecurring();
    notifyListeners();
  }

  /// Bu oy kategoriya bo'yicha xarajat so'mda (USD kurs bo'yicha qo'shiladi) —
  /// byudjet bilan solishtirish uchun.
  double categorySpentThisMonth(String category) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.category == category &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (s, t) => s + toUzs(t.amount, t.currency));
  }

  // ── Xavfsizlik (PIN / biometrik) ────────────────────────────────────────────

  String _hashPin(String pin) =>
      sha256.convert(utf8.encode('kisa_$pin')).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = _hashPin(pin);
    _pinEnabled = true;
    _pinFails = 0;
    _pinLockedUntil = null;
    await prefs.remove('pin_fails');
    await prefs.remove('pin_locked_until');
    await prefs.setString('pin_hash', _pinHash!);
    await prefs.setBool('pin_enabled', true);
    notifyListeners();
  }

  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = null;
    _pinEnabled = false;
    _biometricEnabled = false;
    await prefs.remove('pin_hash');
    await prefs.setBool('pin_enabled', false);
    await prefs.setBool('biometric_enabled', false);
    notifyListeners();
  }

  static const _maxPinFails = 5;

  /// PIN qulfi vaqtincha bloklanganmi — bo'lsa, qancha vaqt qolgan.
  Duration? get pinLockRemaining {
    final until = _pinLockedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  /// PIN'ni tekshiradi. Ketma-ket 5 marta xato bo'lsa qulf bloklanadi
  /// (30 s, keyin har safar ikki barobar, maksimal 1 soat). Hisob qayta
  /// ishga tushirilganda ham saqlanib qoladi.
  Future<bool> verifyPin(String pin) async {
    if (pinLockRemaining != null) return false;
    final prefs = await SharedPreferences.getInstance();
    if (_pinHash != null && _pinHash == _hashPin(pin)) {
      _pinFails = 0;
      _pinLockedUntil = null;
      await prefs.remove('pin_fails');
      await prefs.remove('pin_locked_until');
      return true;
    }
    _pinFails++;
    await prefs.setInt('pin_fails', _pinFails);
    if (_pinFails >= _maxPinFails) {
      final rounds = _pinFails - _maxPinFails; // 0, 1, 2, ...
      final secs = (30 * (1 << rounds.clamp(0, 7))).clamp(30, 3600);
      _pinLockedUntil = DateTime.now().add(Duration(seconds: secs));
      await prefs.setString(
          'pin_locked_until', _pinLockedUntil!.toIso8601String());
    }
    notifyListeners();
    return false;
  }

  /// PIN unutilganda: ro'yxatdan o'tgan telefon raqami mos kelsa PIN
  /// o'chiriladi (offline ilovada boshqa tiklash yo'li yo'q — "Kirish" bilan
  /// bir xil darajadagi tekshiruv). Ma'lumotlar saqlanib qoladi.
  Future<bool> resetPinWithPhone(String phone) async {
    if (_phone == null || _phone != phone) return false;
    await disablePin();
    final prefs = await SharedPreferences.getInstance();
    _pinFails = 0;
    _pinLockedUntil = null;
    await prefs.remove('pin_fails');
    await prefs.remove('pin_locked_until');
    return true;
  }

  Future<void> setBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = value;
    await prefs.setBool('biometric_enabled', value);
    notifyListeners();
  }

  // ── Eslatma (bildirishnoma) ─────────────────────────────────────────────────

  /// Kunlik eslatmani yoqadi/o'chiradi. Yoqishda ruxsat so'raydi; ruxsat
  /// berilmasa false qaytaradi.
  Future<bool> setNotifications(bool enabled, {int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return false;
      _reminderHour = hour ?? _reminderHour;
      _reminderMinute = minute ?? _reminderMinute;
      await NotificationService.scheduleDaily(_reminderHour, _reminderMinute);
      await prefs.setInt('reminder_hour', _reminderHour);
      await prefs.setInt('reminder_minute', _reminderMinute);
    } else {
      await NotificationService.cancelAll();
    }
    _notificationsEnabled = enabled;
    await prefs.setBool('notifications_enabled', enabled);
    notifyListeners();
    return true;
  }

  // ── Takroriy to'lovlar: yaqinlashayotganlar ─────────────────────────────────

  /// Keyingi [days] kun ichida (bugun ham) tushadigan takroriy to'lovlar,
  /// sanasi bo'yicha tartiblangan.
  List<RecurringModel> upcomingRecurring({int days = 7}) {
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month, now.day + days);
    return _recurring.where((r) => !r.nextDate.isAfter(limit)).toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
  }

  // ── Zaxira nusxa (JSON) ─────────────────────────────────────────────────────

  static const backupFormat = 'kisa-backup';
  static const backupVersion = 1;

  /// Barcha moliyaviy ma'lumot va asosiy sozlamalar. PIN va telefon raqam
  /// ataylab kiritilmaydi — zaxira fayli boshqa qurilmaga/odamga tushishi mumkin.
  Map<String, dynamic> toBackup() => {
        'format': backupFormat,
        'version': backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'transactions': _transactions.map((t) => t.toSqlite()).toList(),
        'goals': _goals.map((g) => g.toSqlite()).toList(),
        'recurring': _recurring.map((r) => r.toJson()).toList(),
        'custom_categories':
            CategoryMeta.custom.values.map((c) => c.toJson()).toList(),
        'category_budgets': _categoryBudgets,
        'monthly_budget': _monthlyBudget,
        'settings': {
          'currency': _currency,
          'language': _language,
          'dark_mode': isDarkMode,
          'theme_mode': _themeMode,
          'user_name': _userName,
        },
      };

  /// Zaxiradagi ma'lumotlar bilan joriy ma'lumotlarni to'liq almashtiradi.
  /// Avval hammasi tekshiriladi — fayl yaroqsiz bo'lsa [FormatException]
  /// otiladi va hech narsa o'zgarmaydi. Tiklangan amallar sonini qaytaradi.
  Future<int> restoreBackup(Map<String, dynamic> data) async {
    if (data['format'] != backupFormat) {
      throw const FormatException('Not a KiSA backup');
    }
    final v = data['version'];
    if (v is! int || v > backupVersion) {
      throw const FormatException('Unsupported backup version');
    }

    List<Map<String, dynamic>> list(String key) => [
          for (final e in (data[key] as List? ?? const []))
            Map<String, dynamic>.from(e as Map)
        ];

    final List<TransactionModel> txs;
    final List<GoalModel> goals;
    final List<RecurringModel> recurring;
    final List<CustomCategory> customCats;
    final Map<String, double> budgets;
    try {
      // Hamma yozuvlar joriy foydalanuvchiga biriktiriladi
      txs = list('transactions')
          .map((m) => TransactionModel.fromSqlite({...m, 'user_id': _userId}))
          .toList();
      goals = list('goals')
          .map((m) => GoalModel.fromSqlite({...m, 'user_id': _userId}))
          .toList();
      recurring = list('recurring').map(RecurringModel.fromJson).toList();
      customCats =
          list('custom_categories').map(CustomCategory.fromJson).toList();
      budgets = (data['category_budgets'] as Map? ?? const {})
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    } catch (e) {
      throw FormatException('Corrupted backup: $e');
    }
    final monthly = (data['monthly_budget'] as num?)?.toDouble() ?? 0;

    await _local.clearUserData(_userId);
    await _local.insertTransactions(txs);
    await _local.insertGoals(goals);

    final prefs = await SharedPreferences.getInstance();
    _recurring = recurring;
    await _saveRecurring();
    // Kategoriyalar birlashtiriladi: zaxiradagilar qo'shiladi, mavjudlari qoladi
    for (final c in customCats) {
      CategoryMeta.custom[c.key] = c;
    }
    await _saveCustomCategories();
    _categoryBudgets = budgets;
    await _saveCategoryBudgets();
    _monthlyBudget = monthly;
    await prefs.setDouble('monthly_budget', monthly);

    final st = data['settings'];
    if (st is Map) {
      if (st['currency'] is String) await setCurrency(st['currency']);
      if (st['language'] is String) await setLanguage(st['language']);
      if (st['theme_mode'] is String) {
        await setThemeMode(st['theme_mode']);
      } else if (st['dark_mode'] is bool) {
        await setDarkMode(st['dark_mode']);
      }
      final name = st['user_name'];
      if (name is String && name.trim().isNotEmpty) await setUserName(name);
    }

    await _loadFromLocal();
    await _processRecurring();
    notifyListeners();
    return txs.length;
  }

  /// Barcha moliyaviy ma'lumotlarni o'chiradi: tranzaksiyalar, maqsadlar,
  /// takroriy to'lovlar va byudjetlar. Profil, PIN va sozlamalar qoladi.
  Future<void> clearAllData() async {
    await _local.clearUserData(_userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recurring');
    await prefs.remove('category_budgets');
    await prefs.remove('monthly_budget');
    _transactions = [];
    _goals = [];
    _recurring = [];
    _categoryBudgets = {};
    _monthlyBudget = 0;
    notifyListeners();
  }
}
