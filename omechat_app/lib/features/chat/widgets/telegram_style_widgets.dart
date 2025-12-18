import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/haptics/haptic_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TELEGRAM-STYLE MESSAGE BUBBLE (DARK NEON EDITION)
/// ═══════════════════════════════════════════════════════════════════════════

class TelegramBubble extends StatelessWidget {
  final String text;
  final bool isOwn;
  final DateTime timestamp;
  final bool showTail;
  final bool isDelivered;
  final bool isRead;
  final VoidCallback? onLongPress;
  final String? replyTo;
  
  const TelegramBubble({
    super.key,
    required this.text,
    required this.isOwn,
    required this.timestamp,
    this.showTail = true,
    this.isDelivered = true,
    this.isRead = false,
    this.onLongPress,
    this.replyTo,
  });

  @override
  Widget build(BuildContext context) {
    // DARK NEON COLORS
    final bubbleColor = isOwn 
        ? AppColors.primary  // Neon Orange for sent
        : const Color(0xFF1E1E1E); // Dark Grey for received
    
    final textColor = isOwn ? Colors.white : Colors.white;
    final timeColor = isOwn ? Colors.white70 : Colors.white38;
    
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          HapticEngine.longPress();
          onLongPress?.call();
        },
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isOwn ? 60 : (showTail ? 8 : 16),
            right: isOwn ? (showTail ? 8 : 16) : 60,
          ),
          child: CustomPaint(
            painter: showTail 
                ? _TelegramTailPainter(isOwn: isOwn, color: bubbleColor)
                : null,
            child: Container(
              margin: EdgeInsets.only(
                left: !isOwn && showTail ? 8 : 0,
                right: isOwn && showTail ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwn ? 18 : (showTail ? 4 : 18)),
                  bottomRight: Radius.circular(isOwn ? (showTail ? 4 : 18) : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply preview if exists
                  if (replyTo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isOwn ? Colors.white : AppColors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        replyTo!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isOwn ? Colors.white70 : AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  // Message with inline time
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      // Message text
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                      
                      // Time + read status (inline with text)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: timeColor,
                              ),
                            ),
                            if (isOwn) ...[
                              const SizedBox(width: 3),
                              Icon(
                                isRead 
                                    ? Icons.done_all_rounded 
                                    : Icons.done_rounded,
                                size: 16,
                                color: Colors.white, // White checks on Orange bg
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Telegram-style tail painter
class _TelegramTailPainter extends CustomPainter {
  final bool isOwn;
  final Color color;

  _TelegramTailPainter({required this.isOwn, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isOwn) {
      // Right tail
      path.moveTo(size.width - 8, size.height - 12);
      path.lineTo(size.width, size.height - 6);
      path.quadraticBezierTo(
        size.width + 6, size.height,
        size.width, size.height + 2,
      );
      path.lineTo(size.width - 8, size.height - 4);
      path.close();
    } else {
      // Left tail
      path.moveTo(8, size.height - 12);
      path.lineTo(0, size.height - 6);
      path.quadraticBezierTo(
        -6, size.height,
        0, size.height + 2,
      );
      path.lineTo(8, size.height - 4);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TelegramTailPainter oldDelegate) {
    return isOwn != oldDelegate.isOwn || color != oldDelegate.color;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TELEGRAM-STYLE INPUT BAR (DARK NEON)
/// ═══════════════════════════════════════════════════════════════════════════

class TelegramInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onVoice;
  final VoidCallback? onEmoji;
  
  const TelegramInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onVoice,
    this.onEmoji,
  });

  @override
  State<TelegramInputBar> createState() => _TelegramInputBarState();
}

class _TelegramInputBarState extends State<TelegramInputBar> {
  bool _hasText = false;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
  
  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151014), // Dark Surface
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji button
          IconButton(
            onPressed: widget.onEmoji,
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.white54,
              size: 26,
            ),
          ),
          
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white10, // Transparent White
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                cursorColor: AppColors.primary,
              ),
            ),
          ),
          
          // Attachment button
          IconButton(
            onPressed: widget.onAttachment,
            icon: const Icon(
              Icons.attach_file_rounded,
              color: Colors.white54,
              size: 26,
            ),
          ),
          
          // Send or Voice button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _hasText
                ? IconButton(
                    key: const ValueKey('send'),
                    onPressed: () {
                      HapticEngine.messageSent();
                      widget.onSend();
                    },
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('voice'),
                    onPressed: widget.onVoice,
                    icon: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TELEGRAM-STYLE DATE SEPARATOR
/// ═══════════════════════════════════════════════════════════════════════════

class TelegramDateSeparator extends StatelessWidget {
  final DateTime date;
  
  const TelegramDateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TELEGRAM-STYLE TYPING INDICATOR
/// ═══════════════════════════════════════════════════════════════════════════

class TelegramTypingIndicator extends StatefulWidget {
  final String username;
  
  const TelegramTypingIndicator({super.key, required this.username});

  @override
  State<TelegramTypingIndicator> createState() => _TelegramTypingIndicatorState();
}

class _TelegramTypingIndicatorState extends State<TelegramTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.username} is typing',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dots = '.' * ((_controller.value * 4).floor() % 4);
              return Text(
                dots,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
