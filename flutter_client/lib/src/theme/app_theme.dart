import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1E3A8A);
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0D9488);

  // Realistic, lightweight Neumorphism pearl-alabaster palette
  static const background = Color(0xFFE6E9EF);
  static const neuSurface = Color(0xFFEAEEF5);
  static const neuRecessed = Color(0xFFDFE4EC);
  static const neuShadowDark = Color(0xFFC2C9D6);
  static const neuShadowLight = Color(0xFFFFFFFF);
  static const neuActiveDark = Color(0xFF2B3548);

  static const darkBackground = Color(0xFF0B1120);
  static const darkSurface = Color(0xFF151F33);
  static const text = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFD5DCE6);
  static const paid = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const overdue = Color(0xFFDC2626);
}

class AppTheme {
  AppTheme._();

  /// Raised Neumorphic card decoration with top-left white highlight & bottom-right cool-grey shadow
  static BoxDecoration neuCardDecoration({
    double radius = 22,
    Color? color,
    bool selected = false,
    Color? accentColor,
    Color? borderColor,
  }) {
    final baseColor = color ?? AppColors.neuSurface;
    final activeAccent = accentColor ?? AppColors.blue;
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (selected
                ? activeAccent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.85)),
        width: selected ? 1.6 : 1.1,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: activeAccent.withValues(alpha: 0.10),
                offset: const Offset(1, 2),
                blurRadius: 5,
              ),
              const BoxShadow(
                color: Color(0x80FFFFFF),
                offset: Offset(-1, -1),
                blurRadius: 4,
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x2EC2C9D6), // Ultra-soft subtle modern shadow
                offset: Offset(2, 2.5),
                blurRadius: 5,
              ),
              BoxShadow(
                color: Color(0x99FFFFFF),
                offset: Offset(-1.5, -1.5),
                blurRadius: 4,
              ),
            ],
    );
  }

  /// Pill-shaped Neumorphic row or button decoration
  static BoxDecoration neuPillDecoration({
    double radius = 28,
    Color? color,
    bool active = false,
    bool isActive = false,
    Color? activeColor,
  }) {
    final isSelected = active || isActive;
    if (isSelected) {
      final fill = activeColor ?? const Color(0xFF111827); // Rich pitch-slate black
      return BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(1, 2),
            blurRadius: 4,
          ),
          const BoxShadow(
            color: Color(0x40FFFFFF),
            offset: Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: color ?? AppColors.neuSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.88), width: 1.1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2EC2C9D6),
          offset: Offset(1.5, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Color(0x99FFFFFF),
          offset: Offset(-1.5, -1.5),
          blurRadius: 4,
        ),
      ],
    );
  }

  /// Circular / squircle Neumorphic icon orb decoration
  static BoxDecoration neuOrbDecoration({
    Color? color,
    bool active = false,
    bool isActive = false,
    Color? activeColor,
    BoxShape shape = BoxShape.circle,
    double radius = 14,
  }) {
    final isSelected = active || isActive;
    final fill = isSelected
        ? (activeColor ?? const Color(0xFF111827))
        : (color ?? AppColors.neuSurface);
    return BoxDecoration(
      color: fill,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      border: Border.all(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.90),
        width: 1.1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
              const BoxShadow(
                color: Color(0x40FFFFFF),
                offset: Offset(-1, -1),
                blurRadius: 2,
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x2EC2C9D6),
                offset: Offset(1.5, 1.5),
                blurRadius: 3.5,
              ),
              BoxShadow(
                color: Color(0x99FFFFFF),
                offset: Offset(-1.5, -1.5),
                blurRadius: 3.5,
              ),
            ],
    );
  }

  /// Softly recessed / inset well decoration for inputs, segmented bars, and badges
  static BoxDecoration neuRecessedDecoration({
    double radius = 16,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.neuRecessed,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFD0D7E2), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99FFFFFF),
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  static ThemeData get light => _createTheme(
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.neuSurface,
        foreground: AppColors.text,
      );

  static ThemeData get dark => _createTheme(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        foreground: Colors.white,
      );

  static ThemeData _createTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color foreground,
  }) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight ? Colors.white.withValues(alpha: 0.85) : Colors.white12,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.neuSurface : AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.white12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.neuRecessed : surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isLight ? const Color(0xFFCFD7E3) : Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? const Color(0xFFCFD7E3) : Colors.white24,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2B3548),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppColors.neuShadowDark,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLight ? AppColors.neuSurface : surface,
          foregroundColor: foreground,
          elevation: 3,
          shadowColor: AppColors.neuShadowDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.white12,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: isLight ? AppColors.neuSurface : surface,
          foregroundColor: foreground,
          side: BorderSide(
            color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.white24,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.neuSurface : surface,
        selectedColor: const Color(0xFF2B3548),
        secondarySelectedColor: const Color(0xFF2B3548),
        side: BorderSide(
          color: isLight ? Colors.white.withValues(alpha: 0.85) : Colors.white12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
