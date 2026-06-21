import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_kit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final auth = AuthService();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                PageHeader(title: s('settings')),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil
                      _ProfileCard(provider: provider, auth: auth),

                      GroupLabel(s('finance')),
                      _Tile(
                        icon: Icons.attach_money_rounded,
                        iconColor: AppColors.brand,
                        title: s('currency'),
                        subtitle: provider.currency,
                        onTap: () => _currencyDialog(context, provider, s),
                      ),
                      _Tile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.info,
                        title: s('monthly_budget_s'),
                        subtitle: provider.monthlyBudget > 0
                            ? Money.format(
                                provider.monthlyBudget, provider.currency)
                            : s('not_set'),
                        onTap: () => _budgetDialog(context, provider, s),
                      ),
                      _Tile(
                        icon: Icons.currency_exchange_rounded,
                        iconColor: AppColors.violet,
                        title: s('usd_rate'),
                        subtitle: provider.usdRate > 0
                            ? '1 \$ = ${Money.format(provider.usdRate, 'UZS')}'
                            : s('not_set'),
                        onTap: () => _rateDialog(context, provider, s),
                      ),

                      GroupLabel(s('appearance')),
                      _SwitchTile(
                        icon: Icons.dark_mode_outlined,
                        iconColor: AppColors.violet,
                        title: s('dark_mode'),
                        subtitle: provider.isDarkMode
                            ? s('dark_mode_on')
                            : s('dark_mode_off'),
                        value: provider.isDarkMode,
                        onChanged: provider.setDarkMode,
                      ),
                      _Tile(
                        icon: Icons.translate_rounded,
                        iconColor: AppColors.warning,
                        title: s('language'),
                        subtitle:
                            kLanguageNames[provider.language] ?? "O'zbek",
                        onTap: () => _languageDialog(context, provider, s),
                      ),

                      if (auth.isLoggedIn) ...[
                        GroupLabel(s('sync')),
                        _Tile(
                          icon: provider.isSyncing
                              ? Icons.sync_rounded
                              : Icons.cloud_sync_outlined,
                          iconColor: AppColors.brand,
                          title: provider.isSyncing
                              ? s('syncing')
                              : s('firebase_sync'),
                          subtitle: provider.isOnline
                              ? s('online')
                              : s('offline'),
                          onTap: provider.isSyncing
                              ? null
                              : () => provider.manualSync(),
                        ),
                      ],

                      GroupLabel(s('data_section')),
                      _StatRow(
                        icon: Icons.receipt_long_outlined,
                        label: s('stat_transactions'),
                        value:
                            '${provider.transactions.length} ${s('count_suffix')}',
                      ),
                      _StatRow(
                        icon: Icons.flag_outlined,
                        label: s('stat_active_goals'),
                        value:
                            '${provider.goals.where((g) => !g.isCompleted).length} ${s('count_suffix')}',
                      ),
                      _StatRow(
                        icon: Icons.savings_outlined,
                        label: s('stat_total_balance'),
                        value:
                            '${Money.compact(provider.currencyBalance('UZS'), 'UZS')}  ·  ${Money.compact(provider.currencyBalance('USD'), 'USD')}',
                      ),

                      const SizedBox(height: 16),
                      _DangerTile(
                        title: s('clear_all'),
                        subtitle: s('irreversible'),
                        onTap: () => _clearDialog(context, provider, s),
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: Text('KiSA v2.0.0',
                            style: context.t.bodySmall),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text('Moliyaviy boshqaruv',
                            style: context.t.labelSmall),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dialoglar ──────────────────────────────────────────────────────────────

  void _currencyDialog(
      BuildContext context, AppProvider provider, AppStrings s) {
    const currencies = ['UZS', 'USD'];
    _radioSheet<String>(
      context,
      title: s('select_currency'),
      groupValue: provider.currency,
      options: {for (final c in currencies) c: '$c · ${Money.symbols[c]}'},
      onSelect: provider.setCurrency,
    );
  }

  void _languageDialog(
      BuildContext context, AppProvider provider, AppStrings s) {
    _radioSheet<String>(
      context,
      title: s('select_language'),
      groupValue: provider.language,
      options: kLanguageNames,
      onSelect: provider.setLanguage,
    );
  }

  void _radioSheet<T>(
    BuildContext context, {
    required String title,
    required T groupValue,
    required Map<T, String> options,
    required ValueChanged<T> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text(title, style: ctx.t.titleLarge),
              const SizedBox(height: 16),
              ...options.entries.map((e) {
                final selected = e.key == groupValue;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? AppColors.brand.withValues(alpha: 0.1)
                        : c.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        onSelect(e.key);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.brand
                                          : c.textPrimary)),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.brand, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _rateDialog(BuildContext context, AppProvider provider, AppStrings s) {
    final ctrl = TextEditingController(
        text: provider.usdRate > 0
            ? Money.plain(provider.usdRate, currency: 'UZS')
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('usd_rate')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: Money.amountFormatters,
              decoration: InputDecoration(
                labelText: s('set_rate'),
                prefixText: '1 \$ = ',
                suffixText: "so'm",
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await provider.refreshRate();
                  if (ctx.mounted && provider.usdRate > 0) {
                    ctrl.text = Money.plain(provider.usdRate, currency: 'UZS');
                  }
                },
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(s('cbu_rate')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'),
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () {
              final r = Money.parse(ctrl.text);
              if (r != null && r > 0) provider.setUsdRate(r);
              Navigator.pop(ctx);
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
  }

  void _budgetDialog(
      BuildContext context, AppProvider provider, AppStrings s) {
    final ctrl = TextEditingController(
        text: provider.monthlyBudget > 0
            ? Money.plain(provider.monthlyBudget, currency: provider.currency)
            : '');
    _inputDialog(
      context,
      title: s('monthly_budget_s'),
      controller: ctrl,
      label: s('amount'),
      suffix: provider.currency,
      number: true,
      onSave: () => provider.setMonthlyBudget(Money.parse(ctrl.text) ?? 0),
      saveLabel: s('save'),
      cancelLabel: s('cancel'),
    );
  }

  void _clearDialog(
      BuildContext context, AppProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('are_you_sure'),
            style: const TextStyle(color: AppColors.expense)),
        content: Text(s('clear_confirm'), style: ctx.t.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'),
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () {
              provider.clearAllData();
              Navigator.pop(ctx);
            },
            child: Text(s('delete')),
          ),
        ],
      ),
    );
  }

  void _inputDialog(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String label,
    String? suffix,
    bool number = false,
    required VoidCallback onSave,
    required String saveLabel,
    required String cancelLabel,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: number ? Money.amountFormatters : null,
          textCapitalization:
              number ? TextCapitalization.none : TextCapitalization.words,
          decoration: InputDecoration(labelText: label, suffixText: suffix),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelLabel,
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () {
              onSave();
              Navigator.pop(ctx);
            },
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }
}

// ── Profil kartasi ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppProvider provider;
  final AuthService auth;
  const _ProfileCard({required this.provider, required this.auth});

  @override
  Widget build(BuildContext context) {
    final s = provider.s;
    final loggedIn = auth.isLoggedIn;
    final initial = provider.userName.isNotEmpty
        ? provider.userName.characters.first.toUpperCase()
        : 'K';

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandSoft, AppColors.brandDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.t.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      loggedIn
                          ? (auth.currentUser?.email ?? '')
                          : s('local_data_only'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.t.bodySmall,
                    ),
                  ],
                ),
              ),
              CircleAction(
                icon: Icons.edit_outlined,
                onTap: () => _nameDialog(context, provider, s),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: loggedIn
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: BorderSide(
                          color: AppColors.expense.withValues(alpha: 0.4)),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: () =>
                        _logoutDialog(context, auth, provider, s),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(s('logout')),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: BorderSide(
                          color: AppColors.brand.withValues(alpha: 0.4)),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(s('login')),
                  ),
          ),
        ],
      ),
    );
  }

  void _nameDialog(BuildContext context, AppProvider provider, AppStrings s) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('enter_name')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s('name_label')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'),
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.setUserName(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
  }

  void _logoutDialog(BuildContext context, AuthService auth,
      AppProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('logout')),
        content: Text(s('logout_confirm'), style: ctx.t.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'),
                style: TextStyle(color: ctx.c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                await provider.init();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(s('logout')),
          ),
        ],
      ),
    );
  }
}

// ── Qayta ishlatiladigan satrlar ──────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.c.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                IconBadge(icon: icon, color: iconColor, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.t.titleSmall),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.t.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: context.c.textTertiary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: iconColor, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.t.titleSmall),
                const SizedBox(height: 1),
                Text(subtitle, style: context.t.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: context.t.bodyLarge)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.brand)),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onTap;
  const _DangerTile(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.expense.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border:
                Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const IconBadge(
                  icon: Icons.delete_forever_outlined,
                  color: AppColors.expense,
                  size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.expense.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
