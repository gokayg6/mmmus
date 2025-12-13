import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/chat_bubble.dart';
import '../../core/widgets/avatar_glow.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/message.dart';
import '../../mock/mock_data.dart';

/// Chat Detail Screen
/// Full chat view with messages and input bar
class ChatDetailScreen extends StatefulWidget {
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
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Message> _messages;
  bool _isTyping = false;
  bool _isOnline = true; // Placeholder
  
  @override
  void initState() {
    super.initState();
    _messages = MockData.getMessagesForConversation(widget.conversationId);
    
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
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
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _messages.add(Message(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        content: _messageController.text.trim(),
        senderId: 'me',
        timestamp: DateTime.now(),
        isMe: true,
      ));
    });
    
    _messageController.clear();
    
    // Scroll to show new message
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
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
              
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isFirst = index == 0 || 
                        _messages[index - 1].isMe != message.isMe;
                    final isLast = index == _messages.length - 1 || 
                        _messages[index + 1].isMe != message.isMe;
                    
                    return AnimatedChatBubble(
                      key: ValueKey(message.id),
                      message: message.content,
                      isMe: message.isMe,
                      timestamp: message.timestamp,
                      isFirst: isFirst,
                      isLast: isLast,
                      showTimestamp: isLast,
                      delay: Duration(milliseconds: index * 50),
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
