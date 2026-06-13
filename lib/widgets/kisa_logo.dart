import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// KiSA brend belgisi — zumrad gradientli yumaloq kvadrat ichida "KiSA" matni.
class KisaLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const KisaLogo({super.key, this.size = 80, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final fontSize = size * 0.30;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandSoft, AppColors.brandDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow ? AppShadows.brand(AppColors.brand) : null,
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Ki',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'SA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
