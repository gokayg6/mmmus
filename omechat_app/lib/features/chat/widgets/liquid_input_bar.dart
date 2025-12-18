import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIQUID KEYBOARD TRANSITION
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Input bar that "sticks" to the keyboard with elastic animation,
/// stretching like liquid when the keyboard appears/disappears.

class LiquidInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onVoice;
  final String hintText;
  final bool showSendButton;
  
  const LiquidInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onVoice,
    this.hintText = 'Mesaj yaz...',
    this.showSendButton = true,
  });

  @override
  State<LiquidInputBar> createState() => _LiquidInputBarState();
}

class _LiquidInputBarState extends State<LiquidInputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _elasticController;
  late Animation<double> _elasticAnimation;
  
  bool _hasText = false;
  
  @override
  void initState() {
    super.initState();
    _elasticController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _elasticAnimation = CurvedAnimation(
      parent: _elasticController,
      curve: Curves.elasticOut,
    );
    
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _elasticController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _elasticController.forward();
      } else {
        _elasticController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      margin: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : safeBottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding > 0 ? 12 : 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Attachment button
                if (widget.onAttachment != null)
                  _GlassActionButton(
                    icon: Icons.add_rounded,
                    onTap: widget.onAttachment!,
                  ),
                
                const SizedBox(width: 8),
                
                // Input field - expands with content
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    constraints: BoxConstraints(
                      maxHeight: _hasText ? 120 : 48,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      style: AppTypography.body(),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Voice or Send button (morphs based on text)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _hasText
                      ? _GlassSendButton(
                          key: const ValueKey('send'),
                          onTap: widget.onSend,
                        )
                      : widget.onVoice != null
                          ? _GlassActionButton(
                              key: const ValueKey('voice'),
                              icon: Icons.mic_rounded,
                              onTap: widget.onVoice!,
                              isPrimary: true,
                            )
                          : _GlassSendButton(
                              key: const ValueKey('send_empty'),
                              onTap: widget.onSend,
                              isEnabled: false,
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-style action button (attachment, voice, etc.)
class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  
  const _GlassActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(isPrimary ? 1.0 : 0.7),
          size: 20,
        ),
      ),
    );
  }
}

/// Glass-style send button with gradient
class _GlassSendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isEnabled;
  
  const _GlassSendButton({
    super.key,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isEnabled ? AppColors.primaryGradient : null,
          color: isEnabled ? null : Colors.white.withOpacity(0.05),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.send_rounded,
          color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.3),
          size: 20,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// INTERACTIVE CHAT BACKGROUND - Particle effects on typing
/// ═══════════════════════════════════════════════════════════════════════════

class ChatBackgroundParticles extends StatefulWidget {
  final bool isTyping;
  
  const ChatBackgroundParticles({super.key, this.isTyping = false});

  @override
  State<ChatBackgroundParticles> createState() => _ChatBackgroundParticlesState();
}

class _ChatBackgroundParticlesState extends State<ChatBackgroundParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
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
    if (!widget.isTyping) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              progress: _controller.value,
              intensity: widget.isTyping ? 1.0 : 0.0,
            ),
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final double intensity;
  
  _ParticlePainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.05 * intensity)
      ..style = PaintingStyle.fill;
    
    // Simple floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * ((i * 0.05 + progress) % 1.0));
      final y = size.height * (0.3 + 0.4 * ((i * 0.07 + progress * 0.5) % 1.0));
      final radius = 2.0 + (i % 3) * 1.5;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return progress != oldDelegate.progress || intensity != oldDelegate.intensity;
  }
}
