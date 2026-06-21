import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// KiSA dizayn tizimi — barcha ranglar, tipografiya, masofa, radius va
/// soyalar shu yerda markazlashgan. Ekranlar faqat shu tokenlardan
/// foydalanadi, shunda butun ilova bir xil, professional ko'rinishga ega bo'ladi.

// ─── Ranglar ──────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Brend — KiSA teal-yashil (ilova ikonkasi bilan mos)
  static const brand = Color(0xFF099268);
  static const brandDark = Color(0xFF087F5B);
  static const brandDeep = Color(0xFF0B7285);
  static const brandSoft = Color(0xFF20C997);

  // Semantik
  static const income = Color(0xFF2F9E44);
  static const expense = Color(0xFFE8590C);
  static const warning = Color(0xFFF59F00);
  static const info = Color(0xFF099268);
  static const violet = Color(0xFF7048E8);

  // ── Light ──
  static const lBg = Color(0xFFEFF2F9);
  static const lSurface = Color(0xFFFFFFFF);
  static const lSurfaceAlt = Color(0xFFEEF1F8);
  static const lBorder = Color(0xFFE5E9F2);
  static const lTextPrimary = Color(0xFF1B2440);
  static const lTextSecondary = Color(0xFF6B7686);
  static const lTextTertiary = Color(0xFF9AA4B2);

  // ── Dark ──
  static const dBg = Color(0xFF0A0F16);
  static const dSurface = Color(0xFF141C26);
  static const dSurfaceAlt = Color(0xFF1C2733);
  static const dBorder = Color(0xFF26323F);
  static const dTextPrimary = Color(0xFFF4F7FA);
  static const dTextSecondary = Color(0xFF93A1B0);
  static const dTextTertiary = Color(0xFF5C6A78);

  // Gradientlar
  static const balanceGradientLight = [Color(0xFF12B886), Color(0xFF0C8599)];
  static const balanceGradientDark = [Color(0xFF099268), Color(0xFF0B4F5E)];
}

/// Mavzuga (light/dark) bog'liq palitra — `context.c` orqali olinadi.
class AppPalette {
  final bool isDark;
  const AppPalette(this.isDark);

  Color get bg => isDark ? AppColors.dBg : AppColors.lBg;
  Color get surface => isDark ? AppColors.dSurface : AppColors.lSurface;
  Color get surfaceAlt => isDark ? AppColors.dSurfaceAlt : AppColors.lSurfaceAlt;
  Color get border => isDark ? AppColors.dBorder : AppColors.lBorder;
  Color get textPrimary => isDark ? AppColors.dTextPrimary : AppColors.lTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.dTextSecondary : AppColors.lTextSecondary;
  Color get textTertiary =>
      isDark ? AppColors.dTextTertiary : AppColors.lTextTertiary;
  List<Color> get balanceGradient =>
      isDark ? AppColors.balanceGradientDark : AppColors.balanceGradientLight;
}

// ─── O'lchamlar ─────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 100.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const screen = 20.0; // ekran chetidan masofa
}

// ─── Soyalar ───────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(bool isDark) => isDark
      ? const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0F1B2A4A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];

  static List<BoxShadow> brand(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

// ─── Tema ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static const _font = 'Poppins';

  static SystemUiOverlayStyle overlayStyle(bool isDark) => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? AppColors.dBg : AppColors.lSurface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      );

  static ThemeData light() => _build(false);
  static ThemeData dark() => _build(true);

  static ThemeData _build(bool isDark) {
    final p = AppPalette(isDark);
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    final textTheme = _textTheme(base.textTheme, p).apply(fontFamily: _font);

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      primaryColor: AppColors.brand,
      dividerColor: p.border,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
        primary: AppColors.brand,
        secondary: AppColors.brandDeep,
        surface: p.surface,
        error: AppColors.expense,
        onPrimary: Colors.white,
        onSurface: p.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle(isDark),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardColor: p.surface,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.dSurfaceAlt : AppColors.lTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.textTertiary, fontSize: 14.5),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 14.5),
        floatingLabelStyle: const TextStyle(
            color: AppColors.brand, fontWeight: FontWeight.w600),
        prefixIconColor: p.textTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: textTheme.titleMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppPalette p) {
    TextStyle s(double size, FontWeight w,
            {Color? color, double? height, double? spacing}) =>
        TextStyle(
          fontFamily: _font,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: spacing,
          color: color ?? p.textPrimary,
        );

    return base.copyWith(
      displaySmall: s(32, FontWeight.w800, spacing: -0.5),
      headlineMedium: s(26, FontWeight.w800, spacing: -0.4),
      headlineSmall: s(22, FontWeight.w700, spacing: -0.3),
      titleLarge: s(19, FontWeight.w700, spacing: -0.2),
      titleMedium: s(16, FontWeight.w700),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(15, FontWeight.w500, height: 1.4),
      bodyMedium: s(14, FontWeight.w400, color: p.textSecondary, height: 1.45),
      bodySmall: s(12.5, FontWeight.w400, color: p.textSecondary, height: 1.4),
      labelLarge: s(14, FontWeight.w600),
      labelSmall: s(11.5, FontWeight.w600, color: p.textTertiary, spacing: 0.3),
    );
  }
}

// ─── Qulay kirish kengaytmalari ───────────────────────────────────────────────

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppPalette get c => AppPalette(isDark);
  TextTheme get t => Theme.of(this).textTheme;
}
