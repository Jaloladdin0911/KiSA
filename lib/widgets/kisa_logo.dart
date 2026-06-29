import 'package:flutter/material.dart';

/// KiSA brend logosi — haqiqiy ilova ikonkasi (assets/icon/kisa-1024.png).
/// Splash, onboarding va lock ekranlarida ishlatiladi.
class KisaLogo extends StatelessWidget {
  final double size;
  const KisaLogo({super.key, this.size = 104});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15737F).withValues(alpha: 0.30),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/icon/kisa-1024.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
