import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/chat_bubble.dart';
import '../../core/widgets/avatar_glow.dart';
import '../../core/widgets/network_result_builder.dart';
import '../../core/network/network_result.dart';
import '../../domain/models/chat_models.dart';
import '../../providers/data_providers.dart';

/// Chat Detail Screen
/// Full chat view with messages and input bar
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUsername;
  final String? otherAvatarUrl;
  
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    this.otherAvatarUrl,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  // TODO: Get online status from provider
  bool _isOnline = false; 
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppTheme.durationNormal,
        curve: Curves.easeOut,
      );
    }
  }
  
  Widget _buildReconnectingUI(Object error) {
    final errorMessage = error.toString();
    final showRetrying = errorMessage.contains('503') || 
                         errorMessage.contains('timeout') || 
                         errorMessage.contains('network');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated spinner
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              showRetrying ? 'Reconnecting...' : 'Loading messages...',
              style: AppTypography.headline(color: context.colors.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              showRetrying 
                  ? 'Please wait, retrying automatically'
                  : 'Checking connection',
              style: AppTypography.body(color: context.colors.textMutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    // Step 1: Clear input immediately (optimistic UI)
    _messageController.clear();
    setState(() => _isTyping = false);
    
    // Step 2: Send message (ONLY SQLite write, NO API)
    // Message will appear instantly via stream
    ref.read(chatControllerProvider(widget.conversationId).notifier).sendMessage(
      text,
      receiverName: widget.otherUsername,
    );
    
    // Step 3: Scroll to bottom after brief delay (message should be visible)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch chat state
    final chatState = ref.watch(chatControllerProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body: Stack(
        children: [
          // Background with radial orange glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.backgroundColor,
                    context.colors.surfaceColor,
                  ],
                ),
              ),
            ),
          ),
          
          // Radial orange glow behind messages
          Positioned(
            right: -100,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: AppColors.radialGlow(opacity: 0.15),
              ),
            ),
          ),
          
          // Main content
          Column(
            children: [
              // Top bar
              _buildTopBar(context),
              
              // Messages - OFFLINE-FIRST (SQLite Stream)
              Expanded(
                child: chatState.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, stackTrace) {
                    // This should never happen with offline-first, but handle gracefully
                    return Center(
                      child: Text(
                        'Loading messages...',
                        style: AppTypography.body(color: context.colors.textMutedColor),
                      ),
                    );
                  },
                  data: (messages) {
                    // Auto scroll to bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
                        _scrollToBottom();
                      }
                    });
                    
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Henüz mesaj yok. Merhaba de! 👋",
                              style: AppTypography.body(color: context.colors.textMutedColor),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isFirst = index == 0 || 
                            messages[index - 1].isMe != message.isMe;
                        final isLast = index == messages.length - 1 || 
                            (index < messages.length - 1 && messages[index + 1].isMe != message.isMe);
                        
                        return AnimatedChatBubble(
                          key: ValueKey(message.id),
                          message: message.content,
                          isMe: message.isMe,
                          timestamp: message.createdAt,
                          isFirst: isFirst,
                          isLast: isLast,
                          showTimestamp: isLast,
                          delay: Duration.zero,
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input bar
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: context.isDarkMode ? AppColors.glassDark : context.colors.surfaceColor.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: context.colors.textMutedColor.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: context.colors.textColor,
                  size: 22,
                ),
              ),
              
              // Avatar with Hero
              Hero(
                tag: 'avatar_${widget.conversationId}',
                child: SmallAvatar(
                  initials: widget.otherUsername.isNotEmpty ? widget.otherUsername.substring(0, 1).toUpperCase() : '?',
                  imageUrl: widget.otherAvatarUrl,
                  size: 40,
                  isOnline: _isOnline,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.otherUsername,
                      style: AppTypography.headline(color: context.colors.textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: AppTypography.caption1(
                        color: _isOnline 
                            ? AppColors.online 
                            : context.colors.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Call buttons
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesli arama özelliği yakında!')));
                },
                icon: Icon(Icons.phone_rounded, color: context.colors.textColor, size: 22),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görüntülü arama özelliği yakında!')));
                },
                icon: Icon(Icons.videocam_rounded, color: context.colors.textColor, size: 24),
              ),
              
              // More options menu (replaced call buttons)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.colors.textColor,
                  size: 24,
                ),
                color: context.colors.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  HapticFeedback.lightImpact();
                  // Handle menu actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Text('Block User'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: AppColors.warning, size: 20),
                        SizedBox(width: 12),
                        Text('Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: _isTyping ? 14 : 12,
            bottom: MediaQuery.of(context).padding.bottom + (_isTyping ? 14 : 12),
          ),
          decoration: BoxDecoration(
            color: context.isDarkMode ? AppColors.glassDark : context.colors.surfaceColor.withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: _isTyping 
                    ? AppColors.primary.withOpacity(0.3) 
                    : context.colors.textMutedColor.withOpacity(0.2),
                width: _isTyping ? 1 : 0.5,
              ),
            ),
            boxShadow: _isTyping ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Emoji button
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Show emoji picker
                },
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: AppColors.primarySoft,
                  size: 24,
                ),
              ),
              
              // Attachment button
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              
              // Text field
              Expanded(
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? Colors.white.withOpacity(_isTyping ? 0.12 : 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _isTyping ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: AppTypography.body(color: context.colors.textColor),
                    maxLines: 4,
                    minLines: 1,
                    onChanged: (value) {
                      setState(() => _isTyping = value.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...',
                      hintStyle: AppTypography.body(
                        color: context.colors.textMutedColor,
                      ),
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
              
              // Animated Send button
              _AnimatedSendButton(
                isActive: _isTyping,
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated Send Button with scale and glow effects
class _AnimatedSendButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onPressed;
  
  const _AnimatedSendButton({
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<_AnimatedSendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isActive) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isActive ? () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      } : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.isActive ? AppColors.primaryGradient : null,
            color: widget.isActive ? null : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isActive 
                  ? Colors.white.withOpacity(0.2) 
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: widget.isActive ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(_isPressed ? 0.6 : 0.4),
                blurRadius: _isPressed ? 20 : 12,
                spreadRadius: _isPressed ? 2 : 0,
              ),
            ] : null,
          ),
          child: Icon(
            Icons.send_rounded,
            color: widget.isActive 
                ? Colors.white 
                : AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}
