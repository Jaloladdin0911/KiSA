import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kit.dart';

/// Birinchi ishga tushish — 3 sahifali tanishtiruv. Har sahifada suzuvchi
/// shisha illyustratsiya (parallaks bilan), pastda suyuq sahifa ko'rsatkichi.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _page = PageController();
  late final AnimationController _float = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();
  double _pos = 0;

  static const _slides = [
    (Icons.account_balance_wallet_rounded, KColors.primary, Icons.payments_rounded,
        Icons.credit_card_rounded),
    (Icons.donut_large_rounded, KColors.blue, Icons.bar_chart_rounded,
        Icons.notifications_active_rounded),
    (Icons.flag_rounded, KColors.purple, Icons.savings_rounded,
        Icons.emoji_events_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _page.addListener(() => setState(() => _pos = _page.page ?? 0));
  }

  @override
  void dispose() {
    _page.dispose();
    _float.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pushReplacementNamed('/register');

  void _next() {
    final i = _pos.round();
    if (i >= _slides.length - 1) {
      _finish();
    } else {
      _page.animateToPage(i + 1,
          duration: KMotion.slow, curve: KMotion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().s;
    final last = _pos.round() == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: KMotion.fast,
                child: KPressable(
                  onTap: last ? null : _finish,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 24, 8),
                    child: Text(s('skip'),
                        style: k(14, w: FontWeight.w600, c: KColors.sub)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final offset = (i - _pos).clamp(-1.0, 1.0);
                  return _Slide(
                    data: _slides[i],
                    title: s('ob${i + 1}_title'),
                    subtitle: s('ob${i + 1}_sub'),
                    offset: offset,
                    float: _float,
                  );
                },
              ),
            ),
            _Dots(count: _slides.length, position: _pos),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: KPrimaryButton(
                label: last ? s('start') : s('next'),
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final (IconData, Color, IconData, IconData) data;
  final String title, subtitle;
  final double offset; // -1..1, sahifa markazdan qancha siljigan
  final Animation<double> float;

  const _Slide({
    required this.data,
    required this.title,
    required this.subtitle,
    required this.offset,
    required this.float,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, a, b) = data;
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        const Spacer(),
        // Illyustratsiya matndan tezroq siljiydi — parallaks
        Transform.translate(
          offset: Offset(offset * w * 0.35, 0),
          child: AnimatedBuilder(
            animation: float,
            builder: (_, __) {
              final t = float.value * 2 * math.pi;
              return SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Yumshoq rangli nur
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          color.withValues(alpha: 0.35),
                          color.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                    // Asosiy shisha shar
                    Transform.translate(
                      offset: Offset(0, math.sin(t) * 6),
                      child: Glass(
                        blur: true,
                        borderRadius: BorderRadius.circular(70),
                        shadow: kCardShadow,
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Icon(icon, size: 62, color: color),
                        ),
                      ),
                    ),
                    // Atrofida suzuvchi kichik shisha pufakchalar
                    _orbit(a, color, t, 0, 92),
                    _orbit(b, color, t, math.pi, 100),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 36),
        Opacity(
          opacity: (1 - offset.abs() * 1.4).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(offset * w * 0.12, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: k(28, w: FontWeight.w700, height: 1.15)),
                  const SizedBox(height: 14),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: k(15, c: KColors.sub, height: 1.5)),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _orbit(IconData icon, Color color, double t, double phase, double r) {
    final a = t * 0.5 + phase;
    return Transform.translate(
      offset: Offset(math.cos(a) * r, math.sin(a) * r * 0.55),
      child: Glass(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Suyuq sahifa ko'rsatkichi — faol nuqta cho'zilib, keyingisiga "oqib" o'tadi.
class _Dots extends StatelessWidget {
  final int count;
  final double position;
  const _Dots({required this.count, required this.position});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Builder(builder: (_) {
            final d = (position - i).abs().clamp(0.0, 1.0);
            final active = 1 - d;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 + 20 * active,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                    KColors.mut.withValues(alpha: 0.35), KColors.primary, active),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
      ],
    );
  }
}
