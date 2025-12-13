import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// Animated Glowing Button
/// Features pulsing glow, press animations, and gradient background
class GlowingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double size;
  final bool isLoading;
  final bool showPulse;
  final bool isCircular;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  
  const GlowingButton({
    super.key,
    this.onPressed,
    required this.child,
    this.size = 120,
    this.isLoading = false,
    this.showPulse = true,
    this.isCircular = true,
    this.gradient,
    this.width,
    this.height,
    this.padding,
  });

  /// Rectangular glowing button
  const GlowingButton.rectangle({
    super.key,
    this.onPressed,
    required this.child,
    this.width = double.infinity,
    this.height = 56,
    this.isLoading = false,
    this.showPulse = false,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  })  : size = 56,
        isCircular = false;

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for idle state - 120Hz optimized
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),  // 120Hz: ~180 frames
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.showPulse && !widget.isLoading) {
      _pulseController.repeat(reverse: true);
    }
    
    // Press scale animation
    _pressController = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: AppTheme.curveDefault),
    );
    
    // Loading rotation - 120Hz optimized
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),  // 120Hz: ~120 frames
      vsync: this,
    );
    if (widget.isLoading) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(GlowingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _pulseController.stop();
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _rotationController.stop();
      _rotationController.reset();
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.button;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : () {
        HapticFeedback.mediumImpact();
        widget.onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.isCircular 
                ? _buildCircularButton(gradient)
                : _buildRectangularButton(gradient),
          );
        },
      ),
    );
  }

  Widget _buildCircularButton(Gradient gradient) {
    final glowIntensity = _isPressed ? 0.8 : _pulseAnimation.value;
    
    return SizedBox(
      width: widget.size + 60,
      height: widget.size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing glow
          AnimatedContainer(
            duration: AppTheme.durationNormal,
            width: widget.size + 40,
            height: widget.size + 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(glowIntensity * 0.6),
                  blurRadius: 40 + (glowIntensity * 20),
                  spreadRadius: 5 + (glowIntensity * 10),
                ),
                BoxShadow(
                  color: AppColors.primarySoft.withOpacity(glowIntensity * 0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          
          // Loading ring
          if (widget.isLoading)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) => Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size + 20, widget.size + 20),
                  painter: _ArcPainter(
                    color: AppColors.primarySoft,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          
          // Main button
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isLoading ? AppGradients.buttonPressed : gradient,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRectangularButton(Gradient gradient) {
    final glowIntensity = _isPressed ? 0.8 : (_pulseAnimation.value * 0.5 + 0.3);
    
    return Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        gradient: widget.isLoading ? AppGradients.buttonDisabled : gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(glowIntensity * 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : widget.child,
      ),
    );
  }
}

/// Arc painter for loading animation
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, math.pi * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
