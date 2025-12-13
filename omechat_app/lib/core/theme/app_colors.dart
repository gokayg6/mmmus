import 'package:flutter/material.dart';

/// OmeChat Dark Orange Color Palette
/// No blue colors - only warm oranges and dark backgrounds
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════
  // CORE ORANGE PALETTE (NO BLUE ANYWHERE)
  // ═══════════════════════════════════════════════════════════
  
  /// Main neon-like orange - primary brand color
  static const Color primary = Color(0xFFFF7A1A);
  
  /// Darker orange for pressed states and depth
  static const Color primaryDark = Color(0xFFCC5C10);
  
  /// Softer glow orange for highlights
  static const Color primarySoft = Color(0xFFFFA94A);
  
  /// Very light orange for subtle accents
  static const Color primaryLight = Color(0xFFFFBE7A);
  
  /// Deep burnt orange
  static const Color primaryDeep = Color(0xFFE55A00);

  // ═══════════════════════════════════════════════════════════
  // BACKGROUND COLORS (WARM DARK)
  // ═══════════════════════════════════════════════════════════
  
  /// Almost black with warm undertone - main background
  static const Color background = Color(0xFF050304);
  
  /// Slightly lighter for cards and panels
  static const Color surface = Color(0xFF0C0808);
  
  /// Alternative surface for variation
  static const Color surfaceAlt = Color(0xFF151014);
  
  /// Elevated surface for modals
  static const Color surfaceElevated = Color(0xFF1A1215);
  
  /// Card background
  static const Color card = Color(0xFF100A0C);

  // ═══════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════
  
  /// Primary text - off-white with warm tint
  static const Color textPrimary = Color(0xFFF6F0E8);
  
  /// Secondary text - muted beige-grey
  static const Color textSecondary = Color(0xFFB3A89C);
  
  /// Muted/disabled text
  static const Color textMuted = Color(0xFF80746A);
  
  /// Hint text
  static const Color textHint = Color(0xFF5A504A);

  // ═══════════════════════════════════════════════════════════
  // LIGHT MODE COLORS
  // ═══════════════════════════════════════════════════════════
  
  /// Light mode background - warm white
  static const Color backgroundLight = Color(0xFFFFFBF5);
  
  /// Light mode surface
  static const Color surfaceLight = Color(0xFFFFF8F0);
  
  /// Light mode surface elevated
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  
  /// Light mode card
  static const Color cardLight = Color(0xFFFFF5EB);
  
  /// Light mode primary text - dark warm
  static const Color textPrimaryLight = Color(0xFF1A0A04);
  
  /// Light mode secondary text
  static const Color textSecondaryLight = Color(0xFF5A4030);
  
  /// Light mode muted text
  static const Color textMutedLight = Color(0xFF8A7060);

  // ═══════════════════════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════════════════════
  
  /// Success - warm green
  static const Color success = Color(0xFF30E19B);
  
  /// Error - warm red
  static const Color error = Color(0xFFFF4B4B);
  
  /// Warning - warm yellow
  static const Color warning = Color(0xFFFFC857);
  
  /// Online indicator
  static const Color online = Color(0xFF4ADE80);

  // ═══════════════════════════════════════════════════════════
  // GLASS & BLUR EFFECTS
  // ═══════════════════════════════════════════════════════════
  
  /// Glass container dark
  static const Color glassDark = Color(0x33000000);
  
  /// Glass container light
  static const Color glassLight = Color(0x1AFFFFFF);
  
  /// Glass border
  static const Color glassBorder = Color(0x33FFFFFF);

  // ═══════════════════════════════════════════════════════════
  // BORDERS & STROKES
  // ═══════════════════════════════════════════════════════════
  
  /// Soft white border (20% opacity)
  static const Color borderSoft = Color(0x33FFFFFF);
  
  /// Orange tinted border
  static const Color borderOrange = Color(0x33FF7A1A);
  
  /// Focused border
  static const Color borderFocused = Color(0x66FF7A1A);

  // ═══════════════════════════════════════════════════════════
  // CHAT BUBBLES
  // ═══════════════════════════════════════════════════════════
  
  /// Sent message bubble start
  static const Color bubbleSentStart = Color(0xFFFF8C3A);
  
  /// Sent message bubble end
  static const Color bubbleSentEnd = Color(0xFFFF6B1A);
  
  /// Received message bubble
  static const Color bubbleReceived = Color(0xFF1A1215);

  // ═══════════════════════════════════════════════════════════
  // SHADOWS & GLOWS
  // ═══════════════════════════════════════════════════════════
  
  /// Primary glow color
  static const Color glowPrimary = Color(0x66FF7A1A);
  
  /// Strong glow
  static const Color glowStrong = Color(0x99FF7A1A);
  
  /// Soft glow
  static const Color glowSoft = Color(0x33FF7A1A);

  // ═══════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════
  
  /// Get primary with opacity
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  
  /// Get background with opacity
  static Color backgroundWithOpacity(double opacity) => background.withOpacity(opacity);

  // ═══════════════════════════════════════════════════════════
  // BACKWARD COMPATIBLE ALIASES (Legacy support)
  // ═══════════════════════════════════════════════════════════
  
  // Color aliases for old code
  static const Color accent = primarySoft;
  static const Color secondary = primaryDark;
  static const Color accentWarm = primaryLight;
  static const Color info = primarySoft;
  
  // Dark theme text aliases
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color textTertiaryDark = textMuted;
  
  // Background aliases
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
  static const Color cardDark = card;
  
  // Glass aliases
  static const Color glassMedium = Color(0x26FFFFFF);

  // ═══════════════════════════════════════════════════════════
  // GRADIENTS (Static - for backward compatibility)
  // ═══════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFA94A), // Light Orange
      Color(0xFFFF7A1A), // Main Orange
      Color(0xFFCC5C10), // Dark Orange
    ],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA94A), Color(0xFFFF7A1A), Color(0xFFCC5C10)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primarySoft],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0506), Color(0xFF050304)],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A0A04), Color(0xFF050304)],
  );
  
  static const List<Color> meshGradientColors = [
    Color(0xFFFF7A1A),
    Color(0xFFCC5C10),
    Color(0xFFFFA94A),
    Color(0xFFE55A00),
  ];
  
  /// Radial glow gradient
  static RadialGradient radialGlow({double opacity = 0.3}) => RadialGradient(
    colors: [
      primary.withOpacity(opacity),
      Colors.transparent,
    ],
  );
}

/// Helper class for theme-aware colors
class AppThemeColors {
  final bool isDarkMode;
  const AppThemeColors({required this.isDarkMode});
  
  Color get backgroundColor => isDarkMode ? AppColors.background : AppColors.backgroundLight;
  Color get surfaceColor => isDarkMode ? AppColors.surface : AppColors.surfaceLight;
  Color get cardColor => isDarkMode ? AppColors.card : AppColors.cardLight;
  Color get textColor => isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMutedColor => isDarkMode ? AppColors.textMuted : AppColors.textMutedLight;
  
  // Helper for primary which doesn't change but good to have
  Color get primary => AppColors.primary;
}

/// Theme-aware color extension for BuildContext
/// Use context.colors.xxx to get the correct color for current theme
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // Accessor for grouped colors
  AppThemeColors get colors => AppThemeColors(isDarkMode: isDarkMode);
  
  // Direct accessors (Backward compatibility)
  Color get backgroundColor => isDarkMode ? AppColors.background : AppColors.backgroundLight;
  Color get surfaceColor => isDarkMode ? AppColors.surface : AppColors.surfaceLight;
  Color get cardColor => isDarkMode ? AppColors.card : AppColors.cardLight;
  Color get textColor => isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMutedColor => isDarkMode ? AppColors.textMuted : AppColors.textMutedLight;
}
