import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class LocalDatabase {
  static const _txBox = 'transactions';
  static const _goalBox = 'goals';

  // main() dan bir marta chaqiriladi
  static Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_txBox)) await Hive.openBox(_txBox);
    if (!Hive.isBoxOpen(_goalBox)) await Hive.openBox(_goalBox);
  }

  Box get _tx => Hive.box(_txBox);
  Box get _goals => Hive.box(_goalBox);

  /// Box yozuvlarini modelga o'giradi. Buzilgan yozuv butun ilovani
  /// to'xtatib qo'ymasligi uchun o'tkazib yuboriladi.
  static List<T> _parse<T>(
      Iterable values, String userId, T Function(Map<String, dynamic>) from) {
    final result = <T>[];
    for (final v in values) {
      try {
        final m = Map<String, dynamic>.from(v as Map);
        if (m['user_id'] == userId) result.add(from(m));
      } catch (_) {}
    }
    return result;
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions(String userId) async {
    return _parse(_tx.values, userId, TransactionModel.fromSqlite)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> insertTransaction(TransactionModel t) async {
    await _tx.put(t.id, t.toSqlite());
  }

  Future<void> insertTransactions(Iterable<TransactionModel> txs) async {
    await _tx.putAll({for (final t in txs) t.id: t.toSqlite()});
  }

  Future<void> deleteTransaction(String id) async {
    await _tx.delete(id);
  }

  // ─── GOALS ────────────────────────────────────────────────────────────────

  Future<List<GoalModel>> getGoals(String userId) async {
    return _parse(_goals.values, userId, GoalModel.fromSqlite);
  }

  Future<void> insertGoal(GoalModel g) async {
    await _goals.put(g.id, g.toSqlite());
  }

  Future<void> insertGoals(Iterable<GoalModel> goals) async {
    await _goals.putAll({for (final g in goals) g.id: g.toSqlite()});
  }

  Future<void> updateGoal(GoalModel g) async {
    await _goals.put(g.id, g.toSqlite());
  }

  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
  }

  // ─── TOZALASH ─────────────────────────────────────────────────────────────

  Future<void> clearUserData(String userId) async {
    bool owned(Box box, dynamic k) {
      final v = box.get(k);
      return v is! Map || v['user_id'] == userId;
    }

    final txIds = _tx.keys.where((k) => owned(_tx, k)).toList();
    await _tx.deleteAll(txIds);

    final goalIds = _goals.keys.where((k) => owned(_goals, k)).toList();
    await _goals.deleteAll(goalIds);
  }
}
