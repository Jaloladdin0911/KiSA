import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';

/// Byudjet — KISA_DESIGN_SPEC.md, Section 8. Real: kategoriya byudjetlari
/// (qo'shish/tahrirlash/o'chirish) + bu oy xarajatlari bilan solishtirish.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const _months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final budgets = provider.categoryBudgets;
        final hasBudgets = budgets.isNotEmpty;

        final limit =
            hasBudgets ? provider.totalCategoryBudget : provider.monthlyBudget;
        final spent = hasBudgets
            ? budgets.keys
                .fold(0.0, (s, c) => s + provider.categorySpentThisMonth(c))
            : provider.expenseThisMonth('UZS');
        final remaining = (limit - spent).clamp(0, double.infinity).toDouble();
        final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

        final entries = budgets.entries.toList()
          ..sort((a, b) {
            final pa = provider.categorySpentThisMonth(a.key) / a.value;
            final pb = provider.categorySpentThisMonth(b.key) / b.value;
            return pb.compareTo(pa);
          });

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: kPad,
                child: KPageHeader(
                  title: 'Byudjet',
                  subtitle: '${_months[now.month - 1]} oyi · $daysInMonth kun',
                  trailing:
                      KAddButton(onTap: () => _editSheet(context, provider)),
                ),
              ),
              const SizedBox(height: 18),

              Padding(
                padding: kPad,
                child: _Hero(
                    remaining: remaining, spent: spent, limit: limit, pct: pct),
              ),
              const SizedBox(height: 22),

              Padding(
                padding: kPad,
                child: Row(
                  children: [
                    Text('Kategoriyalar', style: k(16, w: FontWeight.w600)),
                    const Spacer(),
                    if (hasBudgets)
                      GestureDetector(
                        onTap: () => _editSheet(context, provider),
                        child: Text('Tahrirlash',
                            style:
                                k(13, w: FontWeight.w600, c: KColors.primary)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (!hasBudgets)
                Padding(
                  padding: kPad,
                  child: KCard(
                    radius: rCardLg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 40, color: KColors.mut),
                        const SizedBox(height: 12),
                        Text('Hali byudjet yo\'q',
                            style: k(15, w: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            'Kategoriyalarga oylik limit qo\'shing va xarajatni nazorat qiling',
                            textAlign: TextAlign.center,
                            style: k(12.5, c: KColors.sub, height: 1.4)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _editSheet(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: kGradient,
                              borderRadius: BorderRadius.circular(rBtn),
                            ),
                            child: Text('Byudjet qo\'shish',
                                style: k(14,
                                    w: FontWeight.w600, c: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...entries.map((e) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _BudgetRow(
                        category: e.key,
                        limit: e.value,
                        spent: provider.categorySpentThisMonth(e.key),
                        name: provider.s.cat(e.key),
                        onTap: () => _editSheet(context, provider,
                            category: e.key, current: e.value),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  void _editSheet(BuildContext context, AppProvider provider,
      {String? category, double? current}) {
    final isEdit = category != null;
    final s = provider.s;
    String selected = category ?? s.expenseCategoryKeys.first;
    final amountCtrl = TextEditingController(
        text: current != null ? Money.plain(current, currency: 'UZS') : '');

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
                  Text(isEdit ? s.cat(selected) : 'Byudjet qo\'shish',
                      style: k(18, w: FontWeight.w700)),
                  const SizedBox(height: 16),

                  if (!isEdit) ...[
                    Text('Kategoriya',
                        style: k(13, w: FontWeight.w600, c: KColors.sub)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: s.expenseCategoryKeys.map((key) {
                        final sel = key == selected;
                        final cc = CategoryMeta.color(key);
                        return GestureDetector(
                          onTap: () => setM(() => selected = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color:
                                  sel ? cc.withValues(alpha: 0.14) : KColors.bg,
                              borderRadius: BorderRadius.circular(rTile),
                              border: Border.all(
                                  color: sel ? cc : Colors.transparent,
                                  width: 1.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CategoryMeta.icon(key),
                                    size: 16,
                                    color: sel ? cc : KColors.sub),
                                const SizedBox(width: 6),
                                Text(s.cat(key),
                                    style: k(13,
                                        w: sel
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        c: sel ? cc : KColors.sub)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Oylik limit',
                      style: k(13, w: FontWeight.w600, c: KColors.sub)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: Money.amountFormatters,
                    style: k(16),
                    decoration: InputDecoration(
                      suffixText: "so'm",
                      filled: true,
                      fillColor: KColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(rTile),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      if (isEdit) ...[
                        GestureDetector(
                          onTap: () {
                            provider.deleteCategoryBudget(category);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: KColors.dangerBg,
                              borderRadius: BorderRadius.circular(rBtn),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: KColors.danger),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final amount = Money.parse(amountCtrl.text);
                            if (amount == null || amount <= 0) return;
                            provider.setCategoryBudget(selected, amount);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: kGradient,
                              borderRadius: BorderRadius.circular(rBtn),
                            ),
                            child: Text('Saqlash',
                                style: k(16,
                                    w: FontWeight.w600, c: Colors.white)),
                          ),
                        ),
                      ),
                    ],
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
}

class _Hero extends StatelessWidget {
  final double remaining, spent, limit, pct;
  const _Hero({
    required this.remaining,
    required this.spent,
    required this.limit,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final w90 = Colors.white.withValues(alpha: 0.9);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.circular(rCardLg),
        boxShadow: kGreenShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qolgan mablag'",
                        style: k(13, w: FontWeight.w500, c: w90)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(Money.plain(remaining, currency: 'UZS'),
                                style:
                                    k(28, w: FontWeight.w700, c: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text("so'm",
                              style: k(14, w: FontWeight.w500, c: w90)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                    height: 8, color: Colors.white.withValues(alpha: 0.28)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 8, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Sarflandi: ${Money.plain(spent, currency: 'UZS')}',
                  style: k(12, w: FontWeight.w500, c: w90)),
              const Spacer(),
              Text('Limit: ${Money.plain(limit, currency: 'UZS')}',
                  style: k(12, w: FontWeight.w500, c: w90)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String category, name;
  final double limit, spent;
  final VoidCallback onTap;
  const _BudgetRow({
    required this.category,
    required this.name,
    required this.limit,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? spent / limit : 0.0;
    final over = pct > 1.0;
    final color = CategoryMeta.color(category);
    final pctColor = over ? KColors.danger : color;

    return KCard(
      onTap: onTap,
      child: Row(
        children: [
          KTintedIcon(
              icon: CategoryMeta.icon(category), color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: k(14, w: FontWeight.w600)),
                    const Spacer(),
                    Text('${(pct * 100).round()}%',
                        style: k(13, w: FontWeight.w600, c: pctColor)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  over
                      ? 'Limitdan oshgan'
                      : '${Money.plain(spent, currency: 'UZS')} / ${Money.plain(limit, currency: 'UZS')}',
                  style: k(12, c: over ? KColors.danger : KColors.mut),
                ),
                const SizedBox(height: 8),
                KProgressBar(pct: pct, color: color, height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
