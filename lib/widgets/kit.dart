import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// KiSA dizayn tizimi — qayta ishlatiladigan komponentlar (KISA_DESIGN_SPEC.md, Section 2).

/// Oq karta — yumshoq soya, yumaloq burchak.
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final List<BoxShadow> shadow;

  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = rCard,
    this.onTap,
    this.color,
    this.shadow = kSoftShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? KColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// Rangli tint ichidagi ikonka (kvadrat yoki doira).
class KTintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool circle;
  final Color? bg;

  const KTintedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.circle = true,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.13),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}

/// Progress bar — track + fill. 100% da chegaralanadi; limitdan oshsa danger.
class KProgressBar extends StatelessWidget {
  final double pct; // 0..1+ (1 dan oshsa over-budget)
  final Color color;
  final double height;
  final Color? track;

  const KProgressBar({
    super.key,
    required this.pct,
    required this.color,
    this.height = 6,
    this.track,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = pct.clamp(0.0, 1.0);
    final over = pct > 1.0;
    final fillColor = over ? KColors.danger : color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: track ?? KColors.line),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(height: height, color: fillColor),
          ),
        ],
      ),
    );
  }
}

/// Ekran sarlavhasi — chap tomonda nom (+ ixtiyoriy izoh), o'ngda amal.
class KPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const KPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: k(22, w: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: k(13, c: KColors.sub)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Oq yumaloq-kvadrat ikon tugma (header'dagi taqvim/bell uchun).
class KIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const KIconButton(
      {super.key, required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(rTile),
          boxShadow: kSoftShadow,
        ),
        child: Icon(icon, size: 21, color: iconColor ?? KColors.ink),
      ),
    );
  }
}

/// Yashil gradientli "+" tugma (header'dagi qo'shish uchun).
class KAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const KAddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: kGradient,
          borderRadius: BorderRadius.circular(rTile),
          boxShadow: kGreenShadow,
        ),
        child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
      ),
    );
  }
}

/// Orqaga tugma (40px oq doira, chevron-left).
class KBackButton extends StatelessWidget {
  const KBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: KColors.card,
          shape: BoxShape.circle,
          boxShadow: kSoftShadow,
        ),
        child: Icon(Icons.chevron_left_rounded,
            size: 24, color: KColors.ink),
      ),
    );
  }
}
