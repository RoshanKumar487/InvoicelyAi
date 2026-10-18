import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1D68F0);
  static const blue = Color(0xFF1D68F0);
  static const teal = Color(0xFF0D9488);

  // Modern InvoicePro Theme
  static const brandNavy = Color(0xFF0B1736);
  static const brandNavyDark = Color(0xFF060E24);
  static const brandNavyCard = Color(0xFF0D1E45);
  static const brandBlue = Color(0xFF1D68F0);
  static const brandBlueLight = Color(0xFFEBF3FF);

  static const background = Color(0xFFF4F7FC);
  static const neuSurface = Color(0xFFFFFFFF);
  static const neuRecessed = Color(0xFFF1F5F9);
  static const neuShadowDark = Color(0x140F172A);
  static const neuShadowLight = Color(0xFFFFFFFF);
  static const neuActiveDark = Color(0xFF0B1736);

  static const darkBackground = Color(0xFF0B1120);
  static const darkSurface = Color(0xFF151F33);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const subtle = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const paid = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const overdue = Color(0xFFEF4444);
}

class AppTheme {
  AppTheme._();

  /// Crisp, modern card decoration with soft elevation shadow and subtle border
  static BoxDecoration neuCardDecoration({
    double radius = 20,
    Color? color,
    bool selected = false,
    Color? accentColor,
    Color? borderColor,
  }) {
    final baseColor = color ?? Colors.white;
    final activeAccent = accentColor ?? AppColors.brandBlue;
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (selected
                ? activeAccent.withValues(alpha: 0.6)
                : const Color(0xFFE2E8F0)),
        width: selected ? 1.5 : 1.0,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: activeAccent.withValues(alpha: 0.16),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
              const BoxShadow(
                color: Color(0x060F172A),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x080F172A),
                offset: Offset(0, 3),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Color(0x040F172A),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
    );
  }

  /// Pill-shaped modern button or chip decoration
  static BoxDecoration neuPillDecoration({
    double radius = 24,
    Color? color,
    bool active = false,
    bool isActive = false,
    Color? activeColor,
  }) {
    final isSelected = active || isActive;
    if (isSelected) {
      final fill = activeColor ?? AppColors.brandBlue;
      final isWhiteOrLight = fill.computeLuminance() > 0.6;
      return BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isWhiteOrLight ? const Color(0xFFCBD5E1) : Colors.transparent,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isWhiteOrLight
                ? const Color(0x0E0F172A)
                : fill.withValues(alpha: 0.28),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060F172A),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// Circular / squircle icon orb decoration
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
        ? (activeColor ?? AppColors.brandBlueLight)
        : (color ?? Colors.white);
    return BoxDecoration(
      color: fill,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      border: Border.all(
        color: isSelected
            ? AppColors.brandBlue.withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0),
        width: 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// Softly recessed well decoration for inputs, segmented tracks, and badges
  static BoxDecoration neuRecessedDecoration({
    double radius = 14,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
        selectedColor: const Color(0xFFE2E8F0),
        secondarySelectedColor: const Color(0xFFE2E8F0),
        labelStyle: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(
          color: isLight ? const Color(0xFFCBD5E1) : Colors.white12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
