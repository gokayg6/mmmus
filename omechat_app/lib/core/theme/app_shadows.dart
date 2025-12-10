import 'package:flutter/material.dart';
import 'app_colors.dart';

/// OmeChat Shadow Definitions
/// Premium floating glass effects
class AppShadows {
  // === CARD SHADOWS ===
  
  /// Subtle card shadow
  static List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Standard card shadow
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Elevated card shadow (floating)
  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 30,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
  
  // === BUTTON SHADOWS ===
  
  /// Primary button shadow with glow
  static List<BoxShadow> buttonPrimary = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Accent button shadow with glow
  static List<BoxShadow> buttonAccent = [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
  
  // === GLOW SHADOWS ===
  
  /// Primary glow effect
  static List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.4),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
  
  /// Accent glow effect
  static List<BoxShadow> glowAccent = [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.4),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
  
  /// Subtle icon glow
  static List<BoxShadow> glowIcon = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.5),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
  
  /// Success glow
  static List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: AppColors.success.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
  
  // === GLASS SHADOWS ===
  
  /// Bottom dock shadow
  static List<BoxShadow> glassDock = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 30,
      spreadRadius: 0,
      offset: const Offset(0, -5),
    ),
  ];
  
  /// Glass container shadow
  static List<BoxShadow> glassContainer = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Top bar shadow
  static List<BoxShadow> glassTopBar = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
  
  // === VIDEO SHADOWS ===
  
  /// PIP (Picture-in-Picture) video shadow
  static List<BoxShadow> pip = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 5),
    ),
  ];
  
  // === ORB/ANIMATION SHADOWS ===
  
  /// Matchmaking orb glow
  static List<BoxShadow> orbGlow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.5),
      blurRadius: 60,
      spreadRadius: 10,
    ),
    BoxShadow(
      color: AppColors.accent.withOpacity(0.3),
      blurRadius: 80,
      spreadRadius: 20,
    ),
  ];
}
