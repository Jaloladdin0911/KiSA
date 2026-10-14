import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/app_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/categories.dart';
import '../widgets/kit.dart';
import '../widgets/movement_sheet.dart';
import 'add_transaction_screen.dart';
import 'recurring_screen.dart';
import 'goals_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';
import 'accounts_screen.dart';

/// Asosiy ekran — "Liquid Glass": aurora fon ustida shisha kartalar,
/// bo'limlar navbatma-navbat paydo bo'ladi, summalar sanab chiqadi.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sections = <Widget>[
          _Header(provider: provider),
          KPressable(
            scale: 0.98,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AccountsScreen())),
            child: _BalanceCard(provider: provider),
          ),
          if (provider.currencyBalance('USD') != 0) _UsdChip(provider: provider),
          _StatRow(provider: provider),
          _QuickActions(provider: provider),
          _RecentSection(provider: provider),
        ];
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(top: 6, bottom: 130),
              children: [
                for (var i = 0; i < sections.length; i++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, i == 0 ? 0 : (i == 1 ? 20 : 16), 20, 0),
                    child: KFadeSlideIn.stagger(i, child: sections[i]),
                  ),
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

/// Summa o'zgarganda eski qiymatdan yangisiga silliq "sanab" o'tadi.
class _CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle style;
  const _CountUp(
      {super.key,
      required this.value,
      required this.format,
      required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: KMotion.emphasized,
      builder: (_, v, __) => Text(format(v), style: style),
    );
  }
}

// ── Sarlavha ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    final upcoming = provider.upcomingRecurring(days: 3).isNotEmpty;
    return Row(
      children: [
        // Gradient halqali avatar
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            gradient: kGradient,
            shape: BoxShape.circle,
          ),
          child: Glass(
            borderRadius: BorderRadius.circular(24),
            shadow: const [],
            color: KColors.sheet,
            child: Center(
              child: Text(_initials(provider.userName),
                  style: k(15, w: FontWeight.w700, c: KColors.primary)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.s('greeting'), style: k(12.5, c: KColors.sub)),
              const SizedBox(height: 1),
              Text(provider.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k(18, w: FontWeight.w700)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            KIconButton(
              icon: Icons.notifications_none_rounded,
              label: provider.s('upcoming_payments'),
              onTap: () => _showUpcoming(context, provider),
            ),
            // Nuqta faqat yaqin 3 kunda takroriy to'lov bo'lsa — "puls" bilan
            if (upcoming)
              const Positioned(top: 10, right: 11, child: _PulseDot()),
          ],
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 8 + 12 * _c.value,
              height: 8 + 12 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KColors.danger.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: KColors.danger, shape: BoxShape.circle),
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

class _BalanceCardState extends State<_BalanceCard>
    with SingleTickerProviderStateMixin {
  bool _hidden = false;

  // Yaltirash: har 6 soniyada kartadan yorug'lik tasmasi o'tadi
  late final AnimationController _sheen = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6000))
    ..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

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

    return Glass(
      tint: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          KColors.gradStart.withValues(alpha: 0.92),
          KColors.gradMid.withValues(alpha: 0.86),
          KColors.gradEnd.withValues(alpha: 0.80),
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
      borderRadius: BorderRadius.circular(rBalance),
      shadow: kGreenShadow,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            // Suyuq shisha pufakchalar (dekor)
            Positioned(
              right: -40,
              top: -50,
              child: _bubble(170, 0.16),
            ),
            Positioned(
              left: -30,
              bottom: -70,
              child: _bubble(150, 0.10),
            ),
            // Yorug'lik tasmasi
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (_, __) {
                    // Davrning faqat birinchi 30% ida o'tadi, qolgani tinch
                    final t = (_sheen.value / 0.3).clamp(0.0, 1.0);
                    final x = -1.6 + 3.2 * Curves.easeInOut.transform(t);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x - 0.5, -1),
                          end: Alignment(x + 0.5, 1),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p.s('total_balance'),
                          style: k(13, w: FontWeight.w500, c: white82)),
                      const Spacer(),
                      KPressable(
                        scale: 0.8,
                        onTap: () => setState(() => _hidden = !_hidden),
                        child: AnimatedSwitcher(
                          duration: KMotion.fast,
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            _hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            key: ValueKey(_hidden),
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
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
                          child: AnimatedSwitcher(
                            duration: KMotion.medium,
                            child: _hidden
                                ? Text('••• •••',
                                    key: const ValueKey('h'),
                                    style: k(36,
                                        w: FontWeight.w700, c: Colors.white))
                                : _CountUp(
                                    key: const ValueKey('v'),
                                    value: total,
                                    format: (v) =>
                                        Money.plain(v, currency: 'UZS'),
                                    style: k(36,
                                        w: FontWeight.w700, c: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(p.s('som'),
                            style: k(15, w: FontWeight.w500, c: white82)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (momPct != null)
                    Glass(
                      color: Colors.white.withValues(alpha: 0.16),
                      shadow: const [],
                      borderRadius: BorderRadius.circular(rCard),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                              style: k(12,
                                  w: FontWeight.w600, c: Colors.white)),
                          const SizedBox(width: 5),
                          Text(p.s('vs_last_month'),
                              style: k(12,
                                  c: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Hamyonlar bo'yicha taqsimot (so'm)
                  Row(
                    children: [
                      _walletPart(Icons.payments_outlined, p.s('wallet_cash'),
                          p.balanceOf('cash', 'UZS')),
                      const SizedBox(width: 18),
                      _walletPart(Icons.credit_card_rounded,
                          p.s('wallet_card'), p.balanceOf('card', 'UZS')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, double alpha) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [
                Colors.white.withValues(alpha: alpha * 1.6),
                Colors.white.withValues(alpha: alpha * 0.3),
              ],
            ),
            border: Border.all(
                color: Colors.white.withValues(alpha: alpha * 1.4)),
          ),
        ),
      );

  Widget _walletPart(IconData icon, String label, double amount) {
    final dim = Colors.white.withValues(alpha: 0.75);
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: dim),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label  ${_hidden ? '•••' : Money.compact(amount, 'UZS')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k(12.5, w: FontWeight.w500, c: dim),
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
    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountsScreen())),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: KColors.greenBg, shape: BoxShape.circle),
            child: const Icon(Icons.attach_money_rounded,
                size: 18, color: KColors.primary),
          ),
          const SizedBox(width: 12),
          Text(provider.s('dollar_account'),
              style: k(13, w: FontWeight.w500, c: KColors.sub)),
          const Spacer(),
          _CountUp(
            value: usd,
            format: (v) => Money.format(v, 'USD'),
            style: k(16, w: FontWeight.w700),
          ),
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
    final income = provider.incomeThisMonth('UZS');
    final expense = provider.expenseThisMonth('UZS');
    final total = income + expense;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: provider.s('kirim'),
            amount: income,
            share: total > 0 ? income / total : 0,
            icon: Icons.south_west_rounded,
            color: KColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            label: provider.s('chiqim'),
            amount: expense,
            share: total > 0 ? expense / total : 0,
            icon: Icons.north_east_rounded,
            color: KColors.danger,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final double share; // 0..1 — kirim+chiqim ichidagi ulushi
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.amount,
    required this.share,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(label, style: k(12.5, w: FontWeight.w500, c: KColors.sub)),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _CountUp(
                value: amount,
                format: (v) => Money.plain(v, currency: 'UZS'),
                style: k(18, w: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            // Ulush chizig'i — to'lib boruvchi animatsiya
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share),
              duration: const Duration(milliseconds: 900),
              curve: KMotion.emphasized,
              builder: (_, v, __) => KProgressBar(
                  pct: v, color: color, height: 4, track: KColors.bg),
            ),
          ],
        ),
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
    void go(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          label: provider.s('transfer'),
          icon: Icons.swap_horiz_rounded,
          color: KColors.primary,
          onTap: () => go(const TransferScreen()),
        ),
        _QuickAction(
          label: provider.s('qa_payment'),
          icon: Icons.bolt_rounded,
          color: KColors.orange,
          onTap: () => go(const AddTransactionScreen(initialType: 'expense')),
        ),
        _QuickAction(
          label: provider.s('exchange'),
          icon: Icons.currency_exchange_rounded,
          color: KColors.blue,
          onTap: () => go(const TransferScreen(initialMode: 'exchange')),
        ),
        _QuickAction(
          label: provider.s('qa_goal'),
          icon: Icons.flag_rounded,
          color: KColors.purple,
          onTap: () => go(const GoalsScreen()),
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
    return KPressable(
      onTap: onTap,
      scale: 0.88,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Glass(
              borderRadius: BorderRadius.circular(rCard),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.24),
                          color.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                    child: Icon(icon, size: 21, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k(11.5, w: FontWeight.w500, c: KColors.sub)),
          ],
        ),
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
    final recent = provider.transactions.take(4).toList();
    final s = provider.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s('recent_actions'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k(17, w: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            KPressable(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionsScreen())),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(s('see_all'),
                    style: k(13, w: FontWeight.w600, c: KColors.primary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        KCard(
          radius: rCardLg,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 34, color: KColors.mut),
                        const SizedBox(height: 8),
                        Text(s('no_transactions'),
                            style: k(13.5, c: KColors.mut)),
                        const SizedBox(height: 16),
                        // Yangi foydalanuvchi uchun — birinchi qadam
                        KPressable(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(
                                      initialType: 'expense'))),
                          child: Glass(
                            tint: kGradient,
                            shadow: kGreenShadow,
                            borderRadius: BorderRadius.circular(rBtn),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(s('add_first'),
                                    style: k(13.5,
                                        w: FontWeight.w600,
                                        c: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Mavjud pulni kirim deb emas, boshlang'ich qoldiq deb kiritish
                        KPressable(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AccountsScreen())),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(s('set_opening_balance'),
                                style: k(13,
                                    w: FontWeight.w600,
                                    c: KColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      KFadeSlideIn(
                        key: ValueKey(recent[i].id),
                        delay: Duration(milliseconds: 200 + 50 * i),
                        offset: 12,
                        child: _TxRow(
                          tx: recent[i],
                          strings: s,
                          onTap: () => openTransaction(context, recent[i]),
                        ),
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
      return strings('today');
    }
    final y = now.subtract(const Duration(days: 1));
    if (date.year == y.year && date.month == y.month && date.day == y.day) {
      return strings('yesterday');
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

    if (t.isAdjust) {
      // Qoldiq tuzatish — ishorali summa, statistikaga kirmaydi
      icon = Icons.tune_rounded;
      color = KColors.indigo;
      title = strings('balance_adjust');
      meta = _dateLabel(t.date);
      amountStr = Money.format(t.amount, t.currency, showSign: true);
      amountColor = KColors.sub;
    } else if (t.isMovement) {
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

/// Qo'ng'iroqcha: yaqin 7 kundagi takroriy to'lovlar.
void _showUpcoming(BuildContext context, AppProvider provider) {
  final s = provider.s;
  final items = provider.upcomingRecurring();
  final today = DateUtils.dateOnly(DateTime.now());

  String when(DateTime d) {
    final diff = DateUtils.dateOnly(d).difference(today).inDays;
    if (diff <= 0) return s('today');
    if (diff == 1) return s('tomorrow');
    return s('in_days').replaceAll('{n}', '$diff');
  }

  showKSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            Text(s('upcoming_payments'), style: k(17, w: FontWeight.w700)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Text(s('no_upcoming'),
                      textAlign: TextAlign.center,
                      style: k(13.5, c: KColors.mut)),
                ),
              )
            else
              for (final r in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CategoryMeta.color(r.category)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CategoryMeta.icon(r.category),
                            size: 19, color: CategoryMeta.color(r.category)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                r.note.isNotEmpty ? r.note : s.cat(r.category),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: k(14, w: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(when(r.nextDate),
                                style: k(11.5, c: KColors.mut)),
                          ],
                        ),
                      ),
                      Text(
                        Money.format(
                            r.type == 'income' ? r.amount : -r.amount,
                            r.currency,
                            showSign: true),
                        style: k(14.5,
                            w: FontWeight.w600,
                            c: r.type == 'income'
                                ? KColors.primary
                                : KColors.ink),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RecurringScreen()));
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(s('recurring'),
                      style: k(14, w: FontWeight.w600, c: KColors.primary)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
