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

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions(String userId) async {
    return _tx.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((m) => m['user_id'] == userId)
        .map(TransactionModel.fromSqlite)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> insertTransaction(TransactionModel t) async {
    await _tx.put(t.id, t.toSqlite());
  }

  Future<void> updateTransactionSync(String id, bool synced) async {
    final existing = _tx.get(id);
    if (existing != null) {
      final map = Map<String, dynamic>.from(existing as Map);
      map['is_synced'] = synced ? 1 : 0;
      await _tx.put(id, map);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _tx.delete(id);
  }

  Future<List<TransactionModel>> getUnsyncedTransactions(String userId) async {
    return _tx.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((m) => m['user_id'] == userId && m['is_synced'] == 0)
        .map(TransactionModel.fromSqlite)
        .toList();
  }

  // ─── GOALS ────────────────────────────────────────────────────────────────

  Future<List<GoalModel>> getGoals(String userId) async {
    return _goals.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((m) => m['user_id'] == userId)
        .map(GoalModel.fromSqlite)
        .toList();
  }

  Future<void> insertGoal(GoalModel g) async {
    await _goals.put(g.id, g.toSqlite());
  }

  Future<void> updateGoal(GoalModel g) async {
    await _goals.put(g.id, g.toSqlite());
  }

  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
  }

  Future<List<GoalModel>> getUnsyncedGoals(String userId) async {
    return _goals.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((m) => m['user_id'] == userId && m['is_synced'] == 0)
        .map(GoalModel.fromSqlite)
        .toList();
  }

  // ─── TOZALASH ─────────────────────────────────────────────────────────────

  Future<void> clearUserData(String userId) async {
    final txIds = _tx.keys
        .where((k) => (_tx.get(k) as Map)['user_id'] == userId)
        .toList();
    await _tx.deleteAll(txIds);

    final goalIds = _goals.keys
        .where((k) => (_goals.get(k) as Map)['user_id'] == userId)
        .toList();
    await _goals.deleteAll(goalIds);
  }
}
