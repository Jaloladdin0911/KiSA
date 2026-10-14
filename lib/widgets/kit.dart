import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

export 'glass.dart';

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
    final card = Glass(
      padding: padding,
      color: color,
      borderRadius: BorderRadius.circular(radius),
      shadow: shadow,
      child: child,
    );
    if (onTap == null) return card;
    return KPressable(onTap: onTap, scale: 0.97, child: card);
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
  final String? label; // ekran o'quvchisi uchun
  const KIconButton(
      {super.key,
      required this.icon,
      required this.onTap,
      this.iconColor,
      this.label});

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      scale: 0.9,
      semanticLabel: label,
      child: Glass(
        blur: true,
        sigma: 16,
        borderRadius: BorderRadius.circular(rTile),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: iconColor ?? KColors.ink),
        ),
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
    return KPressable(
      onTap: onTap,
      scale: 0.88,
      child: Glass(
        tint: kGradient,
        borderRadius: BorderRadius.circular(rTile),
        shadow: kGreenShadow,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_rounded, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

/// Segmentli tanlagich — botgan trek ichida shisha "tomchi" tanlangan
/// variantga prujina bilan siljiydi. [colors] berilsa, har variantning
/// faol matn rangi alohida (masalan Chiqim — qizil, Kirim — yashil).
class KSegmented extends StatelessWidget {
  final List<(String, String)> options; // (qiymat, yorliq)
  final String value;
  final ValueChanged<String> onChanged;
  final List<Color>? colors;
  final double height;

  const KSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.colors,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final idx = options.indexWhere((o) => o.$1 == value).clamp(0, 99);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KColors.bg,
        borderRadius: BorderRadius.circular(rTile),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / options.length;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: KMotion.spring,
                left: idx * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Glass(
                  color: KColors.raised,
                  borderRadius: BorderRadius.circular(rTile - 4),
                  child: const SizedBox.expand(),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: KPressable(
                        scale: 0.94,
                        onTap: () => onChanged(options[i].$1),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: KMotion.fast,
                            style: k(14,
                                w: i == idx
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                c: i == idx
                                    ? (colors?[i] ?? KColors.ink)
                                    : KColors.sub),
                            child: Text(options[i].$2,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Asosiy CTA — gradient shisha tugma (Saqlash, Yaratish...).
class KPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  const KPrimaryButton(
      {super.key, required this.label, required this.onTap, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      scale: 0.97,
      child: Glass(
        tint: kGradient,
        borderRadius: BorderRadius.circular(rBtn),
        shadow: kGreenShadow,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Center(
            child: Text(label,
                style: k(16, w: FontWeight.w600, c: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// Orqaga tugma (40px oq doira, chevron-left).
class KBackButton extends StatelessWidget {
  const KBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: () => Navigator.maybePop(context),
      scale: 0.88,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      child: Glass(
        blur: true,
        sigma: 16,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left_rounded,
              size: 24, color: KColors.ink),
        ),
      ),
    );
  }
}

/// Doira shisha tugma (yopish ×, o'chirish va h.k.).
class KCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? bg;
  final String? label; // ekran o'quvchisi uchun
  const KCircleButton(
      {super.key,
      required this.icon,
      required this.onTap,
      this.color,
      this.bg,
      this.label});

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: onTap,
      scale: 0.88,
      semanticLabel: label ??
          (icon == Icons.close_rounded
              ? MaterialLocalizations.of(context).closeButtonTooltip
              : null),
      child: Glass(
        blur: bg == null,
        sigma: 16,
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: color ?? KColors.ink),
        ),
      ),
    );
  }
}
