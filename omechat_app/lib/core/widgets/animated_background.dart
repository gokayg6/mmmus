import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated gradient background for premium screens
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool animate;
  final List<Color>? colors;
  
  const AnimatedBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.colors,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 6000),  // 120Hz: ~720 frames
      vsync: this,
    );
    
    if (widget.animate) {
      _controller.repeat();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Light mode uses warm white gradient
    final lightGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.backgroundLight,
        const Color(0xFFFFF5EB),
      ],
    );
    
    return Stack(
      children: [
        // Base gradient - theme-aware
        Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.backgroundGradient : lightGradient,
          ),
        ),
        
        // Animated mesh gradient orbs (only in dark mode for better visibility)
        if (widget.animate && isDark)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _MeshGradientPainter(
                  animation: _controller.value,
                  colors: widget.colors ?? AppColors.meshGradientColors,
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // Subtle overlay - light mode gets warm tint instead of dark vignette
        if (isDark)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  
  _MeshGradientPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    
    // Create floating gradient orbs
    for (int i = 0; i < colors.length; i++) {
      final phase = animation * 2 * math.pi + (i * math.pi / 2);
      
      final x = size.width * (0.3 + 0.4 * math.sin(phase + i));
      final y = size.height * (0.3 + 0.4 * math.cos(phase * 0.7 + i));
      
      paint.shader = RadialGradient(
        colors: [
          colors[i].withOpacity(0.15),
          colors[i].withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(x, y),
        radius: size.width * 0.4,
      ));
      
      canvas.drawCircle(Offset(x, y), size.width * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Static gradient background (no animation)
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.splashGradient,
      ),
      child: child,
    );
  }
}

/// Vignette overlay widget
class VignetteOverlay extends StatelessWidget {
  final Widget child;
  final double intensity;
  
  const VignetteOverlay({
    super.key,
    required this.child,
    this.intensity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(intensity),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
