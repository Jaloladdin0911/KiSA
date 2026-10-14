import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KiSA dizayn tizimi — "Liquid Glass". Barcha ranglar, tipografiya, masofa,
/// radius, soyalar va harakat (motion) shu yerda markazlashgan. Ekranlar
/// faqat shu tokenlardan foydalanadi: yuzalar shaffof shisha, ostida esa
/// global harakatlanuvchi aurora fon (widgets/glass.dart) ko'rinib turadi.

class KColors {
  KColors._();

  /// Joriy tema (main.dart'da provider bilan ulanadi). Getterlar shunga qarab
  /// yorug'/quyuq rang qaytaradi — butun ilova avtomatik moslashadi.
  static bool isDark = false;

  // ── Fon (aurora ostidagi asosiy rang) ──────────────────────────────────────
  static Color get base =>
      isDark ? const Color(0xFF060A12) : const Color(0xFFE8F0F3);

  // ── Shisha yuzalar ─────────────────────────────────────────────────────────
  /// Shisha karta / panel to'ldirgichi (shaffof).
  static Color get card =>
      isDark ? const Color(0x17FFFFFF) : const Color(0x8CFFFFFF);

  /// Ko'proq to'q shisha — pastki oyna, dialog, navigatsiya paneli.
  static Color get sheet =>
      isDark ? const Color(0xCC111722) : const Color(0xD9F7FAFB);

  /// Bo'rtib turgan element — tanlangan segment, toggle tugmachasi.
  static Color get raised =>
      isDark ? const Color(0x33FFFFFF) : const Color(0xF2FFFFFF);

  /// Ichkariga botgan maydon — input, chip, segment treki.
  static Color get bg =>
      isDark ? const Color(0x0FFFFFFF) : const Color(0x0D0F172A);

  /// Shisha chegarasi (yuqori yorug' qirra → pastki xira qirra).
  static Color get rimTop =>
      isDark ? const Color(0x3DFFFFFF) : const Color(0xE6FFFFFF);
  static Color get rimBottom =>
      isDark ? const Color(0x0AFFFFFF) : const Color(0x40FFFFFF);

  static const dark = Color(0xFF14161F); // quyuq summary karta (har ikkalada)

  // ── Matn ───────────────────────────────────────────────────────────────────
  static Color get ink =>
      isDark ? const Color(0xFFF3F6FA) : const Color(0xFF0B1424);
  static Color get sub =>
      isDark ? const Color(0xFFA3ADBD) : const Color(0xFF5B6576);
  static Color get mut =>
      isDark ? const Color(0xFF6E7888) : const Color(0xFF8B94A3);
  static Color get line =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x120F172A);

  // ── KiSA brend ─────────────────────────────────────────────────────────────
  static const primary = Color(0xFF1C9D67); // yashil aksent
  static const gradStart = Color(0xFF15737F); // teal (gradient past-chap)
  static const gradMid = Color(0xFF1C8A74);
  static const gradEnd = Color(0xFF2FA169); // yashil (gradient yuqori-o'ng)
  static Color get greenBg => primary.withValues(alpha: isDark ? 0.22 : 0.14);

  // ── Semantik / kategoriya ──────────────────────────────────────────────────
  static const danger = Color(0xFFF2585B);
  static Color get dangerBg => danger.withValues(alpha: isDark ? 0.2 : 0.12);
  static const orange = Color(0xFFFF8B3D);
  static Color get orangeBg => orange.withValues(alpha: 0.14);
  static const blue = Color(0xFF4C8DFF);
  static Color get blueBg => blue.withValues(alpha: 0.14);
  static const purple = Color(0xFF8B5CF6);
  static Color get purpleBg => purple.withValues(alpha: 0.14);
  static const pink = Color(0xFFEC4899);
  static Color get pinkBg => pink.withValues(alpha: 0.14);
  static const indigo = Color(0xFF6366F1);
  static Color get indigoBg => indigo.withValues(alpha: 0.14);

  /// Aurora fon dog'lari (yorug' / quyuq tema).
  static List<Color> get aurora => isDark
      ? const [
          Color(0xFF0F766E), // teal
          Color(0xFF4338CA), // indigo
          Color(0xFF7C3AED), // binafsha
          Color(0xFF047857), // yashil
        ]
      : const [
          Color(0xFF7DDBC0), // yalpiz
          Color(0xFF93C5FD), // osmon
          Color(0xFFC4B5FD), // lavanda
          Color(0xFFFDE68A), // shaftoli-sariq
        ];
}

/// KiSA signature gradienti (logo, balans kartasi, asosiy CTA, FAB).
const kGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF15737F), Color(0xFF1C8A74), Color(0xFF2FA169)],
  stops: [0.0, 0.55, 1.0],
);

/// false bo'lsa Inter yuklanmaydi, tizim shrifti ishlatiladi — widget
/// testlarida tarmoq/shrift fayli yo'q bo'lgani uchun.
bool kUseGoogleFonts = true;

/// Tipografiya yordamchisi — Inter (google_fonts). Offline birinchi ishga
/// tushishda tizim shriftiga zaxiraga tushadi, keyin keshlanadi.
TextStyle k(
  double size, {
  FontWeight w = FontWeight.w400,
  Color? c,
  double? ls,
  double? height,
}) {
  final style = TextStyle(
    fontSize: size,
    fontWeight: w,
    color: c ?? KColors.ink,
    // Katta sarlavhalar biroz zichroq — zamonaviy ko'rinish
    letterSpacing: ls ?? (size >= 20 ? -0.4 : null),
    height: height,
  );
  return kUseGoogleFonts ? GoogleFonts.inter(textStyle: style) : style;
}

// Radii
const rCardLg = 28.0; // katta kartalar
const rCard = 22.0; // standart kartalar / qatorlar
const rBalance = 32.0; // balans hero kartasi
const rBtn = 18.0; // tugmalar
const rTile = 16.0; // ikon tugmalar / inputlar
const rIconSq = 10.0; // kichik tint ikon kvadratchalar

// Sahifa padding
const kPad = EdgeInsets.symmetric(horizontal: 20);

// Soyalar — shisha ostidan ko'rinib qolmasligi uchun juda yengil va keng
const kSoftShadow = [
  BoxShadow(color: Color(0x0A0B1424), offset: Offset(0, 8), blurRadius: 24),
];
const kCardShadow = [
  BoxShadow(color: Color(0x0F0B1424), offset: Offset(0, 12), blurRadius: 32),
];
const kGreenShadow = [
  BoxShadow(color: Color(0x4D15737F), offset: Offset(0, 14), blurRadius: 28),
];
const kFabShadow = [
  BoxShadow(color: Color(0x6615737F), offset: Offset(0, 10), blurRadius: 22),
];

// ── Harakat (motion) ──────────────────────────────────────────────────────────

class KMotion {
  KMotion._();

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);

  /// Yumshoq "prujina" — biroz oshib ketib joyiga qaytadi.
  static const spring = Cubic(0.34, 1.36, 0.64, 1.0);

  /// Tez boshlanib, silliq to'xtaydi (iOS uslubi).
  static const emphasized = Cubic(0.2, 0.9, 0.1, 1.0);
}

/// Sahifa o'tishlari. Sahifalar shaffof (ostida umumiy aurora fon), shuning
/// uchun ostidagi sahifa yangi sahifa ochilayotganda xiralashib yo'qoladi —
/// aks holda ikki sahifa matni ustma-ust ko'rinardi. iOS'da tizim surish
/// (swipe-back) imo-ishorasi saqlanadi.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    final Widget incoming;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      incoming = _cupertino.buildTransitions(
          route, context, animation, secondaryAnimation, child);
    } else {
      final curved = CurvedAnimation(
        parent: animation,
        curve: KMotion.emphasized,
        reverseCurve: Curves.easeInCubic,
      );
      incoming = FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        ),
      );
    }
    // Ustidan yangi sahifa ochilganda bu sahifa xiralashadi va biroz kichrayadi
    final covered = CurvedAnimation(
        parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(covered),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.97).animate(covered),
        child: incoming,
      ),
    );
  }
}

/// Butun ilova uchun ThemeData — shaffof scaffold, shisha dialog/snackbar.
ThemeData kTheme(bool dark) {
  final brightness = dark ? Brightness.dark : Brightness.light;
  const transitions = GlassPageTransitionsBuilder();
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KColors.primary,
      primary: KColors.primary,
      brightness: brightness,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: transitions,
      TargetPlatform.iOS: transitions,
      TargetPlatform.macOS: transitions,
      TargetPlatform.windows: transitions,
      TargetPlatform.linux: transitions,
      TargetPlatform.fuchsia: transitions,
    }),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          dark ? const Color(0xE61B2230) : const Color(0xE60B1424),
      contentTextStyle: k(13.5, w: FontWeight.w500, c: Colors.white),
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rTile)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KColors.sheet,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rCardLg),
        side: BorderSide(color: KColors.rimTop, width: 1),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: KColors.sheet,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCardLg)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: KColors.sheet,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCardLg)),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: KColors.primary,
    ),
  );
}
