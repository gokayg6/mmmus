import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Animated orb for matchmaking screen
/// Features rotating gradient ring with particle effects
class OrbAnimation extends StatefulWidget {
  final double size;
  final bool isSearching;
  
  const OrbAnimation({
    super.key,
    this.size = 200,
    this.isSearching = true,
  });

  @override
  State<OrbAnimation> createState() => _OrbAnimationState();
}

class _OrbAnimationState extends State<OrbAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = 0.8 + (_pulseController.value * 0.2);
              return Container(
                width: widget.size * pulse,
                height: widget.size * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Particles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                final angle = (index / 8) * 2 * math.pi + 
                    (_particleController.value * 2 * math.pi);
                final radius = widget.size * 0.35;
                final particleSize = 4.0 + (index % 3) * 2;
                
                return Transform.translate(
                  offset: Offset(
                    math.cos(angle) * radius,
                    math.sin(angle) * radius,
                  ),
                  child: Container(
                    width: particleSize,
                    height: particleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index.isEven 
                          ? AppColors.primary.withOpacity(0.8)
                          : AppColors.accent.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: (index.isEven ? AppColors.primary : AppColors.accent)
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
          
          // Rotating gradient ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.8, widget.size * 0.8),
                  painter: _GradientRingPainter(),
                ),
              );
            },
          ),
          
          // Inner orb
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 0.95 + (_pulseController.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.45,
                  height: widget.size * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Center icon
          Icon(
            Icons.person_search_rounded,
            size: widget.size * 0.15,
            color: Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          AppColors.primary,
          AppColors.secondary,
          AppColors.accent,
          AppColors.accentWarm,
          AppColors.primary,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius - 2, paint);
    
    // Second ring with offset
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          AppColors.accent.withOpacity(0.5),
          AppColors.primary.withOpacity(0.5),
          AppColors.secondary.withOpacity(0.5),
          AppColors.accent.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.85));
    
    canvas.drawCircle(center, radius * 0.85, paint2);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple pulse animation widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
