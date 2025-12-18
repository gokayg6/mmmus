import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_transitions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GENIE ROUTE TRANSITION
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// A portal-like page transition that:
/// 1. Squeezes the origin widget on X-axis (needle-thin)
/// 2. Applies directional blur
/// 3. Expands like liquid to fill the screen
/// 4. Reveals the destination with staggered content

class GenieRouteTransition extends PageRouteBuilder {
  final Widget page;
  final Offset origin;
  final Color expansionColor;

  GenieRouteTransition({
    required this.page,
    required this.origin,
    this.expansionColor = const Color(0xFFFF7A1A),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppTransitions.genieDuration,
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _GenieTransitionWidget(
              animation: animation,
              origin: origin,
              expansionColor: expansionColor,
              child: child,
            );
          },
        );
}

class _GenieTransitionWidget extends StatelessWidget {
  final Animation<double> animation;
  final Offset origin;
  final Color expansionColor;
  final Widget child;

  const _GenieTransitionWidget({
    required this.animation,
    required this.origin,
    required this.expansionColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        
        // Trigger haptics at key moments
        if (progress > 0.01 && progress < 0.05) {
          AppTransitions.hapticTransitionStart();
        }
        if (progress > 0.95 && progress < 0.99) {
          AppTransitions.hapticTransitionComplete();
        }
        
        return Stack(
          children: [
            // Layer 1: Liquid expansion painter (behind everything)
            Positioned.fill(
              child: CustomPaint(
                painter: LiquidExpansionPainter(
                  progress: progress,
                  origin: origin,
                  color: expansionColor,
                  screenSize: size,
                ),
              ),
            ),
            
            // Layer 2: Blur overlay (peaks mid-transition)
            if (progress > 0.0 && progress < 0.8)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppTransitions.getBlurSigma(progress),
                    sigmaY: AppTransitions.getBlurSigma(progress),
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            
            // Layer 3: Destination page with fade-in
            if (progress > 0.6)
              Opacity(
                opacity: ((progress - 0.6) / 0.4).clamp(0.0, 1.0),
                child: child,
              ),
          ],
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// LIQUID EXPANSION PAINTER
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// CustomPainter that handles:
/// - Phase 1 (0.0-0.3): X-axis squeeze with Y stretch
/// - Phase 2 (0.3-1.0): Liquid blob expansion with bezier smoothing

class LiquidExpansionPainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color color;
  final Size screenSize;

  LiquidExpansionPainter({
    required this.progress,
    required this.origin,
    required this.color,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (progress < 0.3) {
      // ═══════════════════════════════════════════════════════════════════════
      // PHASE 1: X-Axis Squeeze (Stretch & Squeeze)
      // ═══════════════════════════════════════════════════════════════════════
      final squeezeProgress = progress / 0.3;
      final squeezeCurve = Curves.easeInOut.transform(squeezeProgress);
      
      // Width shrinks from 150 to 30 (80% reduction)
      final width = 150.0 * (1.0 - squeezeCurve * 0.8);
      // Height grows from 50 to 70 (40% increase)
      final height = 50.0 * (1.0 + squeezeCurve * 0.4);
      
      final rect = Rect.fromCenter(
        center: origin,
        width: width,
        height: height,
      );
      
      // Rounded rectangle with dynamic radius
      final radius = Radius.circular(height / 2); // Pill shape
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      
    } else {
      // ═══════════════════════════════════════════════════════════════════════
      // PHASE 2: Liquid Expansion (Genie Effect)
      // ═══════════════════════════════════════════════════════════════════════
      final expandProgress = (progress - 0.3) / 0.7;
      final expandCurve = Curves.fastOutSlowIn.transform(expandProgress);
      
      // Maximum radius to cover entire screen + buffer
      final maxRadius = screenSize.longestSide * 1.5;
      final radius = maxRadius * expandCurve;
      
      // Create liquid blob path with bezier curves for organic feel
      final path = _createLiquidPath(origin, radius, expandProgress);
      canvas.drawPath(path, paint);
      
      // Add subtle glow at expanding edge
      if (expandProgress > 0.1 && expandProgress < 0.8) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3 * (1.0 - expandProgress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20.0 * (1.0 - expandProgress)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  /// Creates an organic liquid blob path using bezier curves
  Path _createLiquidPath(Offset center, double radius, double progress) {
    final path = Path();
    
    // For early expansion, use wobbly edges
    if (progress < 0.5) {
      // 8-point bezier blob
      const numPoints = 8;
      final wobbleAmount = 0.1 * (1.0 - progress * 2); // Wobble decreases over time
      
      for (int i = 0; i < numPoints; i++) {
        final angle = (i / numPoints) * 2 * math.pi;
        final nextAngle = ((i + 1) / numPoints) * 2 * math.pi;
        
        // Random-ish wobble based on position
        final wobble = math.sin(angle * 3 + progress * 10) * wobbleAmount;
        final wobbledRadius = radius * (1.0 + wobble);
        
        final x = center.dx + math.cos(angle) * wobbledRadius;
        final y = center.dy + math.sin(angle) * wobbledRadius;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Bezier control points for smooth curves
          final prevAngle = ((i - 0.5) / numPoints) * 2 * math.pi;
          final controlX = center.dx + math.cos(prevAngle) * wobbledRadius * 1.1;
          final controlY = center.dy + math.sin(prevAngle) * wobbledRadius * 1.1;
          path.quadraticBezierTo(controlX, controlY, x, y);
        }
      }
      path.close();
    } else {
      // Later expansion: simple circle for performance
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    }
    
    return path;
  }

  @override
  bool shouldRepaint(covariant LiquidExpansionPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           origin != oldDelegate.origin ||
           color != oldDelegate.color;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GENIE CONTROLLER
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Multi-phase animation controller for manual Genie animations
/// (when not using the route transition)

class GenieController {
  late AnimationController _controller;
  late Animation<double> squeezeAnimation;
  late Animation<double> blurAnimation;
  late Animation<double> expansionAnimation;
  late Animation<double> contentRevealAnimation;
  
  bool get isAnimating => _controller.isAnimating;
  double get value => _controller.value;
  
  void setup(TickerProvider vsync, {Duration? duration}) {
    _controller = AnimationController(
      duration: duration ?? AppTransitions.genieDuration,
      vsync: vsync,
    );
    
    // Phase 1: X-Axis Squeeze (0.0 - 0.3)
    squeezeAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: GenieIntervals.squeeze,
      ),
    );
    
    // Phase 2: Blur Increase (0.0 - 0.4)
    blurAnimation = Tween<double>(begin: 0.0, end: 25.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: GenieIntervals.blurUp,
      ),
    );
    
    // Phase 3: Liquid Expansion (0.3 - 1.0)
    expansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: GenieIntervals.expansion,
      ),
    );
    
    // Phase 4: Content Reveal (0.7 - 1.0)
    contentRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: GenieIntervals.contentReveal,
      ),
    );
  }
  
  Future<void> forward() async {
    AppTransitions.hapticTransitionStart();
    await _controller.forward();
    AppTransitions.hapticTransitionComplete();
  }
  
  Future<void> reverse() async {
    await _controller.reverse();
  }
  
  void reset() {
    _controller.reset();
  }
  
  void dispose() {
    _controller.dispose();
  }
  
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GENIE BUTTON WRAPPER
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Wraps any widget to add the Genie squeeze animation on tap

class GenieButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, Offset globalPosition)? onGenieComplete;
  
  const GenieButton({
    super.key,
    required this.child,
    this.onTap,
    this.onGenieComplete,
  });

  @override
  State<GenieButton> createState() => _GenieButtonState();
}

class _GenieButtonState extends State<GenieButton> with SingleTickerProviderStateMixin {
  late final GenieController _genieController;
  final GlobalKey _buttonKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _genieController = GenieController();
    _genieController.setup(this);
    _genieController.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    _genieController.dispose();
    super.dispose();
  }
  
  Offset _getGlobalPosition() {
    final RenderBox? box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  
  Future<void> _handleTap() async {
    HapticFeedback.selectionClick();
    
    if (widget.onGenieComplete != null) {
      await _genieController.forward();
      final pos = _getGlobalPosition();
      
      if (mounted) {
        Navigator.of(context).push(
          GenieRouteTransition(
            page: widget.onGenieComplete!(context, pos),
            origin: pos,
          ),
        );
      }
      _genieController.reset();
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _genieController.isAnimating 
        ? _genieController.squeezeAnimation.value 
        : 1.0;
    
    return GestureDetector(
      key: _buttonKey,
      onTap: _handleTap,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(scale, 1.0 + (1.0 - scale) * 0.5), // X squeeze, Y stretch
        child: widget.child,
      ),
    );
  }
}
