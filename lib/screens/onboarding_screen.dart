import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Xush kelibsiz / Onboarding — KISA_DESIGN_SPEC.md, Section 3.
/// 3 sahifali (swipe), birinchi ishga tushishda ko'rsatiladi.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(
      logoText: 'KiSA',
      title: 'Pul nazorati endi\njuda oson',
      subtitle: 'KiSA bilan hisob, byudjet va\nmaqsadlar — bitta ilovada.',
    ),
    _Page(
      icon: Icons.pie_chart_rounded,
      title: 'Byudjetni\nnazorat qiling',
      subtitle: "Har kategoriyaga limit qo'ying va\nxarajatlaringizni kuzating.",
    ),
    _Page(
      icon: Icons.flag_rounded,
      title: 'Maqsadlaringizga\neriching',
      subtitle: "Jamg'arma maqsadlari qo'ying va\nhar kuni yaqinlashing.",
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),

            // Sahifa nuqtalari
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? KColors.primary : const Color(0xFFCBD2DC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // CTA
            Padding(
              padding: kPad,
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(rBtn),
                    boxShadow: kGreenShadow,
                  ),
                  child: Text(_isLast ? 'Boshlash' : 'Keyingi',
                      style: k(16, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            GestureDetector(
              onTap: _finish,
              child: Text.rich(
                TextSpan(
                  text: 'Hisobingiz bormi? ',
                  style: k(14, c: KColors.sub),
                  children: [
                    TextSpan(
                      text: 'Kirish',
                      style: k(14, w: FontWeight.w600, c: KColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Page {
  final String? logoText;
  final IconData? icon;
  final String title, subtitle;
  const _Page({
    this.logoText,
    this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPad,
      child: Column(
        children: [
          const Spacer(flex: 3),
          SizedBox(
            height: 290,
            width: 290,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(290, KColors.gradEnd, 0.16),
                _ring(220, KColors.gradStart, 0.22),
                _ring(152, KColors.gradEnd, 0.38),
                const _AccentDot(top: 18, left: 40, color: KColors.gradEnd),
                const _AccentDot(
                    bottom: 30, right: 36, color: KColors.gradStart),
                const _AccentDot(top: 70, right: 22, color: KColors.gradEnd),
                Container(
                  width: 104,
                  height: 104,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: kGreenShadow,
                  ),
                  child: page.logoText != null
                      ? Text(page.logoText!,
                          style: k(30,
                              w: FontWeight.w300, c: Colors.white, ls: 1))
                      : Icon(page.icon, color: Colors.white, size: 46),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Text(page.title,
              textAlign: TextAlign.center,
              style: k(26, w: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 14),
          Text(page.subtitle,
              textAlign: TextAlign.center,
              style: k(14.5, c: KColors.sub, height: 1.4)),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  static Widget _ring(double d, Color color, double opacity) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: color.withValues(alpha: opacity), width: 1.5),
        ),
      );
}

class _AccentDot extends StatelessWidget {
  final double? top, bottom, left, right;
  final Color color;
  const _AccentDot({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
