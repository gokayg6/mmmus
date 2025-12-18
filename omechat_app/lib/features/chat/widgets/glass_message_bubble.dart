import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GLASS MESSAGE BUBBLE - iOS 18 Depth Effect
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Premium chat bubble with:
/// - Glassmorphism 2.0 (Blur: 25, Border: 0.5px @ 10% white)
/// - iOS-style tail via CustomPainter
/// - Scroll-based gradient flow
/// - Shadow depth

class GlassMessageBubble extends StatelessWidget {
  final String text;
  final bool isOwn;
  final DateTime timestamp;
  final double scrollOffset;
  final bool showTail;
  final VoidCallback? onLongPress;
  
  const GlassMessageBubble({
    super.key,
    required this.text,
    required this.isOwn,
    required this.timestamp,
    this.scrollOffset = 0.0,
    this.showTail = true,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Scroll-based gradient shift
    final gradientShift = (scrollOffset / screenHeight).clamp(0.0, 1.0);
    
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            bottom: 8,
            left: isOwn ? 48 : 0,
            right: isOwn ? 0 : 48,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Shadow layer
              Positioned(
                bottom: -2,
                left: 2,
                right: 2,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main bubble with glass effect
              ClipRRect(
                borderRadius: _getBorderRadius(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                      minWidth: 60,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      gradient: isOwn 
                          ? _getOwnBubbleGradient(gradientShift)
                          : _getOtherBubbleGradient(),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: AppTypography.body(
                            color: isOwn ? Colors.white : Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(isOwn ? 0.7 : 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // iOS Tail (CustomPaint)
              if (showTail)
                Positioned(
                  bottom: 0,
                  right: isOwn ? -6 : null,
                  left: isOwn ? null : -6,
                  child: CustomPaint(
                    size: const Size(12, 16),
                    painter: _BubbleTailPainter(
                      isOwn: isOwn,
                      color: isOwn ? AppColors.primary : AppColors.cardDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOwn ? 18 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 18),
    );
  }

  LinearGradient _getOwnBubbleGradient(double shift) {
    // Gradient flow based on scroll position
    final startColor = Color.lerp(
      AppColors.primarySoft,
      AppColors.primary,
      shift,
    )!;
    final endColor = Color.lerp(
      AppColors.primary,
      AppColors.primaryDark,
      shift,
    )!;
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startColor, endColor],
    );
  }

  LinearGradient _getOtherBubbleGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.04),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// BUBBLE TAIL PAINTER - iOS-style bezier tail
/// ═══════════════════════════════════════════════════════════════════════════

class _BubbleTailPainter extends CustomPainter {
  final bool isOwn;
  final Color color;

  _BubbleTailPainter({required this.isOwn, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isOwn) {
      // Right-side tail (sent messages)
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width, size.height);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, 0, size.height * 0.4);
      path.close();
    } else {
      // Left-side tail (received messages)
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.3, 0, size.height);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width, size.height * 0.4);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return isOwn != oldDelegate.isOwn || color != oldDelegate.color;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TYPING INDICATOR - Animated glass dots
/// ═══════════════════════════════════════════════════════════════════════════

class GlassTypingIndicator extends StatefulWidget {
  const GlassTypingIndicator({super.key});

  @override
  State<GlassTypingIndicator> createState() => _GlassTypingIndicatorState();
}

class _GlassTypingIndicatorState extends State<GlassTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final progress = (_controller.value + delay) % 1.0;
                    final bounce = math.sin(progress * math.pi);
                    
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -bounce * 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.4 + bounce * 0.4),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// VOICE MESSAGE WAVEFORM
/// ═══════════════════════════════════════════════════════════════════════════

class GlassVoiceWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final bool isPlaying;
  final VoidCallback? onTap;
  final Duration duration;

  const GlassVoiceWaveform({
    super.key,
    required this.amplitudes,
    required this.progress,
    required this.duration,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primaryDark.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/Pause button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Waveform
                CustomPaint(
                  size: const Size(120, 32),
                  painter: _WaveformPainter(
                    amplitudes: amplitudes,
                    progress: progress,
                    primaryColor: AppColors.primary,
                    secondaryColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Duration
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = 2.0;
    final totalBars = amplitudes.length;
    final progressIndex = (progress * totalBars).floor();

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap);
      final amplitude = amplitudes[i].clamp(0.1, 1.0);
      final barHeight = amplitude * size.height;
      final y = (size.height - barHeight) / 2;

      // Color based on progress (played vs unplayed)
      final color = i <= progressIndex ? primaryColor : secondaryColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           amplitudes != oldDelegate.amplitudes;
  }
}
