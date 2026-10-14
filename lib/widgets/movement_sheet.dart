import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../screens/add_transaction_screen.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'kit.dart';

/// Ro'yxatdagi amal bosilganda: kirim/chiqim tahrirlash ekranini, o'tkazma/
/// ayirboshlash esa tafsilot oynasini (o'chirish bilan) ochadi.
void openTransaction(BuildContext context, TransactionModel t) {
  if (t.isSystem) {
    showMovementSheet(context, t);
  } else {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddTransactionScreen(existing: t),
    ));
  }
}

/// Amalni o'chiradi va 5 soniya davomida "Bekor qilish" imkonini beradi.
/// [context] — o'chirishdan keyin ham yashaydigan ekran (masalan ro'yxat).
Future<void> deleteWithUndo(BuildContext context, TransactionModel t) async {
  final provider = context.read<AppProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final s = provider.s;
  await provider.deleteTransaction(t.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(s('tx_deleted')),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: s('undo'),
        textColor: const Color(0xFF6EE7B7),
        // updateTransaction o'z joyiga (sana bo'yicha) qaytarib qo'yadi
        onPressed: () => provider.updateTransaction(t),
      ),
    ));
}

/// O'tkazma / ayirboshlash / qoldiq tuzatish tafsilotlari.
void showMovementSheet(BuildContext context, TransactionModel t) {
  final provider = context.read<AppProvider>();
  final s = provider.s;
  String wallet(String place, String cur) =>
      '${place == 'card' ? s('wallet_card') : s('wallet_cash')} · '
      '${cur == 'USD' ? '\$' : s('som')}';

  final toPlace = t.toPlace ?? t.place;
  final toCur = t.toCurrency ?? t.currency;
  final toAmount = t.toAmount ?? t.amount;
  final d = t.date;
  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  showKSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KSheetHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                KTintedIcon(
                  icon: t.isAdjust
                      ? Icons.tune_rounded
                      : t.type == 'exchange'
                          ? Icons.currency_exchange_rounded
                          : Icons.swap_horiz_rounded,
                  color: t.isAdjust ? KColors.indigo : KColors.purple,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.isAdjust ? s('balance_adjust') : s(t.type),
                          style: k(17, w: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${DateFmt.short(d)} · $time',
                          style: k(12.5, c: KColors.mut)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            KCard(
              color: KColors.bg,
              shadow: const [],
              child: t.isAdjust
                  ? _line(
                      s('account'),
                      wallet(t.place, t.currency),
                      Money.format(t.amount, t.currency, showSign: true),
                      t.amount >= 0 ? KColors.primary : KColors.danger)
                  : Column(
                children: [
                  _line(s('from_wallet'), wallet(t.place, t.currency),
                      '−${Money.format(t.amount, t.currency)}', KColors.danger),
                  const SizedBox(height: 12),
                  _line(s('to_wallet'), wallet(toPlace, toCur),
                      '+${Money.format(toAmount, toCur)}', KColors.primary),
                ],
              ),
            ),
            if (t.isAdjust) ...[
              const SizedBox(height: 10),
              Text(s('adjust_note'),
                  style: k(12, c: KColors.mut, height: 1.4)),
            ],
            if (t.type == 'exchange' && t.amount > 0) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  // Har doim "1 $ = X so'm" ko'rinishida
                  t.currency == 'USD'
                      ? '1 \$ = ${Money.format(toAmount / t.amount, 'UZS')}'
                      : '1 \$ = ${Money.format(t.amount / toAmount, 'UZS')}',
                  style: k(12, c: KColors.mut),
                ),
              ),
            ],
            const SizedBox(height: 18),
            KPressable(
              scale: 0.97,
              onTap: () {
                Navigator.pop(ctx);
                deleteWithUndo(context, t);
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KColors.dangerBg,
                  borderRadius: BorderRadius.circular(rBtn),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 20, color: KColors.danger),
                    const SizedBox(width: 8),
                    Text(s('delete'),
                        style:
                            k(15, w: FontWeight.w600, c: KColors.danger)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _line(String label, String wallet, String amount, Color color) => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: k(11.5, c: KColors.mut)),
              const SizedBox(height: 2),
              Text(wallet, style: k(14, w: FontWeight.w600)),
            ],
          ),
        ),
        Text(amount, style: k(15, w: FontWeight.w700, c: color)),
      ],
    );
