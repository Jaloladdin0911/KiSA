import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kit.dart';
import 'lock_screen.dart';

/// Xavfsizlik — PIN-kod va biometrik qulfni boshqarish.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

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
                          child: Text('Xavfsizlik',
                              style: k(17, w: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: kPad,
                  child: KCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _toggle(
                          Icons.lock_outline_rounded,
                          KColors.primary,
                          'PIN-kod',
                          provider.pinEnabled,
                          (v) async {
                            if (v) {
                              await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const PinSetupScreen()));
                            } else {
                              provider.disablePin();
                            }
                          },
                        ),
                        if (provider.pinEnabled) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 60),
                            child: Divider(
                                height: 1, thickness: 1, color: KColors.line),
                          ),
                          _row(
                            Icons.password_rounded,
                            KColors.blue,
                            "PIN-kodni o'zgartirish",
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const PinSetupScreen())),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 60),
                            child: Divider(
                                height: 1, thickness: 1, color: KColors.line),
                          ),
                          _toggle(
                            Icons.fingerprint_rounded,
                            KColors.purple,
                            'Face ID / Touch ID',
                            provider.biometricEnabled,
                            (v) => provider.setBiometric(v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: kPad,
                  child: Text(
                    provider.pinEnabled
                        ? 'Ilova har ochilganda PIN-kod so\'raydi.'
                        : 'PIN-kod yoqilsa, ilova ochilganda kod so\'raladi.',
                    style: k(12.5, c: KColors.sub, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(IconData icon, Color color, String label,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            KTintedIcon(icon: icon, color: color, size: 32, circle: false),
            const SizedBox(width: 14),
            Text(label, style: k(14, w: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: KColors.mut),
          ],
        ),
      ),
    );
  }

  Widget _toggle(IconData icon, Color color, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          KTintedIcon(icon: icon, color: color, size: 32, circle: false),
          const SizedBox(width: 14),
          Text(label, style: k(14, w: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? KColors.primary : const Color(0xFFD7DBE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
