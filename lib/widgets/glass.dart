import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// "Liquid Glass" qurilish bloklari: aurora fon, shisha panel, bosish
/// effekti, paydo bo'lish animatsiyasi va shisha pastki oyna / dialog.

// ── Aurora fon ────────────────────────────────────────────────────────────────

/// Butun ilova ortidagi sekin suzuvchi rangli dog'lar. Shisha yuzalar shu
/// ranglarni o'tkazib ko'rsatadi. Batareyani tejash uchun ~20 fps'da
/// yangilanadi, ilova fonda bo'lsa yoki tizimda "harakatni kamaytirish"
/// yoqilgan bo'lsa to'xtaydi.
class KAuroraBackground extends StatefulWidget {
  const KAuroraBackground({super.key});

  @override
  State<KAuroraBackground> createState() => _KAuroraBackgroundState();
}

class _KAuroraBackgroundState extends State<KAuroraBackground>
    with WidgetsBindingObserver {
  final _time = ValueNotifier<double>(0);
  Timer? _timer;
  final _clock = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _clock.start();
    _timer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      _time.value = _clock.elapsedMilliseconds / 1000.0;
    });
  }

  void _stop() {
    _clock.stop();
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(
          time: _time,
          base: KColors.base,
          colors: KColors.aurora,
          dark: KColors.isDark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final Color base;
  final List<Color> colors;
  final bool dark;

  _AuroraPainter({
    required this.time,
    required this.base,
    required this.colors,
    required this.dark,
  }) : super(repaint: time);

  // Har bir dog': boshlang'ich joy (0..1), harakat radiusi, tezlik, o'lcham
  static const _blobs = [
    (0.15, 0.10, 0.18, 0.050, 0.85),
    (0.90, 0.25, 0.22, 0.037, 0.75),
    (0.20, 0.70, 0.20, 0.043, 0.80),
    (0.85, 0.85, 0.16, 0.031, 0.70),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final t = time.value;
    final span = math.max(size.width, size.height);
    for (var i = 0; i < _blobs.length; i++) {
      final (x, y, r, speed, scale) = _blobs[i];
      final phase = t * speed * 2 * math.pi + i * 1.7;
      final c = Offset(
        size.width * (x + r * math.sin(phase)),
        size.height * (y + r * 0.6 * math.cos(phase * 0.8)),
      );
      final radius = span * scale * (0.9 + 0.1 * math.sin(phase * 1.3));
      final color = colors[i % colors.length];
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: dark ? 0.55 : 0.75),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.base != base || old.dark != dark || old.colors != colors;
}

// ── Shisha panel ─────────────────────────────────────────────────────────────

/// Shaffof shisha yuza: yarim shaffof to'ldirish, yuqori chap burchakdan
/// tushuvchi yorug'lik va yorug' qirra. [blur] true bo'lsa ortidagi kontent
/// haqiqatan xiralashtiriladi (navigatsiya, oynalar) — bu qimmatroq, shuning
/// uchun oddiy kartalarda o'chiq (aurora fon o'zi allaqachon yumshoq).
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool blur;
  final double sigma;
  final List<BoxShadow> shadow;
  final Gradient? tint;

  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(rCard)),
    this.padding,
    this.color,
    this.blur = false,
    this.sigma = 24,
    this.shadow = kSoftShadow,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    Widget surface = CustomPaint(
      foregroundPainter: _RimPainter(
        borderRadius: borderRadius,
        top: KColors.rimTop,
        bottom: KColors.rimBottom,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tint == null ? (color ?? KColors.card) : null,
          gradient: tint,
          borderRadius: borderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          // Shisha yaltirashi — yuqori chapdan yorug'lik
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.4, 0.6),
            colors: [
              Colors.white.withValues(alpha: KColors.isDark ? 0.07 : 0.28),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );

    if (blur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: surface,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}

/// Shisha qirrasi: yuqorida yorqin, pastga tomon so'nadigan 1px chiziq.
class _RimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color top, bottom;
  _RimPainter(
      {required this.borderRadius, required this.top, required this.bottom});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, bottom, top.withValues(alpha: top.a * 0.5)],
        stops: const [0, 0.6, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.top != top || old.bottom != bottom || old.borderRadius != borderRadius;
}

// ── Bosish effekti ───────────────────────────────────────────────────────────

/// Bosilganda biroz kichrayib, qo'yib yuborilganda prujina bilan qaytadi.
/// Mobil qurilmada yengil tebranish (haptic) ham beradi.
class KPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  /// Ekran o'quvchisi (TalkBack/VoiceOver) uchun tugma nomi — faqat ikonkali
  /// tugmalarda albatta beriladi.
  final String? semanticLabel;

  const KPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<KPressable> createState() => _KPressableState();
}

class _KPressableState extends State<KPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: _down ? KMotion.fast : KMotion.slow,
        curve: _down ? Curves.easeOut : KMotion.spring,
        child: widget.child,
      ),
    );
    if (widget.semanticLabel == null) return gesture;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: gesture,
    );
  }
}

// ── Paydo bo'lish ────────────────────────────────────────────────────────────

/// Bir marta: pastdan biroz ko'tarilib, xiralikdan aniq bo'ladi. Ro'yxat
/// bo'limlariga [delay] bilan navbatma-navbat (stagger) qo'llanadi.
class KFadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  const KFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 22,
  });

  /// [index] bo'yicha avtomatik kechikish (60 ms qadam).
  factory KFadeSlideIn.stagger(int index, {Key? key, required Widget child}) =>
      KFadeSlideIn(
          key: key,
          delay: Duration(milliseconds: 60 * index),
          child: child);

  @override
  State<KFadeSlideIn> createState() => _KFadeSlideInState();
}

class _KFadeSlideInState extends State<KFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: KMotion.slow);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: KMotion.emphasized);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) _c.value = 1;
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ── Shisha pastki oyna va dialog ─────────────────────────────────────────────

/// Pastki oyna — xiralashtirilgan shisha panel, silliq "suzib chiqish".
Future<T?> showKSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: KColors.isDark ? 0.45 : 0.18),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 260),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Glass(
        blur: true,
        sigma: 30,
        color: KColors.sheet,
        shadow: kCardShadow,
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        child: Material(type: MaterialType.transparency, child: builder(ctx)),
      ),
    ),
  );
}

/// Dialog — orqa fon xiralashadi, dialog esa prujina bilan kattalashib chiqadi.
Future<T?> showKDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final v = CurvedAnimation(
          parent: anim, curve: KMotion.spring, reverseCurve: Curves.easeIn);
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) => BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 12 * anim.value, sigmaY: 12 * anim.value),
                  child: ColoredBox(
                    color: Colors.black.withValues(
                        alpha: (KColors.isDark ? 0.4 : 0.15) * anim.value),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.88, end: 1.0).animate(v),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// Pastki oyna tepasidagi kichik tutqich.
class KSheetHandle extends StatelessWidget {
  const KSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: KColors.mut.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
