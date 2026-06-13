import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import '../l10n/app_strings.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import 'ui_kit.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currency;
  final AppStrings strings;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.currency,
    required this.strings,
    this.onDelete,
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
    final isIncome = transaction.type == 'income';
    final color =
        isIncome ? AppColors.income : AppColors.expense;
    final catColor = CategoryMeta.color(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
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
            IconBadge(
                icon: CategoryMeta.icon(transaction.category),
                color: catColor,
                size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(strings.cat(transaction.category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.t.titleSmall),
                      ),
                      if (!transaction.isSynced) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.cloud_off_rounded,
                            size: 12, color: c.textTertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.note.isNotEmpty
                        ? '${transaction.note} · ${_dateLabel(transaction.date)}'
                        : _dateLabel(transaction.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.t.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.format(
                  isIncome ? transaction.amount : -transaction.amount,
                  currency,
                  showSign: true),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tranzaksiya qo'shish modali ───────────────────────────────────────────────

void showAddTransactionModal(
    BuildContext context, AppProvider provider, String type) {
  final s = provider.s;
  final catKeys =
      type == 'income' ? s.incomeCategoryKeys : s.expenseCategoryKeys;

  String selectedCategoryKey = catKeys.first;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

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
                      type == 'income' ? s('add_income') : s('add_expense'),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  autofocus: true,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color),
                  decoration: InputDecoration(
                    labelText: s('amount'),
                    suffixText: provider.currency,
                    prefixIcon: Icon(Icons.payments_outlined, color: color),
                  ),
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
                                    color:
                                        selected ? cc : c.textSecondary)),
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
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setModal(() => selectedDate = picked);
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
                        Text(DateFmt.short(selectedDate),
                            style: context.t.bodyLarge),
                        const Spacer(),
                        Icon(Icons.expand_more_rounded,
                            color: c.textTertiary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s('amount'))),
                      );
                      return;
                    }
                    provider.addTransaction(TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: provider.userId,
                      type: type,
                      amount: amount,
                      category: selectedCategoryKey,
                      date: selectedDate,
                      note: noteCtrl.text.trim(),
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
