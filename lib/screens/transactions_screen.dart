import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/calc.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';
import '../widgets/movement_sheet.dart';

/// Tranzaksiyalar tarixi — KISA_DESIGN_SPEC.md, Section 11.
/// Qidiruv + filtr chiplar + sana bo'yicha guruhlangan ro'yxat.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // all | income | expense | movement | today
  String _query = '';
  String? _currency; // null = hammasi | 'UZS' | 'USD'
  String? _place; // null = hammasi | 'cash' | 'card'

  bool get _hasExtraFilter => _currency != null || _place != null;

  bool _matchesWallet(TransactionModel t) {
    // O'tkazmada manba yoki qabul qiluvchi hamyon mos kelsa yetarli
    final curs = {t.currency, if (t.toCurrency != null) t.toCurrency};
    final places = {t.place, if (t.toPlace != null) t.toPlace};
    return (_currency == null || curs.contains(_currency)) &&
        (_place == null || places.contains(_place));
  }

  bool _matchesFilter(TransactionModel t) {
    if (!_matchesWallet(t)) return false;
    switch (_filter) {
      case 'income':
        return t.type == 'income';
      case 'expense':
        return t.type == 'expense';
      case 'movement':
        return t.isSystem;
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
    final q = _query.toLowerCase().trim();
    // Raqam yozilsa — summa bo'yicha ham qidiradi ("150000" yoki "150 000")
    final digits = q.replaceAll(RegExp(r'[\s  ]'), '');
    final amountMatch = RegExp(r'^\d+([.,]\d+)?$').hasMatch(digits) &&
        Calc.trim(t.amount.abs()).contains(digits.replaceAll(',', '.'));
    return amountMatch ||
        t.note.toLowerCase().contains(q) ||
        p.s.cat(t.category).toLowerCase().contains(q);
  }

  String _groupLabel(DateTime d) {
    final s = context.read<AppProvider>().s;
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) {
      return s('today').toUpperCase();
    }
    final y = n.subtract(const Duration(days: 1));
    if (d.year == y.year && d.month == y.month && d.day == y.day) {
      return s('yesterday').toUpperCase();
    }
    return '${d.day}-${s.monthsShort[d.month - 1].toUpperCase()}';
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
      backgroundColor: Colors.transparent,
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
                      child: Text(provider.s('transactions'),
                          style: k(17, w: FontWeight.w600)),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      KIconButton(
                          icon: Icons.tune_rounded,
                          label: provider.s('filters'),
                          iconColor: _hasExtraFilter ? KColors.primary : null,
                          onTap: _filterSheet),
                      if (_hasExtraFilter)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: KColors.primary,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Qidiruv
            Padding(
              padding: kPad,
              child: Glass(
                blur: true,
                sigma: 16,
                borderRadius: BorderRadius.circular(rCard),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 48,
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
                          hintText: provider.s('search_hint'),
                          hintStyle: k(14, c: KColors.mut),
                        ),
                      ),
                    ),
                  ],
                  ),
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
                  _chip('all', provider.s('filter_all')),
                  _chip('income', provider.s('kirim')),
                  _chip('expense', provider.s('chiqim')),
                  _chip('movement', provider.s('filter_movement')),
                  _chip('today', provider.s('today')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ro'yxat
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(provider.s('not_found'),
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_groupLabel(rows.first.date),
                                        style: k(11,
                                            w: FontWeight.w600,
                                            c: KColors.mut,
                                            ls: 0.5)),
                                  ),
                                  // Kunlik sof natija (kirim − chiqim, so'mda)
                                  Builder(builder: (_) {
                                    var net = 0.0;
                                    for (final t in rows) {
                                      final v = provider.toUzs(t.amount, t.currency);
                                      if (t.type == 'income') net += v;
                                      if (t.type == 'expense') net -= v;
                                    }
                                    if (net == 0) return const SizedBox();
                                    final sign = net > 0 ? '+' : '';
                                    return Text(
                                        '$sign${Money.compact(net, 'UZS')}',
                                        style: k(11.5,
                                            w: FontWeight.w600,
                                            c: net > 0
                                                ? KColors.primary
                                                : KColors.sub));
                                  }),
                                ],
                              ),
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
                                      // Chapga surish — o'chirish (Bekor qilish bilan)
                                      Dismissible(
                                        key: ValueKey(rows[i].id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                              right: 6),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: KColors.dangerBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: KColors.danger),
                                          ),
                                        ),
                                        onDismissed: (_) =>
                                            deleteWithUndo(context, rows[i]),
                                        child: _Row(
                                            tx: rows[i], provider: provider),
                                      ),
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

  /// Valyuta va hamyon bo'yicha qo'shimcha filtr.
  void _filterSheet() {
    final s = context.read<AppProvider>().s;
    showKSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          void set(VoidCallback f) {
            setM(f);
            setState(() {});
          }

          Widget group(String title, String? value,
              List<(String?, String)> options, ValueChanged<String?> onSel) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: k(13, w: FontWeight.w600, c: KColors.sub)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      GestureDetector(
                        onTap: () => set(() => onSel(o.$1)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: value == o.$1 ? KColors.primary : KColors.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(o.$2,
                              style: k(13,
                                  w: FontWeight.w600,
                                  c: value == o.$1
                                      ? Colors.white
                                      : KColors.sub)),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Text(s('filters'), style: k(17, w: FontWeight.w700)),
                      const Spacer(),
                      if (_hasExtraFilter)
                        GestureDetector(
                          onTap: () => set(() {
                            _currency = null;
                            _place = null;
                          }),
                          child: Text(s('reset'),
                              style: k(13.5,
                                  w: FontWeight.w600, c: KColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  group(s('currency'), _currency, [
                    (null, s('filter_all')),
                    ('UZS', s('som')),
                    ('USD', '\$'),
                  ], (v) => _currency = v),
                  const SizedBox(height: 18),
                  group(s('account'), _place, [
                    (null, s('filter_all')),
                    ('cash', s('wallet_cash')),
                    ('card', s('wallet_card')),
                  ], (v) => _place = v),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
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

    if (t.isAdjust) {
      // Qoldiq tuzatish — ishorali summa, statistikaga kirmaydi
      icon = Icons.tune_rounded;
      color = KColors.indigo;
      title = s('balance_adjust');
      meta = time;
      amountStr = Money.format(t.amount, t.currency, showSign: true);
      amountColor = KColors.sub;
    } else if (t.isMovement) {
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
      onTap: () => openTransaction(context, t),
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
