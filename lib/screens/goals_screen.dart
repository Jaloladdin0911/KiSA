import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../services/app_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/ui_kit.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(
                  title: s('goals'),
                  actions: [
                    CircleAction(
                      icon: Icons.add_rounded,
                      color: AppColors.brand,
                      onTap: () => _showAddModal(context, provider),
                    ),
                  ],
                ),
                Expanded(
                  child: provider.goals.isEmpty
                      ? EmptyState(
                          icon: Icons.flag_rounded,
                          title: s('no_goals'),
                          subtitle: s('add_financial_goal'),
                          action: ElevatedButton.icon(
                            onPressed: () => _showAddModal(context, provider),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(s('add_goal')),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen, 0, AppSpacing.screen, 24),
                          itemCount: provider.goals.length,
                          itemBuilder: (context, i) {
                            final g = provider.goals[i];
                            return _GoalCard(
                              goal: g,
                              currency: provider.currency,
                              strings: s,
                              onDelete: () => provider.deleteGoal(g.id),
                              onAdd: () =>
                                  _showAddMoneyModal(context, provider, g),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddModal(BuildContext context, AppProvider provider) {
    final s = provider.s;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 90));
    String icon = 'target';
    final icons = GoalIcons.keys;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.c;
        return StatefulBuilder(
          builder: (context, set) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Text(s('new_goal'), style: context.t.titleLarge),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      itemBuilder: (_, i) {
                        final selected = icon == icons[i];
                        return GestureDetector(
                          onTap: () => set(() => icon = icons[i]),
                          child: Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(right: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brand.withValues(alpha: 0.14)
                                  : c.surfaceAlt,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brand
                                    : Colors.transparent,
                                width: 1.4,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              GoalIcons.data(icons[i]),
                              size: 23,
                              color: selected
                                  ? AppColors.brand
                                  : c.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: s('goal_name'),
                      prefixIcon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: Money.amountFormatters,
                    decoration: InputDecoration(
                      labelText: s('goal_amount'),
                      suffixText: provider.currency,
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: deadline,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (p != null) set(() => deadline = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 18, color: c.textSecondary),
                          const SizedBox(width: 12),
                          Text('${s('deadline_prefix')}${DateFmt.short(deadline)}',
                              style: context.t.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      final amount = Money.parse(amountCtrl.text);
                      if (titleCtrl.text.trim().isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        return;
                      }
                      provider.addGoal(GoalModel(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        userId: provider.userId,
                        title: titleCtrl.text.trim(),
                        targetAmount: amount,
                        currentAmount: 0,
                        deadline: deadline,
                        icon: icon,
                      ));
                      Navigator.pop(context);
                    },
                    child: Text(s('create')),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddMoneyModal(
      BuildContext context, AppProvider provider, GoalModel goal) {
    final s = provider.s;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(GoalIcons.data(goal.icon),
                color: AppColors.brand, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text(goal.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: Money.amountFormatters,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s('amount'),
            suffixText: provider.currency,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'),
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () {
              final amount = Money.parse(ctrl.text);
              if (amount == null || amount <= 0) return;
              provider.updateGoal(goal.copyWith(
                currentAmount: (goal.currentAmount + amount)
                    .clamp(0, goal.targetAmount),
              ));
              Navigator.pop(ctx);
            },
            child: Text(s('add_money')),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String currency;
  final AppStrings strings;
  final VoidCallback onDelete, onAdd;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.strings,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final c = context.c;
    final done = goal.isCompleted;
    final color = done ? AppColors.brand : AppColors.info;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: done ? AppColors.brand.withValues(alpha: 0.4) : c.border,
          ),
          boxShadow: AppShadows.card(context.isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(GoalIcons.data(goal.icon),
                      color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.t.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        done
                            ? s('completed_goal')
                            : goal.daysLeft > 0
                                ? '${goal.daysLeft} ${s('days_left')}'
                                : s('overdue'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: done
                              ? AppColors.brand
                              : goal.daysLeft <= 0
                                  ? AppColors.expense
                                  : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!done)
                  Material(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        child: Icon(Icons.add_rounded,
                            color: AppColors.brand, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Money.format(goal.currentAmount, currency),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(Money.format(goal.targetAmount, currency),
                    style: context.t.bodySmall),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 9,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}${s('completed_pct')}',
                  style: context.t.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
