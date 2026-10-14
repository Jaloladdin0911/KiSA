import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/kit.dart';
import 'transfer_screen.dart';

/// Hisoblar — umumiy boylik, CBU kursi va 4 hamyon (naqd/karta × so'm/dollar).
/// Hamyon qatori bosilsa — haqiqiy qoldiqni kiritish (boshlang'ich qoldiq
/// yoki tuzatish); farq "Qoldiq tuzatish" sifatida yoziladi.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, p, _) {
        final s = p.s;
        final sections = <Widget>[
          _NetWorthCard(provider: p),
          const _RateCard(),
          _WalletCard(
            title: s('cash_money'),
            icon: Icons.payments_rounded,
            color: KColors.primary,
            place: 'cash',
          ),
          _WalletCard(
            title: s('wallet_card'),
            icon: Icons.credit_card_rounded,
            color: KColors.blue,
            place: 'card',
          ),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: KColors.mut),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s('wallet_hint'),
                    style: k(12, c: KColors.mut, height: 1.4)),
              ),
            ],
          ),
          KPrimaryButton(
            label: "${s('transfer')} / ${s('exchange')}",
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransferScreen())),
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                          child: Text(s('accounts'),
                              style: k(17, w: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                          child: KFadeSlideIn.stagger(i, child: sections[i]),
                        ),
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
}

// ── Umumiy boylik ─────────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final AppProvider provider;
  const _NetWorthCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final s = p.s;
    final uzs = p.currencyBalance('UZS');
    final usd = p.currencyBalance('USD');
    final w85 = Colors.white.withValues(alpha: 0.85);
    return Glass(
      tint: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          KColors.gradStart.withValues(alpha: 0.92),
          KColors.gradEnd.withValues(alpha: 0.82),
        ],
      ),
      borderRadius: BorderRadius.circular(rCardLg),
      shadow: kGreenShadow,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s('net_worth'),
                    style: k(13, w: FontWeight.w500, c: w85)),
              ),
              const Icon(Icons.account_balance_rounded,
                  size: 20, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p.netWorthUzs),
              duration: const Duration(milliseconds: 900),
              curve: KMotion.emphasized,
              builder: (_, v, __) => Text(
                  "${usd != 0 && p.usdRate > 0 ? '≈ ' : ''}${Money.plain(v, currency: 'UZS')} ${s('som')}",
                  style: k(30, w: FontWeight.w700, c: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill("${Money.plain(uzs, currency: 'UZS')} ${s('som')}"),
              _pill(Money.format(usd, 'USD')),
            ],
          ),
          if (usd != 0 && p.usdRate <= 0) ...[
            const SizedBox(height: 10),
            Text(s('rate_unknown_hint'),
                style: k(11.5, c: w85, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text) => Glass(
        color: Colors.white.withValues(alpha: 0.16),
        shadow: const [],
        borderRadius: BorderRadius.circular(rCard),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(text,
            style: k(12.5, w: FontWeight.w600, c: Colors.white)),
      );
}

// ── CBU kursi ────────────────────────────────────────────────────────────────

class _RateCard extends StatefulWidget {
  const _RateCard();

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  bool _loading = false;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    final p = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    _spin.repeat();
    final ok = await p.refreshRate();
    if (!mounted) return;
    _spin
      ..stop()
      ..reset();
    setState(() => _loading = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(ok ? p.s('rate_updated') : p.s('rate_refresh_fail'))));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final s = p.s;
    final d = p.rateDate;
    String two(int v) => v.toString().padLeft(2, '0');
    final when = d == null
        ? null
        : '${DateFmt.short(d)} ${two(d.hour)}:${two(d.minute)}';

    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          const KTintedIcon(
              icon: Icons.currency_exchange_rounded,
              color: KColors.orange,
              size: 40,
              circle: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s('cbu_rate'), style: k(12, c: KColors.sub)),
                const SizedBox(height: 2),
                Text(
                    p.usdRate > 0
                        ? '1 \$ = ${Money.format(p.usdRate, 'UZS')}'
                        : s('rate_unknown'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k(16, w: FontWeight.w700)),
                if (when != null)
                  Text('${s('rate_updated')}: $when',
                      style: k(11, c: KColors.mut)),
              ],
            ),
          ),
          KPressable(
            onTap: _refresh,
            scale: 0.85,
            semanticLabel: s('rate_refresh'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RotationTransition(
                turns: _spin,
                child: const Icon(Icons.refresh_rounded,
                    size: 22, color: KColors.primary),
              ),
            ),
          ),
          KPressable(
            onTap: () => _manualSheet(context, p),
            scale: 0.85,
            semanticLabel: s('set_rate'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined, size: 20, color: KColors.sub),
            ),
          ),
        ],
      ),
    );
  }

  void _manualSheet(BuildContext context, AppProvider p) {
    final s = p.s;
    final ctrl = TextEditingController(
        text: p.usdRate > 0 ? Money.plain(p.usdRate, currency: 'UZS') : '');
    _amountSheet(
      context,
      title: s('set_rate'),
      subtitle: s('rate_manual_hint'),
      controller: ctrl,
      suffix: "${s('som')} / \$1",
      onSave: (v) {
        if (v <= 0) return false;
        p.setUsdRate(v);
        return true;
      },
    );
  }
}

// ── Hamyon kartasi ───────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final String title, place;
  final IconData icon;
  final Color color;
  const _WalletCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final s = p.s;
    return KCard(
      radius: rCardLg,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              KTintedIcon(icon: icon, color: color, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k(15, w: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _line(context, p, s('som_word'), 'UZS'),
          Divider(height: 1, thickness: 1, color: KColors.line),
          _line(context, p, s('dollar_word'), 'USD'),
        ],
      ),
    );
  }

  Widget _line(
      BuildContext context, AppProvider p, String label, String currency) {
    final bal = p.balanceOf(place, currency);
    return KPressable(
      scale: 0.98,
      onTap: () => _adjustSheet(context, p, currency, bal),
      semanticLabel: '$title, $label: ${Money.format(bal, currency)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: k(13, c: KColors.sub)),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(Money.format(bal, currency),
                    style: k(15.5,
                        w: FontWeight.w700,
                        c: bal < 0 ? KColors.danger : KColors.ink)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 16, color: KColors.mut),
          ],
        ),
      ),
    );
  }

  void _adjustSheet(
      BuildContext context, AppProvider p, String currency, double current) {
    final s = p.s;
    final ctrl = TextEditingController(
        text: current > 0 ? Money.plain(current, currency: currency) : '');
    final messenger = ScaffoldMessenger.of(context);
    _amountSheet(
      context,
      title: '${s('set_balance')} · $title',
      subtitle: s('set_balance_hint'),
      controller: ctrl,
      suffix: currency == 'USD' ? '\$' : s('som'),
      onSave: (v) {
        if (v < 0) return false;
        p.setActualBalance(place, currency, v).then((changed) {
          if (!changed) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s('balance_updated'))));
        });
        return true;
      },
    );
  }
}

// ── Umumiy: summa kiritish oynasi ────────────────────────────────────────────

/// Bitta summa maydonli shisha oyna. [onSave] true qaytarsa yopiladi.
void _amountSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required TextEditingController controller,
  required String suffix,
  required bool Function(double value) onSave,
}) {
  final s = context.read<AppProvider>().s;
  showKSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      void save() {
        final v = Money.parse(controller.text);
        if (v == null) return;
        if (onSave(v)) Navigator.pop(ctx);
      }

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KSheetHandle(),
                const SizedBox(height: 18),
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: k(17, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: k(12.5, c: KColors.sub, height: 1.4)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: Money.amountFormatters,
                  onSubmitted: (_) => save(),
                  style: k(22, w: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: k(22, w: FontWeight.w700, c: KColors.mut),
                    suffixText: suffix,
                    filled: true,
                    fillColor: KColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(rTile),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                KPrimaryButton(label: s('save'), onTap: save),
              ],
            ),
          ),
        ),
      );
    },
  );
}
