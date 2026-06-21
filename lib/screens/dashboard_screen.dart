import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/wallets.dart';
import '../widgets/ui_kit.dart';
import '../widgets/transaction_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final c = context.c;
        final recent = provider.transactions.take(6).toList();
        final insights = AiService.generate(
          provider.transactionsInCurrency(provider.currency),
          provider.monthlyBudget,
          s,
          provider.currency,
        );

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.brand,
              backgroundColor: c.surface,
              onRefresh: () => provider.manualSync(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _Header(provider: provider)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 4,
                        AppSpacing.screen, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _WalletsSection(provider: provider),
                        const SizedBox(height: 22),
                        if (provider.monthlyBudget > 0) ...[
                          _BudgetCard(provider: provider),
                          const SizedBox(height: 22),
                        ],
                        if (insights.isNotEmpty) ...[
                          SectionTitle(s('ai_insights')),
                          ...insights.map((ins) => _InsightCard(insight: ins)),
                          const SizedBox(height: 10),
                        ],
                        SectionTitle(
                          s('recent_transactions'),
                          trailing: Text(
                            '${provider.transactions.length} ${s('count_suffix')}',
                            style: context.t.bodySmall,
                          ),
                        ),
                        if (recent.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: s('no_transactions'),
                              subtitle: s('use_buttons_below'),
                            ),
                          )
                        else
                          ...recent.map((t) => TransactionCard(
                                transaction: t,
                                strings: s,
                                onDelete: () =>
                                    provider.deleteTransaction(t.id),
                                onTap: t.isMovement
                                    ? null
                                    : () => showAddTransactionModal(
                                        context, provider, t.type,
                                        existing: t),
                              )),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Sarlavha ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    final initial = provider.userName.isNotEmpty
        ? provider.userName.characters.first.toUpperCase()
        : 'K';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 8, AppSpacing.screen, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandSoft, AppColors.brandDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xush kelibsiz', style: context.t.bodySmall),
                    const SizedBox(height: 1),
                    Text(provider.userName,
                        style: context.t.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _SyncBadge(provider: provider),
            ],
          ),
          if (provider.usdRate > 0) ...[
            const SizedBox(height: 12),
            _RateBar(provider: provider),
          ],
        ],
      ),
    );
  }
}

// ── Valyuta kursi chizig'i (header tagida) ────────────────────────────────────

class _RateBar extends StatelessWidget {
  final AppProvider provider;
  const _RateBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_exchange_rounded,
              size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Text('1 \$ = ',
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          Text(
            Money.format(provider.usdRate, 'UZS'),
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brand),
          ),
          const Spacer(),
          Text(provider.s('cbu_rate'),
              style: context.t.labelSmall?.copyWith(fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final AppProvider provider;
  const _SyncBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final online = provider.isOnline;
    final color = online ? AppColors.brand : c.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          if (provider.isSyncing)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brand),
            )
          else
            Icon(online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            provider.isSyncing
                ? provider.s('syncing')
                : (online ? provider.s('online') : provider.s('offline')),
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Hamyonlar bo'limi ──────────────────────────────────────────────────────────

class _WalletsSection extends StatelessWidget {
  final AppProvider provider;
  const _WalletsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WalletCard(
          provider: provider,
          currency: Wallets.uzs,
          title: "So'm",
          gradient: context.c.balanceGradient,
        ),
        const SizedBox(height: 12),
        _WalletCard(
          provider: provider,
          currency: Wallets.usd,
          title: 'Dollar',
          gradient: const [Color(0xFF0B7285), Color(0xFF0B4F5E)],
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  final String title;
  final List<Color> gradient;

  const _WalletCard({
    required this.provider,
    required this.currency,
    required this.title,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final total = provider.currencyBalance(currency);
    final cash = provider.balanceOf(Wallets.cash, currency);
    final card = provider.balanceOf(Wallets.card, currency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.brand(gradient.first),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -26,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Wallets.currencyIcon(currency),
                      size: 15, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 7),
                  Text(title,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Money.format(total, currency),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _WalletMini(
                      label: s('wallet_cash'),
                      value: Money.format(cash, currency),
                      icon: Wallets.placeIcon(Wallets.cash),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 1,
                    height: 26,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _WalletMini(
                      label: s('wallet_card'),
                      value: Money.format(card, currency),
                      icon: Wallets.placeIcon(Wallets.card),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletMini extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _WalletMini({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11)),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Budget kartasi ──────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final AppProvider provider;
  const _BudgetCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final monthExpense = provider.expenseThisMonth(provider.currency);
    final used = provider.monthlyBudget > 0
        ? (monthExpense / provider.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final over = used >= 0.85;
    final barColor = over ? AppColors.expense : AppColors.brand;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 18, color: context.c.textSecondary),
                  const SizedBox(width: 8),
                  Text(s('monthly_budget'), style: context.t.titleSmall),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('${(used * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: used,
              minHeight: 9,
              backgroundColor: context.c.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${Money.format(monthExpense, provider.currency)}  /  ${Money.format(provider.monthlyBudget, provider.currency)}',
            style: context.t.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── AI tavsiya kartasi ────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: insight.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(insight.icon, size: 20, color: insight.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: insight.color)),
                const SizedBox(height: 3),
                Text(insight.body, style: context.t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
