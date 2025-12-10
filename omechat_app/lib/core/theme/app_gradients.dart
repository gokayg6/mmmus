import 'package:flutter/material.dart';
import 'app_colors.dart';

/// OmeChat Gradient System
/// All gradients use warm orange tones - NO blue
class AppGradients {
  AppGradients._();

  // ═══════════════════════════════════════════════════════════
  // BACKGROUND GRADIENTS
  // ═══════════════════════════════════════════════════════════
  
  /// Main background gradient - dark with subtle warmth
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050304),
      Color(0xFF120806),
    ],
  );
  
  /// Background with orange glow from top-right
  static const LinearGradient backgroundGlow = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1A0A04),
      Color(0xFF050304),
      Color(0xFF050304),
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // ═══════════════════════════════════════════════════════════
  // RADIAL GLOWS
  // ═══════════════════════════════════════════════════════════
  
  /// Orange glow from top-right (like the logo)
  static const RadialGradient orangeGlow = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [
      Color(0x66FF7A1A),
      Colors.transparent,
    ],
  );
  
  /// Center glow for connect button area
  static const RadialGradient centerGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      Color(0x40FF7A1A),
      Color(0x10FF7A1A),
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Pulsing glow (use with animation)
  static RadialGradient pulseGlow(double intensity) => RadialGradient(
    center: Alignment.center,
    radius: 0.6 + (intensity * 0.4),
    colors: [
      Color.lerp(const Color(0x33FF7A1A), const Color(0x66FF7A1A), intensity)!,
      Colors.transparent,
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // BUTTON GRADIENTS
  // ═══════════════════════════════════════════════════════════
  
  /// Primary button gradient
  static const LinearGradient button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFA94A),
      Color(0xFFFF7A1A),
      Color(0xFFCC5C10),
    ],
  );
  
  /// Button pressed state
  static const LinearGradient buttonPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF8C3A),
      Color(0xFFE86A10),
      Color(0xFFB85010),
    ],
  );
  
  /// Disabled button
  static const LinearGradient buttonDisabled = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A3A2A),
      Color(0xFF3A2A1A),
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // CHAT BUBBLE GRADIENTS
  // ═══════════════════════════════════════════════════════════
  
  /// Sent message bubble gradient
  static const LinearGradient bubbleSent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF8C3A),
      Color(0xFFFF6B1A),
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // SHIMMER / LOADING
  // ═══════════════════════════════════════════════════════════
  
  /// Shimmer gradient for loading states
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1215),
      Color(0xFF251A18),
      Color(0xFF1A1215),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════
  // GLASS EFFECT
  // ═══════════════════════════════════════════════════════════
  
  /// Glass overlay gradient
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // AVATAR RING
  // ═══════════════════════════════════════════════════════════
  
  /// Avatar glow ring gradient
  static const SweepGradient avatarRing = SweepGradient(
    colors: [
      Color(0xFFFF7A1A),
      Color(0xFFFFA94A),
      Color(0xFFFF7A1A),
      Color(0xFFCC5C10),
      Color(0xFFFF7A1A),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );
}
