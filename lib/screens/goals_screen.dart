import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/goal_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';

/// Maqsadlar — KISA_DESIGN_SPEC.md, Section 9. Push qilingan ekran (back button).
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  static const _palette = [
    KColors.blue,
    KColors.orange,
    KColors.primary,
    KColors.purple,
    KColors.pink,
    KColors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final goals = provider.goals;
        final totalSaved =
            goals.fold(0.0, (s, g) => s + g.currentAmount);
        final active = goals.where((g) => !g.isCompleted).length;

        return Scaffold(
          backgroundColor: KColors.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      const KBackButton(),
                      Expanded(
                        child: Center(
                          child: Text('Maqsadlar',
                              style: k(17, w: FontWeight.w600)),
                        ),
                      ),
                      KAddButton(onTap: () => _showAddModal(context, provider)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // Summary (dark)
                      Padding(
                        padding: kPad,
                        child: _Summary(total: totalSaved, active: active),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: kPad,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Faol maqsadlar',
                              style: k(15, w: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (goals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text("Hali maqsad yo'q",
                                style: k(14, c: KColors.mut)),
                          ),
                        )
                      else
                        ...goals.asMap().entries.map((e) {
                          final color = _palette[e.key % _palette.length];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _GoalCard(
                              goal: e.value,
                              color: color,
                              onAddMoney: () =>
                                  _addMoney(context, provider, e.value),
                              onDelete: () => provider.deleteGoal(e.value.id),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Maqsad qo'shish ───────────────────────────────────────────────────────
  void _showAddModal(BuildContext context, AppProvider provider) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 90));
    String icon = 'target';
    final icons = GoalIcons.keys;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setM) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                          color: KColors.line,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Yangi maqsad', style: k(18, w: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final sel = icon == icons[i];
                        return GestureDetector(
                          onTap: () => setM(() => icon = icons[i]),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: sel
                                  ? KColors.primary.withValues(alpha: 0.14)
                                  : KColors.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: sel
                                      ? KColors.primary
                                      : Colors.transparent,
                                  width: 1.5),
                            ),
                            child: Icon(GoalIcons.data(icons[i]),
                                size: 22,
                                color: sel ? KColors.primary : KColors.sub),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Field(controller: titleCtrl, label: 'Maqsad nomi'),
                  const SizedBox(height: 12),
                  _Field(
                      controller: amountCtrl,
                      label: 'Maqsad summasi',
                      number: true,
                      suffix: "so'm"),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: deadline,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (p != null) setM(() => deadline = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                          color: KColors.bg,
                          borderRadius: BorderRadius.circular(rTile)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: KColors.sub),
                          const SizedBox(width: 12),
                          Text('Muddat: ${DateFmt.short(deadline)}',
                              style: k(14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    label: 'Yaratish',
                    onTap: () {
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
                      Navigator.pop(ctx);
                    },
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addMoney(BuildContext context, AppProvider provider, GoalModel goal) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(goal.title, style: k(16, w: FontWeight.w700)),
        content: _Field(controller: ctrl, label: 'Summa', number: true, suffix: "so'm"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Bekor', style: k(14, c: KColors.sub)),
          ),
          _PrimaryButton(
            label: "Qo'shish",
            compact: true,
            onTap: () {
              final amount = Money.parse(ctrl.text);
              if (amount == null || amount <= 0) return;
              provider.updateGoal(goal.copyWith(
                currentAmount:
                    (goal.currentAmount + amount).clamp(0, goal.targetAmount),
              ));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double total;
  final int active;
  const _Summary({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KColors.dark,
        borderRadius: BorderRadius.circular(rCardLg),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Jami jamg'arma",
                    style: k(13, w: FontWeight.w500, c: const Color(0xFF9AA0AE))),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(Money.plain(total, currency: 'UZS'),
                            style: k(26, w: FontWeight.w700, c: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text("so'm",
                          style: k(13,
                              w: FontWeight.w500,
                              c: const Color(0xFF9AA0AE))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$active ta maqsad sari yo\'lda',
                    style: k(12,
                        w: FontWeight.w500, c: const Color(0xFF34D399))),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.track_changes_rounded,
                color: Color(0xFF34D399), size: 24),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final Color color;
  final VoidCallback onAddMoney, onDelete;
  const _GoalCard({
    required this.goal,
    required this.color,
    required this.onAddMoney,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal.progress;
    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: KColors.dangerBg,
          borderRadius: BorderRadius.circular(rCardLg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: KColors.danger),
      ),
      child: KCard(
        radius: rCardLg,
        padding: const EdgeInsets.all(18),
        onTap: onAddMoney,
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 38,
              lineWidth: 6,
              percent: pct.clamp(0.0, 1.0),
              backgroundColor: KColors.line,
              progressColor: color,
              circularStrokeCap: CircularStrokeCap.round,
              center: Icon(GoalIcons.data(goal.icon), color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k(15, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                              Money.plain(goal.currentAmount, currency: 'UZS'),
                              style: k(18, w: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text("so'm", style: k(12, c: KColors.mut)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(pct * 100).round()}% · ${Money.plain(goal.targetAmount, currency: 'UZS')} so\'m maqsad',
                    style: k(11.5, w: FontWeight.w500, c: KColors.mut),
                  ),
                  const SizedBox(height: 8),
                  KProgressBar(pct: pct, color: color, height: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kichik yordamchilar ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool number;
  final String? suffix;
  const _Field({
    required this.controller,
    required this.label,
    this.number = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          number ? const TextInputType.numberWithOptions(decimal: true) : null,
      inputFormatters: number ? Money.amountFormatters : null,
      style: k(15),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: KColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rTile),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _PrimaryButton(
      {required this.label, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? null : double.infinity,
        height: compact ? 44 : 54,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 22) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: kGradient,
          borderRadius: BorderRadius.circular(rBtn),
        ),
        child: Text(label, style: k(15, w: FontWeight.w600, c: Colors.white)),
      ),
    );
  }
}
