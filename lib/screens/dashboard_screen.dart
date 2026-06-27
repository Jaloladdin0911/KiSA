import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import 'add_transaction_screen.dart';
import 'goals_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';
import 'accounts_screen.dart';

/// Asosiy ekran — KISA_DESIGN_SPEC.md, Section 5.
/// Token (KColors/kGradient/k) va real Provider ma'lumotlari bilan, responsive.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: KColors.bg,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 6),
                Padding(padding: kPad, child: _Header(provider: provider)),
                const SizedBox(height: 20),
                Padding(
                  padding: kPad,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AccountsScreen())),
                    child: _BalanceCard(provider: provider),
                  ),
                ),
                if (provider.currencyBalance('USD') != 0) ...[
                  const SizedBox(height: 12),
                  Padding(padding: kPad, child: _UsdChip(provider: provider)),
                ],
                const SizedBox(height: 16),
                Padding(padding: kPad, child: _StatRow(provider: provider)),
                const SizedBox(height: 22),
                Padding(padding: kPad, child: _QuickActions(provider: provider)),
                const SizedBox(height: 24),
                Padding(padding: kPad, child: _RecentSection(provider: provider)),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return 'K';
  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }
  return (parts.first.characters.first + parts.elementAt(1).characters.first)
      .toUpperCase();
}

// ── Sarlavha ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(_initials(provider.userName),
              style: k(15, w: FontWeight.w700, c: const Color(0xFF475569))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalomu alaykum', style: k(12, c: KColors.sub)),
              const SizedBox(height: 1),
              Text(provider.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k(17, w: FontWeight.w600)),
            ],
          ),
        ),
        _SquareButton(
          icon: Icons.notifications_none_rounded,
          dot: true,
          onTap: () => _soon(context),
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final bool dot;
  final VoidCallback onTap;
  const _SquareButton(
      {required this.icon, this.dot = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(rTile),
          boxShadow: kSoftShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: KColors.ink),
            if (dot)
              Positioned(
                top: 12,
                right: 13,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: KColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: KColors.card, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Balans hero kartasi ─────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  final AppProvider provider;
  const _BalanceCard({required this.provider});

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final total = p.currencyBalance('UZS');
    final white82 = Colors.white.withValues(alpha: 0.82);

    // Oylar bo'yicha xarajat o'zgarishi (o'tgan oyga nisbatan)
    final months = p.last6MonthsData('UZS');
    final thisExp = months[5]['expense'] as double;
    final lastExp = months[4]['expense'] as double;
    final double? momPct =
        lastExp > 0 ? (thisExp - lastExp) / lastExp * 100 : null;

    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.circular(rBalance),
        boxShadow: kGreenShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Umumiy balans',
                  style: k(13, w: FontWeight.w500, c: white82)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _hidden = !_hidden),
                child: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _hidden ? '••• •••' : Money.plain(total, currency: 'UZS'),
                    style: k(34, w: FontWeight.w700, c: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child:
                    Text("so'm", style: k(15, w: FontWeight.w500, c: white82)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (momPct != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(rCard),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    momPct >= 0
                        ? Icons.north_east_rounded
                        : Icons.south_east_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text('${momPct.abs().toStringAsFixed(1)}%',
                      style: k(12, w: FontWeight.w600, c: Colors.white)),
                  const SizedBox(width: 5),
                  Text("o'tgan oyga nisbatan",
                      style: k(12,
                          c: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '••••  ••••  ••••  4821',
                style: k(13,
                    c: Colors.white.withValues(alpha: 0.55), ls: 1.5),
              ),
              const Spacer(),
              const _MastercardMark(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 22,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFF5A623),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dollar hisobi chip (USD balans bo'lsa) ──────────────────────────────────

class _UsdChip extends StatelessWidget {
  final AppProvider provider;
  const _UsdChip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final usd = provider.currencyBalance('USD');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: KColors.card,
        borderRadius: BorderRadius.circular(rCard),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: KColors.greenBg, shape: BoxShape.circle),
            child: const Icon(Icons.attach_money_rounded,
                size: 18, color: KColors.primary),
          ),
          const SizedBox(width: 12),
          Text('Dollar hisobi', style: k(13, w: FontWeight.w500, c: KColors.sub)),
          const Spacer(),
          Text(Money.format(usd, 'USD'), style: k(16, w: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Kirim / Chiqim stat kartalari ───────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final AppProvider provider;
  const _StatRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Kirim',
            amount: provider.incomeThisMonth('UZS'),
            icon: Icons.south_west_rounded,
            color: KColors.primary,
            bg: KColors.greenBg,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Chiqim',
            amount: provider.expenseThisMonth('UZS'),
            icon: Icons.north_east_rounded,
            color: KColors.danger,
            bg: KColors.dangerBg,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color, bg;
  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KColors.card,
        borderRadius: BorderRadius.circular(rCard),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: k(12, w: FontWeight.w500, c: KColors.sub)),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Money.plain(amount, currency: 'UZS'),
                style: k(17, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Tezkor amallar ──────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final AppProvider provider;
  const _QuickActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          label: "O'tkazma",
          icon: Icons.swap_horiz_rounded,
          color: KColors.primary,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransferScreen())),
        ),
        _QuickAction(
          label: "To'lov",
          icon: Icons.bolt_rounded,
          color: KColors.orange,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddTransactionScreen(initialType: 'expense'),
          )),
        ),
        _QuickAction(
          label: 'Skaner',
          icon: Icons.qr_code_scanner_rounded,
          color: KColors.blue,
          onTap: () => _soon(context),
        ),
        _QuickAction(
          label: 'Maqsad',
          icon: Icons.flag_rounded,
          color: KColors.purple,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsScreen())),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: KColors.card,
              borderRadius: BorderRadius.circular(rCard),
              boxShadow: kSoftShadow,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: k(11, w: FontWeight.w500, c: KColors.sub)),
        ],
      ),
    );
  }
}

// ── So'nggi amallar ───────────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  final AppProvider provider;
  const _RecentSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final recent = provider.transactions.take(3).toList();
    final s = provider.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("So'nggi amallar", style: k(16, w: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionsScreen())),
              child: Text('Barchasi',
                  style: k(13, w: FontWeight.w600, c: KColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: KColors.card,
            borderRadius: BorderRadius.circular(rCardLg),
            boxShadow: kSoftShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text("Hali amallar yo'q",
                        style: k(13.5, c: KColors.mut)),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      _TxRow(
                        tx: recent[i],
                        strings: s,
                        onTap: () {
                          if (!recent[i].isMovement) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  AddTransactionScreen(existing: recent[i]),
                            ));
                          }
                        },
                      ),
                      if (i != recent.length - 1)
                        Divider(
                            height: 1, thickness: 1, color: KColors.line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionModel tx;
  final AppStrings strings;
  final VoidCallback onTap;
  const _TxRow(
      {required this.tx, required this.strings, required this.onTap});

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Bugun';
    }
    final y = now.subtract(const Duration(days: 1));
    if (date.year == y.year && date.month == y.month && date.day == y.day) {
      return 'Kecha';
    }
    return DateFmt.short(date);
  }

  @override
  Widget build(BuildContext context) {
    final t = tx;
    final isIncome = t.type == 'income';

    final IconData icon;
    final Color color;
    final String title;
    final String meta;
    final String amountStr;
    final Color amountColor;

    if (t.isMovement) {
      icon = t.type == 'exchange'
          ? Icons.currency_exchange_rounded
          : Icons.swap_horiz_rounded;
      color = KColors.purple;
      title = strings(t.type);
      meta = _dateLabel(t.date);
      amountStr = Money.format(t.amount, t.currency);
      amountColor = KColors.sub;
    } else {
      icon = CategoryMeta.icon(t.category);
      color = CategoryMeta.color(t.category);
      title = t.note.isNotEmpty ? t.note : strings.cat(t.category);
      meta = '${strings.cat(t.category)} · ${_dateLabel(t.date)}';
      final signed = isIncome ? t.amount : -t.amount;
      amountStr = Money.format(signed, t.currency, showSign: true);
      amountColor = isIncome ? KColors.primary : KColors.ink;
    }

    return GestureDetector(
      onTap: onTap,
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
                shape: BoxShape.circle,
              ),
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

void _soon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tez orada')),
  );
}
