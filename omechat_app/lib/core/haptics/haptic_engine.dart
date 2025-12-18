import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HAPTIC ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Centralized haptic feedback system for consistent tactile responses
/// across the entire OmeChat application.

class HapticEngine {
  HapticEngine._();

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE HAPTICS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Message sent - Medium "fırlatma" feeling
  static void messageSent() {
    HapticFeedback.mediumImpact();
  }
  
  /// Message received - Light "tık" notification
  static void messageReceived() {
    HapticFeedback.lightImpact();
  }
  
  /// Message liked/reacted
  static void messageReaction() {
    HapticFeedback.selectionClick();
  }
  
  /// Message deleted
  static void messageDeleted() {
    HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION HAPTICS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Tab changed in navbar
  static void tabChanged() {
    HapticFeedback.selectionClick();
  }
  
  /// Page transition started
  static void transitionStart() {
    HapticFeedback.mediumImpact();
  }
  
  /// Page transition completed
  static void transitionComplete() {
    HapticFeedback.lightImpact();
  }
  
  /// Button pressed
  static void buttonPress() {
    HapticFeedback.selectionClick();
  }
  
  /// Long press recognized
  static void longPress() {
    HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEEDBACK HAPTICS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Success action
  static void success() {
    HapticFeedback.lightImpact();
  }
  
  /// Error/warning
  static void error() {
    HapticFeedback.vibrate();
  }
  
  /// Selection click (light)
  static void selection() {
    HapticFeedback.selectionClick();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENIE TRANSITION HAPTICS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Genie squeeze started
  static void genieSqueeze() {
    HapticFeedback.selectionClick();
  }
  
  /// Genie expansion peak
  static void genieExpand() {
    HapticFeedback.mediumImpact();
  }
  
  /// Genie reveal complete
  static void genieComplete() {
    HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALL HAPTICS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Incoming call vibration pattern
  static void incomingCall() {
    HapticFeedback.vibrate();
  }
  
  /// Call connected
  static void callConnected() {
    HapticFeedback.mediumImpact();
  }
  
  /// Call ended
  static void callEnded() {
    HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULL-TO-REFRESH & SCROLL
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Pull threshold reached (ready to refresh)
  static void pullThreshold() {
    HapticFeedback.selectionClick();
  }
  
  /// Refresh triggered
  static void refreshTriggered() {
    HapticFeedback.mediumImpact();
  }
  
  /// Scroll edge reached (overscroll)
  static void scrollEdge() {
    HapticFeedback.selectionClick();
  }
}
