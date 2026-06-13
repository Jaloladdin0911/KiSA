import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../l10n/app_strings.dart';
import 'local_database.dart';
import 'sync_service.dart';
import 'auth_service.dart';

class AppProvider extends ChangeNotifier {
  final LocalDatabase _local = LocalDatabase();
  final SyncService _sync = SyncService();
  final AuthService _auth = AuthService();

  List<TransactionModel> _transactions = [];
  List<GoalModel> _goals = [];
  String _currency = 'UZS';
  bool _isDarkMode = false;
  double _monthlyBudget = 0.0;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOnline = false;
  String _language = 'uz';
  String _userName = 'Foydalanuvchi';

  StreamSubscription? _connectivitySub;

  List<TransactionModel> get transactions => _transactions;
  List<GoalModel> get goals => _goals;
  String get currency => _currency;
  bool get isDarkMode => _isDarkMode;
  double get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  String get language => _language;
  AppStrings get s => AppStrings(_language);
  String get userId => _auth.userId;
  String get userName => _userName;

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;

  double get thisMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  Map<String, double> get expenseByCategory {
    final Map<String, double> result = {};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }

  List<Map<String, dynamic>> get last6MonthsData {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      return {
        'month': month,
        'income': _transactions
            .where((t) =>
                t.type == 'income' &&
                t.date.month == month.month &&
                t.date.year == month.year)
            .fold(0.0, (s, t) => s + t.amount),
        'expense': _transactions
            .where((t) =>
                t.type == 'expense' &&
                t.date.month == month.month &&
                t.date.year == month.year)
            .fold(0.0, (s, t) => s + t.amount),
      };
    });
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'UZS';
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    _language = prefs.getString('language') ?? 'uz';
    _userName = _resolveUserName(prefs);

    await _loadFromLocal();

    // connectivity_plus v6 — List<ConnectivityResult> qaytaradi
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();

      if (!wasOnline && _isOnline && _auth.isLoggedIn) {
        _syncWithFirebase();
      }
    });

    _isOnline = await _sync.isOnline;

    if (_auth.isLoggedIn && _isOnline) {
      _syncWithFirebase();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    _transactions = await _local.getTransactions(userId);
    _goals = await _local.getGoals(userId);
    notifyListeners();
  }

  Future<void> _syncWithFirebase() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    await _sync.syncAll(userId);
    await _loadFromLocal();

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel t) async {
    await _local.insertTransaction(t);
    _transactions.insert(0, t);
    notifyListeners();

    if (_isOnline && _auth.isLoggedIn) {
      _syncWithFirebase();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _local.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();

    if (_isOnline && _auth.isLoggedIn) {
      await _sync.deleteTransactionFromFirebase(userId, id);
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    await _local.insertGoal(goal);
    _goals.add(goal);
    notifyListeners();

    if (_isOnline && _auth.isLoggedIn) {
      _syncWithFirebase();
    }
  }

  Future<void> updateGoal(GoalModel updated) async {
    await _local.updateGoal(updated);
    final idx = _goals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _goals[idx] = updated;
    notifyListeners();

    if (_isOnline && _auth.isLoggedIn) {
      _syncWithFirebase();
    }
  }

  Future<void> deleteGoal(String id) async {
    await _local.deleteGoal(id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();

    if (_isOnline && _auth.isLoggedIn) {
      await _sync.deleteGoalFromFirebase(userId, id);
    }
  }

  // Firebase displayName birinchi o'rinda, bo'lmasa lokal saqlangan ism.
  String _resolveUserName(SharedPreferences prefs) {
    final fromFirebase = _auth.currentUser?.displayName;
    if (fromFirebase != null && fromFirebase.isNotEmpty) return fromFirebase;
    final local = prefs.getString('user_name');
    if (local != null && local.isNotEmpty) return local;
    return 'Foydalanuvchi';
  }

  Future<void> setUserName(String name) async {
    await _auth.updateDisplayName(name);
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

  Future<void> clearAllData() async {
    await _local.clearUserData(userId);
    _transactions = [];
    _goals = [];
    notifyListeners();
  }

  Future<void> manualSync() async {
    if (!_auth.isLoggedIn) return;
    await _syncWithFirebase();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
