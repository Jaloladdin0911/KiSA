import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
          provider.transactions,
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
                        _BalanceCard(provider: provider),
                        const SizedBox(height: 14),
                        _QuickActions(provider: provider),
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
                                currency: provider.currency,
                                strings: s,
                                onDelete: () =>
                                    provider.deleteTransaction(t.id),
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
          AppSpacing.screen, 8, AppSpacing.screen, 16),
      child: Row(
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

// ── Balans kartasi ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AppProvider provider;
  const _BalanceCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final grad = context.c.balanceGradient;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brand(grad.first),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
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
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 7),
                  Text(s('total_balance'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money.format(provider.balance, provider.currency),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: s('income'),
                      value: Money.format(
                          provider.thisMonthIncome, provider.currency),
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: s('expense'),
                      value: Money.format(
                          provider.thisMonthExpense, provider.currency),
                      icon: Icons.arrow_upward_rounded,
                      alignEnd: true,
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

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool alignEnd;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 14 : 0, right: alignEnd ? 0 : 14),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
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
    final s = provider.s;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: s('income'),
            icon: Icons.add_rounded,
            color: AppColors.income,
            onTap: () =>
                showAddTransactionModal(context, provider, 'income'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: s('expense'),
            icon: Icons.remove_rounded,
            color: AppColors.expense,
            onTap: () =>
                showAddTransactionModal(context, provider, 'expense'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 9),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5)),
            ],
          ),
        ),
      ),
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
    final used = provider.monthlyBudget > 0
        ? (provider.thisMonthExpense / provider.monthlyBudget).clamp(0.0, 1.0)
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
            '${Money.format(provider.thisMonthExpense, provider.currency)}  /  ${Money.format(provider.monthlyBudget, provider.currency)}',
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
