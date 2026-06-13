import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon;
  final bool isSynced;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
    this.isSynced = false,
  });

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isCompleted => currentAmount >= targetAmount;
  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  Map<String, dynamic> toSqlite() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline.toIso8601String(),
        'icon': icon,
        'is_synced': isSynced ? 1 : 0,
      };

  factory GoalModel.fromSqlite(Map<String, dynamic> map) => GoalModel(
        id: map['id'],
        userId: map['user_id'] ?? '',
        title: map['title'],
        targetAmount: (map['target_amount'] as num).toDouble(),
        currentAmount: (map['current_amount'] as num).toDouble(),
        deadline: DateTime.parse(map['deadline']),
        icon: map['icon'] ?? 'target',
        isSynced: map['is_synced'] == 1,
      );

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': Timestamp.fromDate(deadline),
        'icon': icon,
      };

  factory GoalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      GoalModel(
        id: doc.id,
        userId: doc.data()?['userId'] ?? '',
        title: doc.data()?['title'] ?? '',
        targetAmount: (doc.data()?['targetAmount'] as num).toDouble(),
        currentAmount: (doc.data()?['currentAmount'] as num).toDouble(),
        deadline: (doc.data()?['deadline'] as Timestamp).toDate(),
        icon: doc.data()?['icon'] ?? 'target',
        isSynced: true,
      );

  GoalModel copyWith({double? currentAmount, bool? isSynced}) => GoalModel(
        id: id,
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline,
        icon: icon,
        isSynced: isSynced ?? this.isSynced,
      );
}
