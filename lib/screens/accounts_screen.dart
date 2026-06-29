import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/kit.dart';
import 'transfer_screen.dart';

/// Hisoblar — naqd va karta, har birida so'm va dollar (4 hamyon).
/// Balanslar tranzaksiyalardan hisoblanadi (place + currency).
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
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
                          child: Text(provider.s('accounts'),
                              style: k(17, w: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _TotalCard(
                        uzs: provider.currencyBalance('UZS'),
                        usd: provider.currencyBalance('USD'),
                      ),
                      const SizedBox(height: 20),
                      _AccountCard(
                        title: provider.s('cash_money'),
                        icon: Icons.payments_rounded,
                        color: KColors.primary,
                        uzs: provider.balanceOf('cash', 'UZS'),
                        usd: provider.balanceOf('cash', 'USD'),
                      ),
                      const SizedBox(height: 14),
                      _AccountCard(
                        title: provider.s('wallet_card'),
                        icon: Icons.credit_card_rounded,
                        color: KColors.blue,
                        uzs: provider.balanceOf('card', 'UZS'),
                        usd: provider.balanceOf('card', 'USD'),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TransferScreen())),
                        child: Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: kGradient,
                            borderRadius: BorderRadius.circular(rBtn),
                            boxShadow: kGreenShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.swap_horiz_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  "${provider.s('transfer')} / ${provider.s('exchange')}",
                                  style: k(15,
                                      w: FontWeight.w600, c: Colors.white)),
                            ],
                          ),
                        ),
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

class _TotalCard extends StatelessWidget {
  final double uzs, usd;
  const _TotalCard({required this.uzs, required this.usd});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.circular(rCardLg),
        boxShadow: kGreenShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s('total_balance'),
              style: k(13,
                  w: FontWeight.w500,
                  c: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text("${Money.plain(uzs, currency: 'UZS')} ${s('som')}",
                style: k(28, w: FontWeight.w700, c: Colors.white)),
          ),
          if (usd != 0) ...[
            const SizedBox(height: 4),
            Text(Money.format(usd, 'USD'),
                style: k(16,
                    w: FontWeight.w600,
                    c: Colors.white.withValues(alpha: 0.9))),
          ],
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double uzs, usd;
  const _AccountCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.uzs,
    required this.usd,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    return KCard(
      radius: rCardLg,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              KTintedIcon(icon: icon, color: color, size: 40),
              const SizedBox(width: 12),
              Text(title, style: k(15, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _line(s('som_word'), "${Money.plain(uzs, currency: 'UZS')} ${s('som')}"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: KColors.line),
          ),
          _line(s('dollar_word'), Money.format(usd, 'USD')),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Row(
        children: [
          Text(label, style: k(13, c: KColors.sub)),
          const Spacer(),
          Text(value, style: k(15, w: FontWeight.w700)),
        ],
      );
}
