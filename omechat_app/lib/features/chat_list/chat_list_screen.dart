import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/avatar_glow.dart';
import '../../domain/models/chat_models.dart';
import '../../providers/data_providers.dart';
import '../chat_detail/chat_detail_screen.dart';

/// Chat List Screen - Uses ChatRepository for real data
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  
  Future<void> _onRefresh() async {
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Mesajlar',
                    style: AppTypography.largeTitle(
                      color: context.colors.textColor,
                    ),
                  ),
                  const Spacer(),
                  // New chat button
                  _NewChatButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigate to random connect
                    },
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: AppTheme.radiusMedium,
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: context.colors.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: AppTypography.body(color: context.colors.textColor),
                        decoration: InputDecoration(
                          hintText: 'Sohbet ara...',
                          hintStyle: AppTypography.body(
                            color: context.colors.textMutedColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Conversations list
            Expanded(
              child: conversationsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
                data: (conversations) => _buildConversationList(conversations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 4,
      itemBuilder: (context, index) => _ShimmerTile(index: index),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: context.colors.textMutedColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: AppTypography.headline(color: context.colors.textColor),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _onRefresh,
            child: Text('Tekrar dene', style: AppTypography.body(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: context.colors.textMutedColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz sohbet yok',
              style: AppTypography.headline(color: context.colors.textSecondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Keşfet sekmesinden yeni insanlarla tanış!',
              style: AppTypography.body(color: context.colors.textMutedColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: context.colors.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _StaggeredItem(
            index: index,
            child: _ConversationTile(
              conversation: conversation,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      conversationId: conversation.id,
                      otherUsername: conversation.otherUsername,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewChatButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewChatButton({required this.onTap});

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.edit_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Conversation Tile Widget
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        borderRadius: AppTheme.radiusMedium,
        child: Row(
          children: [
            // Avatar with Hero
            Hero(
              tag: 'avatar_${conversation.id}',
              child: SmallAvatar(
                initials: conversation.initials,
                imageUrl: conversation.otherAvatarUrl,
                size: 54,
                isOnline: conversation.isOnline,
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Name and message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUsername,
                          style: AppTypography.headline(
                            color: context.colors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastActivity),
                        style: AppTypography.caption1(
                          color: conversation.hasUnread 
                              ? AppColors.primary 
                              : context.colors.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: AppTypography.subheadline(
                            color: conversation.hasUnread 
                                ? context.colors.textColor
                                : context.colors.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.hasUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: conversation.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}g';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}s';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}dk';
    } else {
      return 'şimdi';
    }
  }
}

/// Unread Badge Widget
class _UnreadBadge extends StatelessWidget {
  final int count;
  
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: AppTypography.caption1(color: Colors.white),
      ),
    );
  }
}

/// Staggered animation item
class _StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  
  const _StaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}

/// Shimmer loading tile
class _ShimmerTile extends StatelessWidget {
  final int index;
  const _ShimmerTile({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: AppTheme.radiusMedium,
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: context.colors.textMutedColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.colors.textMutedColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.colors.textMutedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
