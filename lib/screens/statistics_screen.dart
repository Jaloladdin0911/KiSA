import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';
import '../widgets/movement_sheet.dart';

/// Statistika — davr (hafta/oy/yil) va tur (chiqim/kirim) bo'yicha:
/// interaktiv donut, avvalgi davr bilan solishtirish, 6 oylik dinamika va
/// kategoriyalar. Barcha summalar so'mda (USD — CBU kursi bo'yicha).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'month'; // week | month | year
  String _type = 'expense'; // expense | income
  int? _touched; // donutda tanlangan bo'lak

  /// Joriy va avvalgi davr chegaralari: [from, to).
  ({DateTime from, DateTime to, DateTime prevFrom}) _range() {
    final n = DateTime.now();
    switch (_period) {
      case 'week':
        final from = DateTime(n.year, n.month, n.day - 6);
        return (
          from: from,
          to: DateTime(n.year, n.month, n.day + 1),
          prevFrom: DateTime(from.year, from.month, from.day - 7),
        );
      case 'year':
        return (
          from: DateTime(n.year),
          to: DateTime(n.year + 1),
          prevFrom: DateTime(n.year - 1),
        );
      default:
        return (
          from: DateTime(n.year, n.month),
          to: DateTime(n.year, n.month + 1),
          prevFrom: DateTime(n.year, n.month - 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final r = _range();
        final map = provider.categoryTotals(_type, r.from, r.to);
        final total = map.values.fold(0.0, (a, b) => a + b);
        final prevTotal = provider
            .categoryTotals(_type, r.prevFrom, r.from)
            .values
            .fold(0.0, (a, b) => a + b);
        final count = provider.inRange(_type, r.from, r.to).length;
        final days = DateTime.now().difference(r.from).inDays + 1;
        final sorted = map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final accent = _type == 'expense' ? KColors.danger : KColors.primary;
        if (_touched != null && _touched! >= sorted.length) _touched = null;

        final sections = <Widget>[
          KPageHeader(title: s('statistics'), subtitle: s('stats_subtitle')),
          KSegmented(
            options: [
              ('week', s('period_week')),
              ('month', s('period_month')),
              ('year', s('period_year')),
            ],
            value: _period,
            onChanged: (v) => setState(() {
              _period = v;
              _touched = null;
            }),
          ),
          KSegmented(
            options: [('expense', s('chiqim')), ('income', s('kirim'))],
            colors: const [KColors.danger, KColors.primary],
            value: _type,
            height: 36,
            onChanged: (v) => setState(() {
              _type = v;
              _touched = null;
            }),
          ),
          _DonutCard(
            entries: sorted,
            total: total,
            touched: _touched,
            emptyText: s('no_data'),
            totalLabel: _type == 'expense' ? s('total_spent') : s('total_earned'),
            som: s('som'),
            catName: s.cat,
            onTouch: (i) => setState(() => _touched = i),
          ),
          _Insights(
            change: prevTotal > 0 ? (total - prevTotal) / prevTotal * 100 : null,
            // Chiqim oshishi — yomon (qizil), kirim oshishi — yaxshi (yashil)
            upIsGood: _type == 'income',
            dailyAvg: total / days,
            count: count,
          ),
          _TrendCard(data: provider.monthlyTotals()),
          Text(s('by_category'), style: k(17, w: FontWeight.w700)),
          if (sorted.isEmpty)
            Text(_type == 'expense' ? s('no_expense_period') : s('no_income_period'),
                style: k(13, c: KColors.mut))
          else
            KCard(
              radius: rCardLg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    _BreakdownRow(
                      name: s.cat(sorted[i].key),
                      category: sorted[i].key,
                      amount: sorted[i].value,
                      pct: total > 0 ? sorted[i].value / total : 0.0,
                      highlighted: _touched == i,
                      accent: accent,
                      onTap: () => _categorySheet(
                          context, provider, sorted[i].key, r.from, r.to),
                    ),
                    if (i != sorted.length - 1)
                      Divider(height: 1, thickness: 1, color: KColors.line),
                  ],
                ],
              ),
            ),
        ];

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(top: 6, bottom: 130),
            children: [
              for (var i = 0; i < sections.length; i++)
                Padding(
                  padding: EdgeInsets.fromLTRB(20, i == 0 ? 0 : 16, 20, 0),
                  child: KFadeSlideIn.stagger(i, child: sections[i]),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Kategoriya bosilganda — shu davrdagi uning amallari.
  void _categorySheet(BuildContext context, AppProvider provider,
      String category, DateTime from, DateTime to) {
    final s = provider.s;
    final txs = provider.inRange(_type, from, to, category: category).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total =
        txs.fold(0.0, (sum, t) => sum + provider.toUzs(t.amount, t.currency));
    final color = CategoryMeta.color(category);

    showKSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KSheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    KTintedIcon(icon: CategoryMeta.icon(category), color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.cat(category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: k(17, w: FontWeight.w700)),
                          Text('${txs.length} ${s('tx_count').toLowerCase()}',
                              style: k(12.5, c: KColors.mut)),
                        ],
                      ),
                    ),
                    Text('${Money.plain(total, currency: 'UZS')} ${s('som')}',
                        style: k(15, w: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: txs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, thickness: 1, color: KColors.line),
                    itemBuilder: (_, i) {
                      final t = txs[i];
                      return KPressable(
                        scale: 0.98,
                        onTap: () {
                          Navigator.pop(ctx);
                          openTransaction(context, t);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        t.note.isNotEmpty
                                            ? t.note
                                            : s.cat(t.category),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: k(14, w: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(DateFmt.short(t.date),
                                        style: k(11.5, c: KColors.mut)),
                                  ],
                                ),
                              ),
                              Text(Money.format(t.amount, t.currency),
                                  style: k(14.5, w: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Donut ───────────────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final double total;
  final int? touched;
  final String emptyText, totalLabel, som;
  final String Function(String) catName;
  final ValueChanged<int?> onTouch;

  const _DonutCard({
    required this.entries,
    required this.total,
    required this.touched,
    required this.emptyText,
    required this.totalLabel,
    required this.som,
    required this.catName,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final sel = touched != null ? entries[touched!] : null;
    return KCard(
      radius: rCardLg,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        height: 212,
        child: total == 0
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.donut_large_rounded,
                        size: 40, color: KColors.mut.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    Text(emptyText, style: k(14, c: KColors.mut)),
                  ],
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Ochilishda donut aylanib, to'lib chiqadi
                  TweenAnimationBuilder<double>(
                    key: ValueKey(entries.length),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: KMotion.emphasized,
                    builder: (_, t, __) => Transform.rotate(
                      angle: (1 - t) * -1.2,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 68,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, res) {
                                if (event is! FlTapUpEvent) return;
                                final i =
                                    res?.touchedSection?.touchedSectionIndex;
                                onTouch(i == null || i < 0 || i == touched
                                    ? null
                                    : i);
                              },
                            ),
                            sections: [
                              for (var i = 0; i < entries.length; i++)
                                PieChartSectionData(
                                  value: entries[i].value,
                                  color: CategoryMeta.color(entries[i].key)
                                      .withValues(
                                          alpha: touched == null || touched == i
                                              ? 1
                                              : 0.35),
                                  radius: touched == i ? 34 : 26,
                                  showTitle: false,
                                ),
                            ],
                          ),
                          duration: KMotion.medium,
                          curve: KMotion.emphasized,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: KMotion.fast,
                      child: Column(
                        key: ValueKey(touched),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel != null) ...[
                            Icon(CategoryMeta.icon(sel.key),
                                size: 18, color: CategoryMeta.color(sel.key)),
                            const SizedBox(height: 4),
                          ],
                          SizedBox(
                            width: 120,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  Money.plain(sel?.value ?? total,
                                      currency: 'UZS'),
                                  style: k(22, w: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 120,
                            child: Text(
                                sel != null
                                    ? '${catName(sel.key)} · ${(sel.value / total * 100).round()}%'
                                    : '$totalLabel · $som',
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: k(11.5,
                                    w: FontWeight.w500, c: KColors.sub)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Tushunchalar (insights) ───────────────────────────────────────────────────

class _Insights extends StatelessWidget {
  final double? change; // % avvalgi davrga nisbatan
  final bool upIsGood;
  final double dailyAvg;
  final int count;

  const _Insights({
    required this.change,
    required this.upIsGood,
    required this.dailyAvg,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    final c = change;
    final good = c == null || c == 0 ? null : (c > 0) == upIsGood;
    final changeColor = good == null
        ? KColors.sub
        : (good ? KColors.primary : KColors.danger);

    Widget tile(IconData icon, Color color, String value, String label) =>
        Expanded(
          child: KCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: k(16, w: FontWeight.w700, c: color == KColors.sub
                          ? KColors.ink
                          : color)),
                ),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: k(11, c: KColors.mut, height: 1.25)),
              ],
            ),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(
          c == null
              ? Icons.horizontal_rule_rounded
              : (c >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          changeColor,
          c == null ? '—' : '${c >= 0 ? '+' : '−'}${c.abs().toStringAsFixed(0)}%',
          s('vs_prev_period'),
        ),
        const SizedBox(width: 10),
        tile(Icons.calendar_view_day_rounded, KColors.blue,
            Money.compact(dailyAvg, 'UZS'), s('daily_avg')),
        const SizedBox(width: 10),
        tile(Icons.receipt_long_rounded, KColors.purple, '$count',
            s('tx_count')),
      ],
    );
  }
}

// ── 6 oylik dinamika ─────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final List<({DateTime month, double income, double expense})> data;
  const _TrendCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    final maxV = data.fold<double>(
        0, (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b));
    final top = maxV <= 0 ? 1.0 : maxV * 1.15;

    Widget legend(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label, style: k(11.5, c: KColors.sub)),
          ],
        );

    return KCard(
      radius: rCardLg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s('trend_6m'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k(15, w: FontWeight.w700)),
              ),
              legend(KColors.primary, s('kirim')),
              const SizedBox(width: 10),
              legend(KColors.danger, s('chiqim')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            // Ustunlar pastdan o'sib chiqadi
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: KMotion.emphasized,
              builder: (_, t, __) => BarChart(
                BarChartData(
                  maxY: top,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: top / 3,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: KColors.line, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              s.monthsShort[data[v.toInt()].month.month - 1],
                              style: k(10.5, c: KColors.mut)),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => KColors.sheet,
                      tooltipRoundedRadius: 10,
                      getTooltipItem: (group, _, rod, rodIndex) =>
                          BarTooltipItem(
                        Money.compact(rodIndex == 0
                            ? data[group.x].income
                            : data[group.x].expense, 'UZS'),
                        k(11.5,
                            w: FontWeight.w600,
                            c: rodIndex == 0 ? KColors.primary : KColors.danger),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          _rod(data[i].income * t, KColors.primary),
                          _rod(data[i].expense * t, KColors.danger),
                        ],
                      ),
                  ],
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartRodData _rod(double v, Color c) => BarChartRodData(
        toY: v,
        width: 9,
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [c.withValues(alpha: 0.55), c],
        ),
      );
}

// ── Kategoriya qatori ───────────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  final String name, category;
  final double amount, pct;
  final bool highlighted;
  final Color accent;
  final VoidCallback onTap;

  const _BreakdownRow({
    required this.name,
    required this.category,
    required this.amount,
    required this.pct,
    required this.highlighted,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryMeta.color(category);
    return KPressable(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: KMotion.medium,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: highlighted ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(rTile),
        ),
        child: Row(
          children: [
            KTintedIcon(
                icon: CategoryMeta.icon(category),
                color: color,
                size: 38,
                circle: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k(14, w: FontWeight.w600)),
                      ),
                      Text(Money.compact(amount, 'UZS'),
                          style: k(14, w: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: KMotion.emphasized,
                          builder: (_, v, __) => KProgressBar(
                              pct: v, color: color, height: 5, track: KColors.bg),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Text('${(pct * 100).round()}%',
                            textAlign: TextAlign.end,
                            style: k(11.5, w: FontWeight.w600, c: KColors.sub)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: KColors.mut),
          ],
        ),
      ),
    );
  }
}

