import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Xush kelibsiz / Onboarding — KISA_DESIGN_SPEC.md, Section 3.
/// Birinchi ishga tushishda ko'rsatiladi. "Boshlash" → asosiy ilova.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.bg,
      body: SafeArea(
        child: Padding(
          padding: kPad,
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Bezakli halqalar + logo
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
                    _logoTile(),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Sarlavha
              Text(
                'Pul nazorati endi\njuda oson',
                textAlign: TextAlign.center,
                style: k(26, w: FontWeight.w700, height: 1.25),
              ),
              const SizedBox(height: 14),
              Text(
                'KiSA bilan hisob, byudjet va\nmaqsadlar — bitta ilovada.',
                textAlign: TextAlign.center,
                style: k(14.5, c: KColors.sub, height: 1.4),
              ),

              const Spacer(flex: 3),

              // Sahifa nuqtalari
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 8,
                    decoration: BoxDecoration(
                      color: KColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _dot(),
                  const SizedBox(width: 6),
                  _dot(),
                ],
              ),
              const SizedBox(height: 28),

              // CTA — Boshlash
              GestureDetector(
                onTap: () => _finish(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(rBtn),
                    boxShadow: kGreenShadow,
                  ),
                  child:
                      Text('Boshlash', style: k(16, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
              const SizedBox(height: 18),

              // Kirish havolasi (offline — to'g'ridan-to'g'ri asosiy ilovaga)
              GestureDetector(
                onTap: () => _finish(context),
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

  static Widget _dot() => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFCBD2DC),
          shape: BoxShape.circle,
        ),
      );

  static Widget _logoTile() => Container(
        width: 104,
        height: 104,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: kGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: kGreenShadow,
        ),
        child: Text('KiSA',
            style: k(30, w: FontWeight.w300, c: Colors.white, ls: 1)),
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
