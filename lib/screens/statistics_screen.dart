import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../utils/wallets.dart';
import '../widgets/ui_kit.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currency = Wallets.uzs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final c = context.c;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(title: s('statistics')),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Row(
                    children: Wallets.currencies.map((cur) {
                      final selected = cur == _currency;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _currency = cur),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brand.withValues(alpha: 0.13)
                                  : c.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brand
                                    : Colors.transparent,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Wallets.currencyIcon(cur),
                                    size: 15,
                                    color: selected
                                        ? AppColors.brand
                                        : c.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  cur == Wallets.usd ? 'Dollar' : "So'm",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.brand
                                          : c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: c.textPrimary,
                      unselectedLabelColor: c.textSecondary,
                      labelStyle: context.t.titleSmall,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      splashBorderRadius: BorderRadius.circular(AppRadius.sm),
                      indicator: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: AppShadows.card(context.isDark),
                      ),
                      tabs: [
                        Tab(text: s('chart')),
                        Tab(text: s('categories')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ChartTab(provider: provider, currency: _currency),
                      _CategoriesTab(provider: provider, currency: _currency),
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
}

// ── TAB 1: Bar chart ─────────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  const _ChartTab({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final months = kMonthNames[provider.language] ?? kMonthNames['uz']!;
    final monthData = provider.last6MonthsData(currency);
    final maxY = monthData
            .expand((d) => [d['income'] as double, d['expense'] as double])
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.25;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: s('this_month_income'),
                value: Money.format(
                    provider.incomeThisMonth(currency), currency),
                color: AppColors.income,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: s('this_month_expense'),
                value: Money.format(
                    provider.expenseThisMonth(currency), currency),
                color: AppColors.expense,
                icon: Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionTitle(s('last_6_months')),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 12, 12),
          child: provider.transactions.isEmpty
              ? SizedBox(
                  height: 200,
                  child: EmptyState(
                      icon: Icons.bar_chart_rounded, title: s('no_data')),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY > 0 ? maxY : 1000000,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.lTextPrimary,
                            getTooltipItem: (group, _, rod, rodIndex) =>
                                BarTooltipItem(
                              '${rodIndex == 0 ? s('income') : s('expense')}\n${Money.compact(rod.toY, currency)}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              getTitlesWidget: (val, _) {
                                final i = val.toInt();
                                if (i < 0 || i >= monthData.length) {
                                  return const SizedBox();
                                }
                                final d = monthData[i]['month'] as DateTime;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(months[d.month - 1],
                                      style: context.t.bodySmall),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: context.c.border,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: monthData.asMap().entries.map((e) {
                          return BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(
                              toY: e.value['income'] as double,
                              color: AppColors.income,
                              width: 9,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: e.value['expense'] as double,
                              color: AppColors.expense,
                              width: 9,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ]);
                        }).toList(),
                      )),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Legend(color: AppColors.income, label: s('income')),
                        const SizedBox(width: 22),
                        _Legend(
                            color: AppColors.expense, label: s('expense')),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── TAB 2: Kategoriyalar ──────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  const _CategoriesTab({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final expCat = provider.expenseByCategory(currency);
    final total = expCat.values.fold(0.0, (a, b) => a + b);
    final sorted = expCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (expCat.isEmpty) {
      return EmptyState(
          icon: Icons.donut_large_rounded, title: s('no_data'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, 24),
      children: [
        SectionTitle(s('expense_by_category')),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 62,
                  sections: sorted.map((e) {
                    return PieChartSectionData(
                      value: e.value,
                      title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                      color: CategoryMeta.color(e.key),
                      radius: 26,
                      titlePositionPercentageOffset: 1.5,
                      titleStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.c.textSecondary),
                    );
                  }).toList(),
                )),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s('expense'), style: context.t.bodySmall),
                    const SizedBox(height: 2),
                    Text(Money.compact(total, currency),
                        style: context.t.titleMedium),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final pct = e.value / total;
          final color = CategoryMeta.color(e.key);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.c.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.c.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconBadge(
                        icon: CategoryMeta.icon(e.key),
                        color: color,
                        size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.cat(e.key), style: context.t.titleSmall),
                    ),
                    Text(Money.format(e.value, currency),
                        style: context.t.titleSmall),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: context.c.surfaceAlt,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: context.t.bodySmall),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Yordamchi widgetlar ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(label, style: context.t.bodySmall),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 7),
          Text(label, style: context.t.bodySmall),
        ],
      );
}
