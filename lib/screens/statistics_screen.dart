import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';

/// Statistika — KISA_DESIGN_SPEC.md, Section 6. Donut + kategoriya breakdown,
/// real Hive ma'lumotidan (tanlangan davr bo'yicha xarajatlar).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'month'; // week | month | year

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_period) {
      case 'week':
        final from = now.subtract(const Duration(days: 7));
        return d.isAfter(from);
      case 'year':
        return d.year == now.year;
      default:
        return d.month == now.month && d.year == now.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Davr bo'yicha xarajatlarni kategoriya bo'yicha yig'amiz (UZS)
        final map = <String, double>{};
        for (final TransactionModel t in provider.transactions) {
          if (t.type == 'expense' && t.currency == 'UZS' && _inPeriod(t.date)) {
            map[t.category] = (map[t.category] ?? 0) + t.amount;
          }
        }
        final total = map.values.fold(0.0, (a, b) => a + b);
        final sorted = map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: kPad,
                child: KPageHeader(
                  title: provider.s('statistics'),
                  subtitle: provider.s('stats_subtitle'),
                  trailing: KIconButton(
                      icon: Icons.calendar_today_rounded,
                      onTap: () {}),
                ),
              ),
              const SizedBox(height: 18),

              // Segmented
              Padding(
                padding: kPad,
                child: _Segmented(
                  value: _period,
                  onChanged: (v) => setState(() => _period = v),
                ),
              ),
              const SizedBox(height: 20),

              // Donut card
              Padding(
                padding: kPad,
                child: KCard(
                  radius: rCardLg,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SizedBox(
                    height: 208,
                    child: total == 0
                        ? Center(
                            child: Text(provider.s('no_data'),
                                style: k(14, c: KColors.mut)))
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 70,
                                sections: sorted.map((e) {
                                  return PieChartSectionData(
                                    value: e.value,
                                    color: CategoryMeta.color(e.key),
                                    radius: 26,
                                    showTitle: false,
                                  );
                                }).toList(),
                              )),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(Money.plain(total, currency: 'UZS'),
                                      style: k(23, w: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                      "${provider.s('total_spent')} · ${provider.s('som')}",
                                      style: k(12,
                                          w: FontWeight.w500, c: KColors.sub)),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Padding(
                padding: kPad,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(provider.s('by_category'),
                      style: k(15, w: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              if (sorted.isEmpty)
                Padding(
                  padding: kPad,
                  child: Text(provider.s('no_expense_period'),
                      style: k(13, c: KColors.mut)),
                )
              else
                ...sorted.map((e) {
                  final pct = total > 0 ? e.value / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _BreakdownRow(
                      name: provider.s.cat(e.key),
                      amount: e.value,
                      pct: pct,
                      color: CategoryMeta.color(e.key),
                      som: provider.s('som'),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _Segmented extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _Segmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    Widget seg(String v, String label) {
      final active = v == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? KColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(rTile - 3),
              boxShadow: active ? kSoftShadow : null,
            ),
            child: Text(label,
                style: k(14,
                    w: active ? FontWeight.w600 : FontWeight.w500,
                    c: active ? KColors.ink : KColors.sub)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KColors.isDark
            ? const Color(0xFF23262F)
            : const Color(0xFFE6E9EF),
        borderRadius: BorderRadius.circular(rTile),
      ),
      child: Row(
        children: [
          seg('week', s('period_week')),
          seg('month', s('period_month')),
          seg('year', s('period_year')),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String name;
  final double amount, pct;
  final Color color;
  final String som;
  const _BreakdownRow({
    required this.name,
    required this.amount,
    required this.pct,
    required this.color,
    required this.som,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            Text(name, style: k(13.5, w: FontWeight.w600)),
            const Spacer(),
            Text('${(pct * 100).round()}%', style: k(13.5, w: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 23),
          child: Text("${Money.plain(amount, currency: 'UZS')} $som",
              style: k(11.5, c: KColors.mut)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 23),
          child: KProgressBar(pct: pct, color: color, height: 6),
        ),
      ],
    );
  }
}
