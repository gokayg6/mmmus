import 'package:flutter/material.dart';

/// OmeChat Color Palette
/// iOS-inspired with premium feel
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF007AFF);       // iOS Blue
  static const Color primaryDark = Color(0xFF0A84FF);   // iOS Blue (Dark mode)
  static const Color secondary = Color(0xFF5856D6);     // iOS Purple
  static const Color secondaryDark = Color(0xFF5E5CE6);
  
  // Accent/Brand colors
  static const Color accent = Color(0xFFFF6B35);        // OmeChat Orange
  static const Color accentGradientStart = Color(0xFFFF6B35);
  static const Color accentGradientEnd = Color(0xFFFF8F5C);
  
  // Background colors - Light mode
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Background colors - Dark mode
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color cardDark = Color(0xFF2C2C2E);
  
  // Glass/Blur colors
  static const Color glassLight = Color(0x14FFFFFF);    // 8% white
  static const Color glassDark = Color(0x40000000);     // 25% black
  static const Color glassBorderLight = Color(0x26FFFFFF); // 15% white
  static const Color glassBorderDark = Color(0x26FFFFFF);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textTertiaryLight = Color(0xFFC7C7CC);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textTertiaryDark = Color(0xFF48484A);
  
  // Status colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF5AC8FA);
  
  // Chat bubble colors
  static const Color chatBubbleOwn = Color(0xFF007AFF);
  static const Color chatBubblePartner = Color(0xFF3A3A3C);
  static const Color chatBubblePartnerLight = Color(0xFFE9E9EB);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGradientStart, accentGradientEnd],
  );
}
