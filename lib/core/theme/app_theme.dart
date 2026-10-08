import 'package:flutter/material.dart';

enum NonogramThemeMode {
  classicPaper,
  midnight,
  ocean,
  highContrast;

  String get displayName {
    switch (this) {
      case NonogramThemeMode.classicPaper:
        return 'Classic Paper';
      case NonogramThemeMode.midnight:
        return 'Midnight';
      case NonogramThemeMode.ocean:
        return 'Ocean';
      case NonogramThemeMode.highContrast:
        return 'High Contrast';
    }
  }

  static NonogramThemeMode fromString(String val) {
    switch (val.toLowerCase()) {
      case 'classicpaper':
      case 'paper':
        return NonogramThemeMode.classicPaper;
      case 'midnight':
      case 'dark':
        return NonogramThemeMode.midnight;
      case 'ocean':
        return NonogramThemeMode.ocean;
      case 'highcontrast':
        return NonogramThemeMode.highContrast;
      default:
        return NonogramThemeMode.classicPaper;
    }
  }
}

/// Palette tokens specific to the Nonogram grid and gameplay elements.
class PuzzleColors {
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;

  // Grid specific
  final Color gridBorder;
  final Color gridMajorLine;
  final Color gridMinorLine;
  final Color cellEmpty;
  final Color cellFilled;
  final Color cellCrossed;
  final Color cellActiveHighlight;
  final Color clueBackground;
  final Color clueActiveBackground;
  final Color clueText;
  final Color clueCompletedText;
  final Color mistakeFlash;
  final Color successGlow;

  const PuzzleColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.gridBorder,
    required this.gridMajorLine,
    required this.gridMinorLine,
    required this.cellEmpty,
    required this.cellFilled,
    required this.cellCrossed,
    required this.cellActiveHighlight,
    required this.clueBackground,
    required this.clueActiveBackground,
    required this.clueText,
    required this.clueCompletedText,
    required this.mistakeFlash,
    required this.successGlow,
  });

  static const classicPaper = PuzzleColors(
    background: Color(0xFFF9F6F0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF2C3E50),
    accent: Color(0xFFE67E22),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    gridBorder: Color(0xFF1E293B),
    gridMajorLine: Color(0xFF334155),
    gridMinorLine: Color(0xFFCBD5E1),
    cellEmpty: Color(0xFFFFFFFF),
    cellFilled: Color(0xFF1E293B),
    cellCrossed: Color(0xFF94A3B8),
    cellActiveHighlight: Color(0xFFE2E8F0),
    clueBackground: Color(0xFFF1F5F9),
    clueActiveBackground: Color(0xFFE2E8F0),
    clueText: Color(0xFF0F172A),
    clueCompletedText: Color(0xFF94A3B8),
    mistakeFlash: Color(0xFFEF4444),
    successGlow: Color(0xFF10B981),
  );

  static const midnight = PuzzleColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    primary: Color(0xFF38BDF8),
    accent: Color(0xFF818CF8),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    gridBorder: Color(0xFF38BDF8),
    gridMajorLine: Color(0xFF64748B),
    gridMinorLine: Color(0xFF334155),
    cellEmpty: Color(0xFF1E293B),
    cellFilled: Color(0xFF38BDF8),
    cellCrossed: Color(0xFF64748B),
    cellActiveHighlight: Color(0xFF1E3A5F),
    clueBackground: Color(0xFF0B132B),
    clueActiveBackground: Color(0xFF1E3A5F),
    clueText: Color(0xFFF8FAFC),
    clueCompletedText: Color(0xFF475569),
    mistakeFlash: Color(0xFFF43F5E),
    successGlow: Color(0xFF34D399),
  );

  static const ocean = PuzzleColors(
    background: Color(0xFF0C2438),
    surface: Color(0xFF133652),
    primary: Color(0xFF14B8A6),
    accent: Color(0xFF06B6D4),
    textPrimary: Color(0xFFF0FDFA),
    textSecondary: Color(0xFF99F6E4),
    gridBorder: Color(0xFF14B8A6),
    gridMajorLine: Color(0xFF0D9488),
    gridMinorLine: Color(0xFF1F4E6E),
    cellEmpty: Color(0xFF133652),
    cellFilled: Color(0xFF2DD4BF),
    cellCrossed: Color(0xFF5EEAD4),
    cellActiveHighlight: Color(0xFF184E77),
    clueBackground: Color(0xFF081C2C),
    clueActiveBackground: Color(0xFF184E77),
    clueText: Color(0xFFCCFBF1),
    clueCompletedText: Color(0xFF4B6B82),
    mistakeFlash: Color(0xFFFB7185),
    successGlow: Color(0xFF10B981),
  );

  static const highContrast = PuzzleColors(
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    primary: Color(0xFFFFD700),
    accent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    gridBorder: Color(0xFFFFFFFF),
    gridMajorLine: Color(0xFFFFFFFF),
    gridMinorLine: Color(0xFF777777),
    cellEmpty: Color(0xFF000000),
    cellFilled: Color(0xFFFFD700),
    cellCrossed: Color(0xFFFFFFFF),
    cellActiveHighlight: Color(0xFF333333),
    clueBackground: Color(0xFF1A1A1A),
    clueActiveBackground: Color(0xFF444444),
    clueText: Color(0xFFFFFFFF),
    clueCompletedText: Color(0xFF666666),
    mistakeFlash: Color(0xFFFF0055),
    successGlow: Color(0xFF00FF88),
  );

  static PuzzleColors getPalette(NonogramThemeMode mode) {
    switch (mode) {
      case NonogramThemeMode.classicPaper:
        return classicPaper;
      case NonogramThemeMode.midnight:
        return midnight;
      case NonogramThemeMode.ocean:
        return ocean;
      case NonogramThemeMode.highContrast:
        return highContrast;
    }
  }
}

/// App ThemeData builder from theme palette.
class AppTheme {
  static ThemeData getThemeData(NonogramThemeMode mode) {
    final colors = PuzzleColors.getPalette(mode);
    final isDark = mode != NonogramThemeMode.classicPaper;

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: colors.accent,
        onSecondary: Colors.white,
        error: colors.mistakeFlash,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
    );
  }
}
