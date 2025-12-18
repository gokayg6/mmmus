import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// APP TRANSITIONS - Global Animation Constants & Helpers
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// This file contains the core animation physics for the entire OmeChat app.
/// All transitions should use these constants for consistency.

class AppTransitions {
  AppTransitions._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE CURVES - iOS 18 Liquid Physics
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary fluid curve for most transitions
  static const Curve fluidCurve = Curves.fastLinearToSlowEaseIn;
  
  /// Elastic curve for "jelly" effects
  static const Curve elasticCurve = Curves.elasticOut;
  
  /// Exponential ease for iOS-style momentum
  static const Curve iosEase = Curves.easeOutExpo;
  
  /// Tight spring for quick rebounds
  static const Curve springTight = Curves.easeOutBack;
  
  /// Slow dramatic reveal
  static const Curve dramaticReveal = Curves.easeOutCirc;

  // ═══════════════════════════════════════════════════════════════════════════
  // DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Genie portal transition (full sequence)
  static const Duration genieDuration = Duration(milliseconds: 800);
  
  /// Phase 1: X-axis squeeze
  static const Duration squeezeDuration = Duration(milliseconds: 240);
  
  /// Phase 2: Blur ramp
  static const Duration blurDuration = Duration(milliseconds: 320);
  
  /// Phase 3: Liquid expansion
  static const Duration expansionDuration = Duration(milliseconds: 560);
  
  /// Quick micro-interactions
  static const Duration microDuration = Duration(milliseconds: 150);
  
  /// Standard UI transitions
  static const Duration normalDuration = Duration(milliseconds: 300);
  
  /// Slow dramatic reveals
  static const Duration slowDuration = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════════════════
  // GENIE TRANSFORM MATRIX
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Calculates the 3D perspective transform for the Genie squeeze effect
  /// [progress] 0.0 = normal, 1.0 = fully squeezed
  static Matrix4 genieSqueezeTransform(double progress) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective depth
      ..scale(
        1.0 - (progress * 0.8),  // X shrinks to 20%
        1.0 + (progress * 0.3),  // Y stretches 30%
        1.0,
      )
      ..translate(0.0, -progress * 20); // Slight upward drift
  }
  
  /// Calculates the liquid blob expansion transform
  /// [progress] 0.0 = point, 1.0 = full screen
  static Matrix4 liquidExpandTransform(double progress, Size screenSize) {
    final maxScale = screenSize.longestSide * 2;
    return Matrix4.identity()
      ..scale(progress * maxScale);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HAPTIC FEEDBACK HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Trigger haptic for transition start
  static void hapticTransitionStart() {
    HapticFeedback.mediumImpact();
  }
  
  /// Trigger haptic for transition complete
  static void hapticTransitionComplete() {
    HapticFeedback.lightImpact();
  }
  
  /// Trigger haptic for squeeze phase
  static void hapticSqueeze() {
    HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR INTERPOLATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Interpolate between two colors with custom curve
  static Color lerpColor(Color a, Color b, double t, {Curve curve = Curves.linear}) {
    return Color.lerp(a, b, curve.transform(t)) ?? a;
  }
  
  /// Get blur sigma from progress (0-25 range)
  static double getBlurSigma(double progress) {
    // Peak at 40% progress, then fade
    if (progress < 0.4) {
      return 25.0 * (progress / 0.4);
    } else {
      return 25.0 * (1.0 - ((progress - 0.4) / 0.6));
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// INTERVAL CURVES - For multi-phase animations
/// ═══════════════════════════════════════════════════════════════════════════

class GenieIntervals {
  GenieIntervals._();
  
  /// Phase 1: Button squeeze (0.0 - 0.3)
  static const Interval squeeze = Interval(0.0, 0.3, curve: Curves.easeInOut);
  
  /// Phase 2: Blur ramp up (0.0 - 0.4)
  static const Interval blurUp = Interval(0.0, 0.4, curve: Curves.easeIn);
  
  /// Phase 3: Liquid expansion (0.3 - 1.0)
  static const Interval expansion = Interval(0.3, 1.0, curve: Curves.fastOutSlowIn);
  
  /// Phase 4: Content reveal stagger (0.7 - 1.0)
  static const Interval contentReveal = Interval(0.7, 1.0, curve: Curves.easeOut);
}
