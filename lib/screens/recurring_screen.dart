import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recurring_model.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';

/// Takroriy to'lovlar — oylik maosh, ijara, obuna kabi takrorlanuvchi amallar.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  static const _freqKey = {
    'daily': 'freq_daily',
    'weekly': 'freq_weekly',
    'monthly': 'freq_monthly',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = provider.recurring;
        return Scaffold(
          backgroundColor: KColors.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      const KBackButton(),
                      Expanded(
                        child: Center(
                          child: Text(provider.s('recurring'),
                              style: k(17, w: FontWeight.w600)),
                        ),
                      ),
                      KAddButton(onTap: () => _showAddSheet(context, provider)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: items.isEmpty
                      ? _empty(context, provider)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecurRow(
                              item: items[i],
                              strings: provider.s,
                              freqLabel:
                                  provider.s(_freqKey[items[i].frequency] ?? ''),
                              onDelete: () =>
                                  provider.deleteRecurring(items[i].id),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context, AppProvider provider) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_repeat_rounded, size: 48, color: KColors.mut),
              const SizedBox(height: 14),
              Text(provider.s('no_recurring'),
                  style: k(15, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(provider.s('no_recurring_desc'),
                  textAlign: TextAlign.center,
                  style: k(12.5, c: KColors.sub, height: 1.4)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _showAddSheet(context, provider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                      gradient: kGradient,
                      borderRadius: BorderRadius.circular(rBtn)),
                  child: Text(provider.s('add_money'),
                      style: k(14, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );

  void _showAddSheet(BuildContext context, AppProvider provider) {
    final s = provider.s;
    String type = 'expense';
    String category = s.expenseCategoryKeys.first;
    String place = 'card';
    String currency = 'UZS';
    String freq = 'monthly';
    DateTime start = DateTime.now();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setM) {
            final cats =
                type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys;
            if (!cats.contains(category)) category = cats.first;
            return Padding(
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
                    Text(s('new_recurring'),
                        style: k(18, w: FontWeight.w700)),
                    const SizedBox(height: 16),

                    _seg(
                      [('expense', s('chiqim')), ('income', s('kirim'))],
                      type,
                      (v) => setM(() {
                        type = v;
                        category = (v == 'income'
                                ? s.incomeCategoryKeys
                                : s.expenseCategoryKeys)
                            .first;
                      }),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: Money.amountFormatters,
                      style: k(16),
                      decoration: _dec(s('amount'),
                          suffix: currency == 'USD' ? '\$' : s('som')),
                    ),
                    const SizedBox(height: 14),

                    _label(s('category')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.map((key) {
                        final sel = key == category;
                        final cc = CategoryMeta.color(key);
                        return GestureDetector(
                          onTap: () => setM(() => category = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 8),
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
                                    size: 15, color: sel ? cc : KColors.sub),
                                const SizedBox(width: 6),
                                Text(s.cat(key),
                                    style: k(12.5,
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
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _seg(
                            [('cash', s('wallet_cash')), ('card', s('wallet_card'))],
                            place,
                            (v) => setM(() => place = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _seg(
                            [('UZS', s('som')), ('USD', '\$')],
                            currency,
                            (v) => setM(() => currency = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _label(s('frequency')),
                    _seg(
                      [
                        ('daily', s('freq_daily')),
                        ('weekly', s('freq_weekly')),
                        ('monthly', s('freq_monthly')),
                      ],
                      freq,
                      (v) => setM(() => freq = v),
                    ),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: start,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 3650)),
                        );
                        if (p != null) setM(() => start = p);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                            color: KColors.bg,
                            borderRadius: BorderRadius.circular(rTile)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 18, color: KColors.sub),
                            const SizedBox(width: 12),
                            Text(
                                '${s('start_date')}: ${DateFmt.short(start)}',
                                style: k(14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        final amount = Money.parse(amountCtrl.text);
                        if (amount == null || amount <= 0) return;
                        final d = DateTime(start.year, start.month, start.day);
                        provider.addRecurring(RecurringModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          type: type,
                          amount: amount,
                          category: category,
                          place: place,
                          currency: currency,
                          note: noteCtrl.text.trim(),
                          frequency: freq,
                          nextDate: d,
                        ));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            gradient: kGradient,
                            borderRadius: BorderRadius.circular(rBtn)),
                        child: Text(s('save'),
                            style:
                                k(16, w: FontWeight.w600, c: Colors.white)),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: k(13, w: FontWeight.w600, c: KColors.sub)),
      );

  static InputDecoration _dec(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: KColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rTile),
          borderSide: BorderSide.none,
        ),
      );

  static Widget _seg(List<(String, String)> options, String value,
      ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KColors.isDark
            ? const Color(0xFF23262F)
            : const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(rTile),
      ),
      child: Row(
        children: options.map((o) {
          final active = o.$1 == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? KColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(rTile - 3),
                  boxShadow: active ? kSoftShadow : null,
                ),
                child: Text(o.$2,
                    style: k(13.5,
                        w: active ? FontWeight.w600 : FontWeight.w500,
                        c: active ? KColors.ink : KColors.sub)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecurRow extends StatelessWidget {
  final RecurringModel item;
  final dynamic strings;
  final String freqLabel;
  final VoidCallback onDelete;
  const _RecurRow({
    required this.item,
    required this.strings,
    required this.freqLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'income';
    final color = CategoryMeta.color(item.category);
    final title =
        item.note.isNotEmpty ? item.note : strings.cat(item.category);
    final signed = isIncome ? item.amount : -item.amount;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
            color: KColors.dangerBg,
            borderRadius: BorderRadius.circular(rCard)),
        child: const Icon(Icons.delete_outline_rounded, color: KColors.danger),
      ),
      child: KCard(
        child: Row(
          children: [
            KTintedIcon(
                icon: CategoryMeta.icon(item.category), color: color, size: 44),
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
                  Text('$freqLabel · ${DateFmt.short(item.nextDate)}',
                      style: k(11.5, c: KColors.mut)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.format(signed, item.currency, showSign: true),
              style: k(15,
                  w: FontWeight.w600,
                  c: isIncome ? KColors.primary : KColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
