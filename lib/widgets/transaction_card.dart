import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../l10n/app_strings.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../utils/wallets.dart';
import 'ui_kit.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final AppStrings strings;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.strings,
    this.onDelete,
    this.onTap,
  });

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return strings('today');
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return strings('yesterday');
    }
    return DateFmt.short(date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = transaction;

    // Leading ikonka + rang
    final IconData icon;
    final Color iconColor;
    final String title;
    final String subtitle;
    final Widget trailing;

    if (t.isMovement) {
      final fromLabel = strings(Wallets.placeKey(t.place));
      final toLabel = strings(Wallets.placeKey(t.toPlace ?? t.place));
      icon = t.type == 'exchange'
          ? Icons.currency_exchange_rounded
          : Icons.swap_horiz_rounded;
      iconColor = t.type == 'exchange' ? AppColors.violet : AppColors.info;
      title = strings(t.type);
      subtitle = '$fromLabel → $toLabel · ${_dateLabel(t.date)}';
      if (t.type == 'exchange') {
        trailing = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('−${Money.format(t.amount, t.currency)}',
                style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
            Text('+${Money.format(t.toAmount ?? t.amount, t.toCurrency ?? t.currency)}',
                style: const TextStyle(
                    color: AppColors.income,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
          ],
        );
      } else {
        trailing = Text(
          Money.format(t.amount, t.currency),
          style: TextStyle(
              color: c.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14.5),
        );
      }
    } else {
      final isIncome = t.type == 'income';
      icon = CategoryMeta.icon(t.category);
      iconColor = CategoryMeta.color(t.category);
      title = strings.cat(t.category);
      final wallet = strings(Wallets.placeKey(t.place));
      subtitle = t.note.isNotEmpty
          ? '${t.note} · $wallet · ${_dateLabel(t.date)}'
          : '$wallet · ${_dateLabel(t.date)}';
      trailing = Text(
        Money.format(isIncome ? t.amount : -t.amount, t.currency,
            showSign: true),
        style: TextStyle(
            color: isIncome ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w700,
            fontSize: 14.5),
      );
    }

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.expense),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border),
          ),
          child: Row(
          children: [
            IconBadge(icon: icon, color: iconColor, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.t.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
        ),
      ),
    );
  }
}

// ── Umumiy: segment tanlovi (joy / valyuta) ───────────────────────────────────

class _SegChoice extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final String Function(String) label;
  final IconData Function(String)? icon;
  final Color color;

  const _SegChoice({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    this.icon,
    this.color = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: options.map((o) {
        final selected = o == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.13) : c.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon!(o),
                        size: 16, color: selected ? color : c.textSecondary),
                    const SizedBox(width: 6),
                  ],
                  Text(label(o),
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? color : c.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _curLabel(String cur) => Money.symbols[cur] ?? cur;

// ── Markaziy + tugma uchun amal tanlash oynasi ────────────────────────────────

void showAddActionSheet(BuildContext context, AppProvider provider) {
  final s = provider.s;
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final actions = <(IconData, Color, String, VoidCallback)>[
        (Icons.arrow_downward_rounded, AppColors.income, s('income'),
            () => showAddTransactionModal(context, provider, 'income')),
        (Icons.arrow_upward_rounded, AppColors.expense, s('expense'),
            () => showAddTransactionModal(context, provider, 'expense')),
        (Icons.swap_horiz_rounded, AppColors.info, s('transfer'),
            () => showTransferModal(context, provider)),
        (Icons.currency_exchange_rounded, AppColors.violet, s('exchange'),
            () => showExchangeModal(context, provider)),
      ];

      Widget tile((IconData, Color, String, VoidCallback) a) {
        return Expanded(
          child: Material(
            color: a.$2.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.pop(ctx);
                a.$4();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: a.$2.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(color: a.$2, shape: BoxShape.circle),
                      child: Icon(a.$1, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(a.$3,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: a.$2)),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text(s('add_action'), style: ctx.t.titleLarge),
            const SizedBox(height: 18),
            Row(children: [
              tile(actions[0]),
              const SizedBox(width: 12),
              tile(actions[1]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              tile(actions[2]),
              const SizedBox(width: 12),
              tile(actions[3]),
            ]),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 18),
          ],
        ),
      );
    },
  );
}

// ── Tranzaksiya qo'shish modali (kirim / chiqim) ──────────────────────────────

void showAddTransactionModal(
    BuildContext context, AppProvider provider, String type,
    {TransactionModel? existing}) {
  final s = provider.s;
  final catKeys =
      type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys;

  final isEdit = existing != null;
  String selectedCategoryKey = isEdit && catKeys.contains(existing.category)
      ? existing.category
      : catKeys.first;
  String place = existing?.place ?? Wallets.cash;
  String currency = existing?.currency ??
      (provider.currency == Wallets.usd ? Wallets.usd : Wallets.uzs);
  final amountCtrl = TextEditingController(
    text: isEdit ? Money.plain(existing.amount, currency: existing.currency) : '',
  );
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  DateTime selectedDate = existing?.date ?? DateTime.now();

  final color = type == 'income' ? AppColors.income : AppColors.expense;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.c;
      return StatefulBuilder(
        builder: (context, setModal) => Padding(
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
                Row(
                  children: [
                    IconBadge(
                        icon: type == 'income'
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: color,
                        size: 40),
                    const SizedBox(width: 12),
                    Text(
                      isEdit
                          ? s('edit')
                          : (type == 'income'
                              ? s('add_income')
                              : s('add_expense')),
                      style: context.t.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Summa
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: Money.amountFormatters,
                  autofocus: !isEdit,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: color),
                  decoration: InputDecoration(
                    labelText: s('amount'),
                    suffixText: _curLabel(currency),
                    prefixIcon: Icon(Icons.payments_outlined, color: color),
                  ),
                ),
                const SizedBox(height: 18),

                // Hamyon: joy + valyuta
                Text(s('wallet'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                _SegChoice(
                  options: Wallets.places,
                  value: place,
                  onChanged: (v) => setModal(() => place = v),
                  label: (p) => s(Wallets.placeKey(p)),
                  icon: Wallets.placeIcon,
                  color: color,
                ),
                const SizedBox(height: 8),
                _SegChoice(
                  options: Wallets.currencies,
                  value: currency,
                  onChanged: (v) => setModal(() => currency = v),
                  label: _curLabel,
                  icon: Wallets.currencyIcon,
                  color: color,
                ),
                const SizedBox(height: 18),

                // Kategoriya
                Text(s('category'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: catKeys.map<Widget>((k) {
                    final selected = k == selectedCategoryKey;
                    final cc = CategoryMeta.color(k);
                    return GestureDetector(
                      onTap: () => setModal(() => selectedCategoryKey = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? cc.withValues(alpha: 0.14)
                              : c.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selected ? cc : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CategoryMeta.icon(k),
                                size: 16,
                                color: selected ? cc : c.textSecondary),
                            const SizedBox(width: 6),
                            Text(s.cat(k),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected ? cc : c.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Izoh
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: s('note_optional'),
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // Sana
                _DateField(
                  date: selectedDate,
                  onPick: (d) => setModal(() => selectedDate = d),
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    final amount = Money.parse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s('amount'))),
                      );
                      return;
                    }
                    final tx = TransactionModel(
                      id: existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: provider.userId,
                      type: type,
                      amount: amount,
                      category: selectedCategoryKey,
                      date: selectedDate,
                      note: noteCtrl.text.trim(),
                      place: place,
                      currency: currency,
                    );
                    if (isEdit) {
                      provider.updateTransaction(tx);
                    } else {
                      provider.addTransaction(tx);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? s('update') : s('save')),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 18),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ── O'tkazma modali (bir valyuta ichida naqd ↔ karta) ─────────────────────────

void showTransferModal(BuildContext context, AppProvider provider) {
  final s = provider.s;
  String currency = Wallets.uzs;
  String fromPlace = Wallets.cash;
  String toPlace = Wallets.card;
  final amountCtrl = TextEditingController();
  const color = AppColors.info;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModal) => Padding(
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
                Row(
                  children: [
                    const IconBadge(
                        icon: Icons.swap_horiz_rounded,
                        color: color,
                        size: 40),
                    const SizedBox(width: 12),
                    Text(s('add_transfer'), style: context.t.titleLarge),
                  ],
                ),
                const SizedBox(height: 22),

                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: Money.amountFormatters,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: color),
                  decoration: InputDecoration(
                    labelText: s('amount'),
                    suffixText: _curLabel(currency),
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: color),
                  ),
                ),
                const SizedBox(height: 18),

                Text(s('currency'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                _SegChoice(
                  options: Wallets.currencies,
                  value: currency,
                  onChanged: (v) => setModal(() => currency = v),
                  label: _curLabel,
                  icon: Wallets.currencyIcon,
                  color: color,
                ),
                const SizedBox(height: 18),

                Text(s('from_wallet'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                _SegChoice(
                  options: Wallets.places,
                  value: fromPlace,
                  onChanged: (v) => setModal(() {
                    fromPlace = v;
                    if (toPlace == fromPlace) {
                      toPlace = Wallets.places.firstWhere((p) => p != v);
                    }
                  }),
                  label: (p) => s(Wallets.placeKey(p)),
                  icon: Wallets.placeIcon,
                  color: color,
                ),
                const SizedBox(height: 10),
                Text(s('to_wallet'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                _SegChoice(
                  options: Wallets.places,
                  value: toPlace,
                  onChanged: (v) => setModal(() {
                    toPlace = v;
                    if (fromPlace == toPlace) {
                      fromPlace = Wallets.places.firstWhere((p) => p != v);
                    }
                  }),
                  label: (p) => s(Wallets.placeKey(p)),
                  icon: Wallets.placeIcon,
                  color: color,
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    final amount = Money.parse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s('amount'))));
                      return;
                    }
                    if (fromPlace == toPlace) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s('same_wallet_error'))));
                      return;
                    }
                    provider.addTransaction(TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: provider.userId,
                      type: 'transfer',
                      amount: amount,
                      category: 'transfer',
                      date: DateTime.now(),
                      note: '',
                      place: fromPlace,
                      currency: currency,
                      toPlace: toPlace,
                      toCurrency: currency,
                      toAmount: amount,
                    ));
                    Navigator.pop(context);
                  },
                  child: Text(s('save')),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 18),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ── Ayirboshlash modali (so'm ↔ dollar) ───────────────────────────────────────

void showExchangeModal(BuildContext context, AppProvider provider) {
  final s = provider.s;
  String fromCurrency = Wallets.uzs;
  String toCurrency = Wallets.usd;
  String fromPlace = Wallets.cash;
  String toPlace = Wallets.cash;
  final giveCtrl = TextEditingController();
  final getCtrl = TextEditingController();
  const color = AppColors.violet;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.c;
      return StatefulBuilder(
        builder: (context, setModal) => Padding(
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
                Row(
                  children: [
                    const IconBadge(
                        icon: Icons.currency_exchange_rounded,
                        color: color,
                        size: 40),
                    const SizedBox(width: 12),
                    Text(s('add_exchange'), style: context.t.titleLarge),
                  ],
                ),
                const SizedBox(height: 22),

                // Berasiz
                Text(s('you_give'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                TextField(
                  controller: giveCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: Money.amountFormatters,
                  decoration: InputDecoration(
                    labelText: s('amount'),
                    suffixText: _curLabel(fromCurrency),
                    prefixIcon:
                        const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                _SegChoice(
                  options: Wallets.currencies,
                  value: fromCurrency,
                  onChanged: (v) => setModal(() {
                    fromCurrency = v;
                    if (toCurrency == fromCurrency) {
                      toCurrency =
                          Wallets.currencies.firstWhere((x) => x != v);
                    }
                  }),
                  label: _curLabel,
                  icon: Wallets.currencyIcon,
                  color: color,
                ),
                const SizedBox(height: 6),
                _SegChoice(
                  options: Wallets.places,
                  value: fromPlace,
                  onChanged: (v) => setModal(() => fromPlace = v),
                  label: (p) => s(Wallets.placeKey(p)),
                  icon: Wallets.placeIcon,
                  color: color,
                ),

                const SizedBox(height: 16),
                Center(
                  child: Icon(Icons.south_rounded,
                      color: c.textTertiary, size: 22),
                ),
                const SizedBox(height: 16),

                // Olasiz
                Text(s('you_get'), style: context.t.titleSmall),
                const SizedBox(height: 10),
                TextField(
                  controller: getCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: Money.amountFormatters,
                  decoration: InputDecoration(
                    labelText: s('amount'),
                    suffixText: _curLabel(toCurrency),
                    prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                _SegChoice(
                  options: Wallets.currencies,
                  value: toCurrency,
                  onChanged: (v) => setModal(() {
                    toCurrency = v;
                    if (fromCurrency == toCurrency) {
                      fromCurrency =
                          Wallets.currencies.firstWhere((x) => x != v);
                    }
                  }),
                  label: _curLabel,
                  icon: Wallets.currencyIcon,
                  color: color,
                ),
                const SizedBox(height: 6),
                _SegChoice(
                  options: Wallets.places,
                  value: toPlace,
                  onChanged: (v) => setModal(() => toPlace = v),
                  label: (p) => s(Wallets.placeKey(p)),
                  icon: Wallets.placeIcon,
                  color: color,
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    final give = Money.parse(giveCtrl.text);
                    final get = Money.parse(getCtrl.text);
                    if (give == null || give <= 0 || get == null || get <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s('amount'))));
                      return;
                    }
                    if (fromCurrency == toCurrency) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s('same_wallet_error'))));
                      return;
                    }
                    provider.addTransaction(TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: provider.userId,
                      type: 'exchange',
                      amount: give,
                      category: 'exchange',
                      date: DateTime.now(),
                      note: '',
                      place: fromPlace,
                      currency: fromCurrency,
                      toPlace: toPlace,
                      toCurrency: toCurrency,
                      toAmount: get,
                    ));
                    Navigator.pop(context);
                  },
                  child: Text(s('save')),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 18),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ── Sana tanlash maydoni ──────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DateField({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: c.textSecondary),
            const SizedBox(width: 12),
            Text(DateFmt.short(date), style: context.t.bodyLarge),
            const Spacer(),
            Icon(Icons.expand_more_rounded, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
