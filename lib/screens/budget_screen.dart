import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/kit.dart';

/// Byudjet — KISA_DESIGN_SPEC.md, Section 8.
/// Hero real ma'lumotga (oylik budjet + bu oy xarajati) bog'langan.
/// Kategoriya limitlari hozircha namuna — per-category budjet modeli keyin qo'shiladi.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const _months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        final hasBudget = provider.monthlyBudget > 0;
        final limit = hasBudget ? provider.monthlyBudget : 7000000.0;
        final spent =
            hasBudget ? provider.expenseThisMonth('UZS') : 4850000.0;
        final remaining = (limit - spent).clamp(0, double.infinity).toDouble();
        final pct = limit > 0 ? (spent / limit) : 0.0;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: kPad,
                child: KPageHeader(
                  title: 'Byudjet',
                  subtitle: '${_months[now.month - 1]} oyi · $daysInMonth kun',
                  trailing: KAddButton(onTap: () => _soon(context)),
                ),
              ),
              const SizedBox(height: 18),

              // Hero
              Padding(
                padding: kPad,
                child: _Hero(
                  remaining: remaining,
                  spent: spent,
                  limit: limit,
                  pct: pct.clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(height: 22),

              Padding(
                padding: kPad,
                child: Row(
                  children: [
                    Text('Kategoriyalar', style: k(16, w: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _soon(context),
                      child: Text('Tahrirlash',
                          style: k(13, w: FontWeight.w600, c: KColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ..._categories.map((c) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _BudgetRow(data: c),
                  )),
            ],
          ),
        );
      },
    );
  }

  static const _categories = [
    _Cat('Oziq-ovqat', Icons.local_cafe_rounded, KColors.orange, 1250000, 1500000),
    _Cat('Transport', Icons.directions_car_rounded, KColors.blue, 420000, 600000),
    _Cat('Xaridlar', Icons.shopping_bag_rounded, KColors.danger, 980000, 800000),
    _Cat('Kommunal', Icons.bolt_rounded, KColors.purple, 540000, 700000),
    _Cat('Ko\'ngilochar', Icons.auto_awesome_rounded, KColors.primary, 310000, 500000),
  ];
}

class _Cat {
  final String name;
  final IconData icon;
  final Color color;
  final double spent, limit;
  const _Cat(this.name, this.icon, this.color, this.spent, this.limit);
}

class _Hero extends StatelessWidget {
  final double remaining, spent, limit, pct;
  const _Hero({
    required this.remaining,
    required this.spent,
    required this.limit,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final w90 = Colors.white.withValues(alpha: 0.9);
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Qolgan mablag'",
                        style: k(13, w: FontWeight.w500, c: w90)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(Money.plain(remaining, currency: 'UZS'),
                                style:
                                    k(28, w: FontWeight.w700, c: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text("so'm",
                              style: k(14, w: FontWeight.w500, c: w90)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                    height: 8, color: Colors.white.withValues(alpha: 0.28)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 8, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Sarflandi: ${Money.plain(spent, currency: 'UZS')}',
                  style: k(12, w: FontWeight.w500, c: w90)),
              const Spacer(),
              Text('Limit: ${Money.plain(limit, currency: 'UZS')}',
                  style: k(12, w: FontWeight.w500, c: w90)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final _Cat data;
  const _BudgetRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.spent / data.limit;
    final over = pct > 1.0;
    final pctColor = over ? KColors.danger : data.color;

    return KCard(
      child: Row(
        children: [
          KTintedIcon(icon: data.icon, color: data.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.name, style: k(14, w: FontWeight.w600)),
                    const Spacer(),
                    Text('${(pct * 100).round()}%',
                        style: k(13, w: FontWeight.w600, c: pctColor)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  over
                      ? 'Limitdan oshgan'
                      : '${Money.plain(data.spent, currency: 'UZS')} / ${Money.plain(data.limit, currency: 'UZS')}',
                  style: k(12, c: over ? KColors.danger : KColors.mut),
                ),
                const SizedBox(height: 8),
                KProgressBar(pct: pct, color: data.color, height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _soon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tez orada')),
  );
}
