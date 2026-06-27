import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';
import 'add_transaction_screen.dart';

/// Tranzaksiyalar tarixi — KISA_DESIGN_SPEC.md, Section 11.
/// Qidiruv + filtr chiplar + sana bo'yicha guruhlangan ro'yxat.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // all | income | expense | today
  String _query = '';

  static const _monthsUpper = [
    'YAN', 'FEV', 'MAR', 'APR', 'MAY', 'IYUN',
    'IYUL', 'AVG', 'SEN', 'OKT', 'NOY', 'DEK',
  ];

  bool _matchesFilter(TransactionModel t) {
    switch (_filter) {
      case 'income':
        return t.type == 'income';
      case 'expense':
        return t.type == 'expense';
      case 'today':
        final n = DateTime.now();
        return t.date.year == n.year &&
            t.date.month == n.month &&
            t.date.day == n.day;
      default:
        return true;
    }
  }

  bool _matchesQuery(TransactionModel t, AppProvider p) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.note.toLowerCase().contains(q) ||
        p.s.cat(t.category).toLowerCase().contains(q);
  }

  String _groupLabel(DateTime d) {
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) {
      return 'BUGUN';
    }
    final y = n.subtract(const Duration(days: 1));
    if (d.year == y.year && d.month == y.month && d.day == y.day) {
      return 'KECHA';
    }
    return '${d.day}-${_monthsUpper[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.transactions
        .where((t) => _matchesFilter(t) && _matchesQuery(t, provider))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Sana (kun) bo'yicha guruhlash
    final groups = <String, List<TransactionModel>>{};
    for (final t in items) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(t);
    }
    final groupKeys = groups.keys.toList();

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
                      child: Text('Tranzaksiyalar',
                          style: k(17, w: FontWeight.w600)),
                    ),
                  ),
                  KIconButton(
                      icon: Icons.tune_rounded, onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Qidiruv
            Padding(
              padding: kPad,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: KColors.card,
                  borderRadius: BorderRadius.circular(rCard),
                  boxShadow: kSoftShadow,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 20, color: KColors.mut),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: k(14),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Qidirish...',
                          hintStyle: k(14, c: KColors.mut),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Filtr chiplar
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: kPad,
                children: [
                  _chip('all', 'Hammasi'),
                  _chip('income', 'Kirim'),
                  _chip('expense', 'Chiqim'),
                  _chip('today', 'Bugun'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ro'yxat
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text("Tranzaksiya topilmadi",
                          style: k(14, c: KColors.mut)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: groupKeys.length,
                      itemBuilder: (_, gi) {
                        final rows = groups[groupKeys[gi]]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 6, 20, 8),
                              child: Text(_groupLabel(rows.first.date),
                                  style: k(11,
                                      w: FontWeight.w600, c: KColors.mut, ls: 0.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                              child: KCard(
                                radius: rCard,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < rows.length; i++) ...[
                                      _Row(tx: rows[i], provider: provider),
                                      if (i != rows.length - 1)
                                        Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: KColors.line),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? KColors.primary : KColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? KColors.primary : KColors.line, width: 1),
          ),
          child: Text(label,
              style: k(13,
                  w: FontWeight.w600,
                  c: active ? Colors.white : KColors.sub)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final TransactionModel tx;
  final AppProvider provider;
  const _Row({required this.tx, required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final t = tx;
    final isIncome = t.type == 'income';

    final IconData icon;
    final Color color;
    final String title;
    final String meta;
    final String amountStr;
    final Color amountColor;

    final time =
        '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}';

    if (t.isMovement) {
      icon = t.type == 'exchange'
          ? Icons.currency_exchange_rounded
          : Icons.swap_horiz_rounded;
      color = KColors.purple;
      title = s(t.type);
      meta = time;
      amountStr = Money.format(t.amount, t.currency);
      amountColor = KColors.sub;
    } else {
      icon = CategoryMeta.icon(t.category);
      color = CategoryMeta.color(t.category);
      title = t.note.isNotEmpty ? t.note : s.cat(t.category);
      meta = '${s.cat(t.category)} · $time';
      final signed = isIncome ? t.amount : -t.amount;
      amountStr = Money.format(signed, t.currency, showSign: true);
      amountColor = isIncome ? KColors.primary : KColors.ink;
    }

    return GestureDetector(
      onTap: () {
        if (!t.isMovement) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddTransactionScreen(existing: t),
          ));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k(14, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k(11.5, c: KColors.mut)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amountStr, style: k(15, w: FontWeight.w600, c: amountColor)),
          ],
        ),
      ),
    );
  }
}
