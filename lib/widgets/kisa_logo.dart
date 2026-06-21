import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// KiSA brend belgisi — haqiqiy ilova ikonkasi (teal gradient).
/// Yumaloq burchakli kvadrat ichida brend logosi ko'rsatiladi.
class KisaLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const KisaLogo({super.key, this.size = 80, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow ? AppShadows.brand(AppColors.brand) : null,
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
