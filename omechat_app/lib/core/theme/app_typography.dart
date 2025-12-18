import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OmeChat Typography System
/// SF Pro-inspired using Inter from Google Fonts
class AppTypography {
  /// Primary font family - Inter (closest to SF Pro)
  static String get fontFamily => GoogleFonts.inter().fontFamily!;
  static const String serifFont = 'WacianSerif';

  // === SERIF TITLES ===
  
  /// Serif Title - Wacian Serif (Custom)
  static TextStyle serifTitle({double fontSize = 34, Color? color, FontWeight fontWeight = FontWeight.w700}) => TextStyle(
    fontFamily: serifFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0.37,
    height: 1.2,
    color: color ?? Colors.white,
  );
  
  // === LARGE TITLES ===
  
  /// Large Title - Hero text (34-40pt)
  static TextStyle largeTitle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 1.2,
    color: color ?? Colors.white,
  );
  
  /// Extra Large Title - Splash screens (40pt)
  static TextStyle extraLargeTitle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    height: 1.1,
    color: color ?? Colors.white,
  );
  
  // === TITLES ===
  
  /// Title 1 (28pt)
  static TextStyle title1({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    height: 1.21,
    color: color ?? Colors.white,
  );
  
  /// Title 2 (22pt)
  static TextStyle title2({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    height: 1.27,
    color: color ?? Colors.white,
  );
  
  /// Title 3 (20pt)
  static TextStyle title3({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    height: 1.25,
    color: color ?? Colors.white,
  );
  
  // === HEADLINES ===
  
  /// Headline (17pt semibold)
  static TextStyle headline({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.29,
    color: color ?? Colors.white,
  );
  
  // === BODY TEXT ===
  
  /// Body (17pt regular)
  static TextStyle body({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 1.29,
    color: color ?? Colors.white,
  );
  
  /// Body Medium (17pt medium)
  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.41,
    height: 1.29,
    color: color ?? Colors.white,
  );
  
  /// Callout (16pt)
  static TextStyle callout({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.31,
    color: color ?? Colors.white,
  );
  
  /// Subheadline (15pt)
  static TextStyle subheadline({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.33,
    color: color ?? Colors.white,
  );
  
  /// Subheadline Medium (15pt medium)
  static TextStyle subheadlineMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
    height: 1.33,
    color: color ?? Colors.white,
  );
  
  /// Footnote (13pt)
  static TextStyle footnote({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.38,
    color: color ?? Colors.white.withOpacity(0.7),
  );
  
  // === CAPTIONS ===
  
  /// Caption 1 (12pt)
  static TextStyle caption1({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
    color: color ?? Colors.white.withOpacity(0.6),
  );
  
  /// Caption 2 (11pt)
  static TextStyle caption2({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    height: 1.27,
    color: color ?? Colors.white.withOpacity(0.5),
  );
  
  // === BUTTON TEXT ===
  
  /// Button Large (17pt semibold)
  static TextStyle buttonLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.29,
    color: color ?? Colors.white,
  );
  
  /// Button Medium (15pt semibold)
  static TextStyle buttonMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    height: 1.33,
    color: color ?? Colors.white,
  );
  
  /// Button Small (13pt medium)
  static TextStyle buttonSmall({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.08,
    height: 1.38,
    color: color ?? Colors.white,
  );
  
  // === SPECIAL ===
  
  /// Tab bar label (10pt medium)
  static TextStyle tabLabel({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
    color: color ?? Colors.white,
  );
  
  /// Badge text (11pt bold)
  static TextStyle badge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.18,
    color: color ?? Colors.white,
  );
  
  /// Online count (14pt semibold)
  static TextStyle onlineCount({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.21,
    color: color ?? Colors.white,
  );
}
