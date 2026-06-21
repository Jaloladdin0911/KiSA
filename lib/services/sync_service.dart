import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import 'local_database.dart';

class SyncService {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final LocalDatabase _local = LocalDatabase();

  // connectivity_plus v6 — List<ConnectivityResult> qaytaradi
  Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> syncAll(String userId) async {
    if (!await isOnline) return;
    await _syncTransactions(userId);
    await _syncGoals(userId);
  }

  Future<void> _syncTransactions(String userId) async {
    final db = _firestore;
    if (db == null) return;

    final unsynced = await _local.getUnsyncedTransactions(userId);
    for (final t in unsynced) {
      try {
        await db
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(t.id)
            .set(t.toFirestore());
        await _local.updateTransactionSync(t.id, true);
      } catch (_) {}
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      for (final doc in snapshot.docs) {
        final t = TransactionModel.fromFirestore(doc);
        await _local.insertTransaction(t);
      }
    } catch (_) {}
  }

  Future<void> _syncGoals(String userId) async {
    final db = _firestore;
    if (db == null) return;

    final unsynced = await _local.getUnsyncedGoals(userId);
    for (final g in unsynced) {
      try {
        await db
            .collection('users')
            .doc(userId)
            .collection('goals')
            .doc(g.id)
            .set(g.toFirestore());
        await _local.updateGoal(g.copyWith(isSynced: true));
      } catch (_) {}
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();

      for (final doc in snapshot.docs) {
        final g = GoalModel.fromFirestore(doc);
        await _local.insertGoal(g);
      }
    } catch (_) {}
  }

  Future<void> deleteTransactionFromFirebase(String userId, String txId) async {
    if (!await isOnline) return;
    final db = _firestore;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txId)
          .delete();
    } catch (_) {}
  }

  /// Foydalanuvchining barcha Firestore ma'lumotlarini o'chiradi
  /// (akkaunt o'chirilganda). Auth user o'chirilishidan OLDIN chaqirilishi kerak,
  /// chunki o'chirilgach Firestore qoidalari ruxsat bermaydi.
  Future<void> deleteAllUserData(String userId) async {
    if (!await isOnline) return;
    final db = _firestore;
    if (db == null) return;
    try {
      for (final coll in ['transactions', 'goals']) {
        final snap =
            await db.collection('users').doc(userId).collection(coll).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> deleteGoalFromFirebase(String userId, String goalId) async {
    if (!await isOnline) return;
    final db = _firestore;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .delete();
    } catch (_) {}
  }
}
