import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../l10n/app_strings.dart';
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
  bool _isDarkMode = false;
  double _monthlyBudget = 0.0;
  Map<String, double> _categoryBudgets = {};
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  String? _pinHash;
  bool _notificationsEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _isLoading = true;
  String _language = 'uz';
  String _userName = 'Foydalanuvchi';
  double _usdRate = 0;
  DateTime? _rateDate;

  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  String get currency => _currency;
  bool get isDarkMode => _isDarkMode;
  double get monthlyBudget => _monthlyBudget;
  Map<String, double> get categoryBudgets => _categoryBudgets;
  double get totalCategoryBudget =>
      _categoryBudgets.values.fold(0.0, (a, b) => a + b);
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

  /// Valyuta bo'yicha jami (naqd + karta).
  double currencyBalance(String currency) =>
      balanceOf('cash', currency) + balanceOf('card', currency);

  /// Asosiy valyuta balansi (orqaga moslik uchun).
  double get balance => currencyBalance(_currency);

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

  /// AI tahlili uchun — bitta valyutadagi faqat kirim/chiqim amallari.
  List<TransactionModel> transactionsInCurrency(String currency) =>
      _transactions
          .where((t) =>
              (t.type == 'income' || t.type == 'expense') &&
              t.currency == currency)
          .toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'UZS';
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    final cb = prefs.getString('category_budgets');
    if (cb != null) {
      try {
        final m = jsonDecode(cb) as Map<String, dynamic>;
        _categoryBudgets =
            m.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }
    _pinEnabled = prefs.getBool('pin_enabled') ?? false;
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    _pinHash = prefs.getString('pin_hash');
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    _reminderHour = prefs.getInt('reminder_hour') ?? 20;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    if (_notificationsEnabled) {
      NotificationService.scheduleDaily(_reminderHour, _reminderMinute);
    }
    _language = prefs.getString('language') ?? 'uz';
    _userName = prefs.getString('user_name') ?? 'Foydalanuvchi';
    _usdRate = prefs.getDouble('usd_rate') ?? 0;
    final rd = prefs.getString('usd_rate_date');
    _rateDate = rd != null ? DateTime.tryParse(rd) : null;

    await _loadFromLocal();

    // Kursni fonda yangilash (offline bo'lsa kesh qoladi, xatosiz tushadi)
    _refreshRate();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshRate() async {
    final r = await _rate.fetchUsdRate();
    if (r != null) {
      _usdRate = r;
      _rateDate = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> refreshRate() => _refreshRate();

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

  Future<void> setDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', v);
    _isDarkMode = v;
    notifyListeners();
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

  /// Bu oy kategoriya bo'yicha xarajat (UZS) — byudjet bilan solishtirish uchun.
  double categorySpentThisMonth(String category) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.currency == 'UZS' &&
            t.category == category &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // ── Xavfsizlik (PIN / biometrik) ────────────────────────────────────────────

  String _hashPin(String pin) =>
      sha256.convert(utf8.encode('kisa_$pin')).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pinHash = _hashPin(pin);
    _pinEnabled = true;
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

  bool verifyPin(String pin) => _pinHash != null && _pinHash == _hashPin(pin);

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

  Future<void> clearAllData() async {
    await _local.clearUserData(_userId);
    _transactions = [];
    _goals = [];
    notifyListeners();
  }
}
