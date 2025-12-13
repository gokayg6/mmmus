import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Chat Bubble Widget
/// Sent messages: Orange gradient with glow
/// Received messages: Dark surface with orange border
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? timestamp;
  final bool showTimestamp;
  final bool isFirst;
  final bool isLast;
  
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.timestamp,
    this.showTimestamp = true,
    this.isFirst = true,
    this.isLast = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 16,
        right: isMe ? 16 : 60,
        top: isFirst ? 8 : 2,
        bottom: isLast ? 8 : 2,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe ? AppGradients.bubbleSent : null,
              color: isMe ? null : AppColors.bubbleReceived,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isFirst || isMe ? 20 : 6),
                topRight: Radius.circular(isFirst || !isMe ? 20 : 6),
                bottomLeft: Radius.circular(isLast || isMe ? 20 : 6),
                bottomRight: Radius.circular(isLast || !isMe ? 20 : 6),
              ),
              border: isMe ? null : Border.all(
                color: AppColors.borderOrange,
                width: 1,
              ),
              boxShadow: isMe ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Text(
              message,
              style: AppTypography.body(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          if (showTimestamp && timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(timestamp!),
                style: AppTypography.caption2(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animated Chat Bubble - Slides in with fade and scale
class AnimatedChatBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final DateTime? timestamp;
  final bool showTimestamp;
  final bool isFirst;
  final bool isLast;
  final Duration delay;
  
  const AnimatedChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.timestamp,
    this.showTimestamp = true,
    this.isFirst = true,
    this.isLast = true,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),  // 120Hz: ~30 frames
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: child,
          ),
        ),
      ),
      child: ChatBubble(
        message: widget.message,
        isMe: widget.isMe,
        timestamp: widget.timestamp,
        showTimestamp: widget.showTimestamp,
        isFirst: widget.isFirst,
        isLast: widget.isLast,
      ),
    );
  }
}

/// Typing Indicator Bubble
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) => AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    ));
    
    _animations = _controllers.map((controller) => Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ))).toList();
    
    // Stagger the animations
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 60, top: 4, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bubbleReceived,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderOrange),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) => Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(
                  0.4 + (_animations[index].value * 0.6),
                ),
                shape: BoxShape.circle,
              ),
            ),
          )),
        ),
      ),
    );
  }
}
