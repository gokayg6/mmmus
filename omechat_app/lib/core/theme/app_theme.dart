import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// OmeChat Theme System
/// Complete dark orange theme with NO blue colors anywhere
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════
  // DESIGN CONSTANTS
  // ═══════════════════════════════════════════════════════════
  
  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusPill = 100.0;
  
  // Blur Radius
  static const double blurLight = 8.0;
  static const double blurMedium = 15.0;
  static const double blurHeavy = 25.0;
  static const double blurGlass = 20.0;
  static const double blurControlPanel = 20.0;  // Alias
  static const double blurBottomSheet = 25.0;   // Alias
  
  // Animation Durations - Optimized for 240Hz (no frame rate limit)
  static const Duration durationFast = Duration(milliseconds: 50);       // 240Hz: ~12 frames
  static const Duration durationNormal = Duration(milliseconds: 100);   // 240Hz: ~24 frames
  static const Duration durationSlow = Duration(milliseconds: 150);     // 240Hz: ~36 frames
  static const Duration durationVerySlow = Duration(milliseconds: 200); // 240Hz: ~48 frames
  static const Duration durationMedium = Duration(milliseconds: 125);    // 240Hz: ~30 frames
  
  // Animation Curves
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveSharp = Curves.easeOutQuart;
  static const Curve curveBounce = Curves.elasticOut;
  
  // Font Family
  static const String fontFamily = 'SF Pro Display';

  // ═══════════════════════════════════════════════════════════
  // COLOR SCHEME (NO BLUE - DARK ORANGE ONLY)
  // ═══════════════════════════════════════════════════════════
  
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary - ORANGE (not blue!)
    primary: AppColors.primary,
    onPrimary: Colors.black,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.textPrimary,
    // Secondary - ORANGE SOFT (not blue!)
    secondary: AppColors.primarySoft,
    onSecondary: Colors.black,
    secondaryContainer: AppColors.surfaceAlt,
    onSecondaryContainer: AppColors.textPrimary,
    // Tertiary - ORANGE VARIANTS (not blue!)
    tertiary: AppColors.primaryLight,
    onTertiary: Colors.black,
    // Error
    error: AppColors.error,
    onError: Colors.white,
    // Background & Surface
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceAlt,
    onSurfaceVariant: AppColors.textSecondary,
    // Outline
    outline: AppColors.borderSoft,
    outlineVariant: AppColors.borderOrange,
    // Shadow
    shadow: Colors.black,
    // Inverse
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primaryDark,
    // Scrim
    scrim: Colors.black,
  );

  // ═══════════════════════════════════════════════════════════
  // DARK THEME (MAIN THEME)
  // ═══════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.borderSoft,
      
      // AppBar Theme - Transparent with orange accents
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.headline(),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      
      // Icon Theme - Orange
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      
      // Elevated Button - Orange gradient look
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primaryDark.withOpacity(0.4);
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.black),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusPill),
            ),
          ),
          overlayColor: WidgetStateProperty.all(
            AppColors.primaryDark.withOpacity(0.2),
          ),
        ),
      ),
      
      // Text Button - Orange
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withOpacity(0.1),
          ),
          textStyle: WidgetStateProperty.all(
            AppTypography.buttonMedium(),
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusPill),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      
      // Input Decoration - Orange focus (no borders)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintStyle: AppTypography.body(color: AppColors.textHint),
        labelStyle: AppTypography.body(color: AppColors.textSecondary),
        errorStyle: AppTypography.caption1(color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      
      // Bottom Navigation - Orange selected
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Navigation Bar (M3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.caption1(),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      
      // FAB - Orange
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),
      
      // Chip - Orange
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surface.withOpacity(0.5),
        labelStyle: AppTypography.caption1(),
        secondaryLabelStyle: AppTypography.caption1(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXXLarge),
        ),
        titleTextStyle: AppTypography.title2(),
        contentTextStyle: AppTypography.body(),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        modalBackgroundColor: AppColors.surfaceElevated,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXXLarge),
          ),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTypography.body(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Progress Indicator - Orange
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
        circularTrackColor: AppColors.surface,
      ),
      
      // Slider - Orange
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surface,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
      ),
      
      // Switch - Orange
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.4);
          }
          return AppColors.surface;
        }),
      ),
      
      // Checkbox - Orange
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: AppColors.textMuted, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio - Orange
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
      ),
      
      // Tab Bar - Orange
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.buttonMedium(),
        unselectedLabelStyle: AppTypography.buttonMedium(),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 0.5,
        space: 1,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primary.withOpacity(0.1),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(radiusSmall),
          border: Border.all(color: AppColors.borderSoft),
        ),
        textStyle: AppTypography.caption1(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT THEME BUILDER
  // ═══════════════════════════════════════════════════════════
  
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: AppTypography.extraLargeTitle(),
      displayMedium: AppTypography.largeTitle(),
      displaySmall: AppTypography.title1(),
      headlineLarge: AppTypography.title1(),
      headlineMedium: AppTypography.title2(),
      headlineSmall: AppTypography.title3(),
      titleLarge: AppTypography.headline(),
      titleMedium: AppTypography.bodyMedium(),
      titleSmall: AppTypography.subheadlineMedium(),
      bodyLarge: AppTypography.body(),
      bodyMedium: AppTypography.callout(),
      bodySmall: AppTypography.footnote(),
      labelLarge: AppTypography.buttonLarge(),
      labelMedium: AppTypography.buttonMedium(),
      labelSmall: AppTypography.caption1(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LIGHT COLOR SCHEME
  // ═══════════════════════════════════════════════════════════
  
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primarySoft,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surfaceLight,
    onSecondaryContainer: AppColors.textPrimaryLight,
    tertiary: AppColors.primaryDeep,
    onTertiary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.cardLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: Color(0xFFD0C5B8),
    outlineVariant: Color(0xFFE8DDD0),
    shadow: Colors.black26,
    inverseSurface: AppColors.background,
    onInverseSurface: AppColors.textPrimary,
    inversePrimary: AppColors.primaryLight,
    scrim: Colors.black38,
  );

  // ═══════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════
  
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    
    return base.copyWith(
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      canvasColor: AppColors.backgroundLight,
      cardColor: AppColors.cardLight,
      dividerColor: const Color(0xFFE0D5C8),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.headline(color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 24,
        ),
      ),
      
      textTheme: _buildLightTextTheme(base.textTheme),
      primaryTextTheme: _buildLightTextTheme(base.primaryTextTheme),
      
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primaryDark.withOpacity(0.4);
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusPill),
            ),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withOpacity(0.1),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: AppTypography.body(color: AppColors.textMutedLight),
        labelStyle: AppTypography.body(color: AppColors.textSecondaryLight),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.caption1(color: AppColors.textPrimaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXXLarge),
        ),
        titleTextStyle: AppTypography.title2(color: AppColors.textPrimaryLight),
        contentTextStyle: AppTypography.body(color: AppColors.textSecondaryLight),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXXLarge)),
        ),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.4);
          }
          return Colors.grey.shade300;
        }),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE0D5C8),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    );
  }

  static TextTheme _buildLightTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: AppTypography.extraLargeTitle(color: AppColors.textPrimaryLight),
      displayMedium: AppTypography.largeTitle(color: AppColors.textPrimaryLight),
      displaySmall: AppTypography.title1(color: AppColors.textPrimaryLight),
      headlineLarge: AppTypography.title1(color: AppColors.textPrimaryLight),
      headlineMedium: AppTypography.title2(color: AppColors.textPrimaryLight),
      headlineSmall: AppTypography.title3(color: AppColors.textPrimaryLight),
      titleLarge: AppTypography.headline(color: AppColors.textPrimaryLight),
      titleMedium: AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
      titleSmall: AppTypography.subheadlineMedium(color: AppColors.textSecondaryLight),
      bodyLarge: AppTypography.body(color: AppColors.textPrimaryLight),
      bodyMedium: AppTypography.callout(color: AppColors.textSecondaryLight),
      bodySmall: AppTypography.footnote(color: AppColors.textMutedLight),
      labelLarge: AppTypography.buttonLarge(color: AppColors.textPrimaryLight),
      labelMedium: AppTypography.buttonMedium(color: AppColors.textPrimaryLight),
      labelSmall: AppTypography.caption1(color: AppColors.textMutedLight),
    );
  }
}
