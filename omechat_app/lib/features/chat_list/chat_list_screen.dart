import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/avatar_glow.dart';
import '../../core/widgets/network_result_builder.dart';
import '../../core/network/network_result.dart';
import '../../domain/models/chat_models.dart';
import '../../providers/data_providers.dart';
import '../../services/friend_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/api_client.dart';
import 'package:dio/dio.dart';
import '../chat_detail/chat_detail_screen.dart';
import 'friend_requests_modal.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Chat List Screen - Uses ChatRepository for real data
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

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
    
    // Ensure socket connected
    final apiClient = ref.watch(apiClientProvider);
    final socketService = ref.watch(chatSocketServiceProvider);
    
    // Lazy connect logic
    if (apiClient.accessToken != null && !socketService.isConnected) {
       final baseUrl = apiClient.dio.options.baseUrl; 
       socketService.connect(baseUrl, apiClient.accessToken!);
    }
    
    // Note: Real-time friend event listening moved to initState to avoid memory leaks
    
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
                    AppLocalizations.of(context)?.messages ?? 'Messages',
                    style: AppTypography.largeTitle(
                      color: context.colors.textColor,
                    ),
                  ),
                  const Spacer(),
                  
                  // Friend Requests Button (New)
                  IconButton(
                    onPressed: () => _showFriendRequests(context),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.notifications_outlined, color: context.colors.textColor),
                        // Red dot indicator based on FUTURE state (complex, skipping red dot logic for now to keep it simple or fetch count)
                        // Ideally we check incoming requests count here.
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // New Chat / Add Friend Button
                  _NewChatButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showNewChatOptions(context);
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
                          hintText: AppLocalizations.of(context)?.searchChat ?? 'Search chat...',
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
            
            // Conversations list - OFFLINE-FIRST (SQLite Stream)
            Expanded(
              child: conversationsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) {
                  // This should rarely happen with offline-first, but handle gracefully
                  return _buildErrorState(error);
                },
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.noMessages ?? 'No chats yet',
                            style: AppTypography.headline(color: context.colors.textMutedColor),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildConversationList(conversations);
                },
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
    // Check if user is not logged in (401 or no token)
    final apiClient = ref.read(apiClientProvider);
    final isLoggedIn = apiClient.accessToken != null;
    
    String errorMessage = 'An error occurred';
    if (!isLoggedIn) {
      errorMessage = 'Please log in to view chats';
    } else if (error.toString().contains('400') || error.toString().contains('401')) {
      errorMessage = 'Session invalid. Please log in again.';
    } else {
      errorMessage = 'Error: ${error.toString()}';
    }
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLoggedIn ? Icons.error_outline_rounded : Icons.login_rounded,
            size: 48,
            color: context.colors.textMutedColor,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              style: AppTypography.headline(color: context.colors.textColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _onRefresh,
            child: Text('Try again', style: AppTypography.body(color: AppColors.primary)),
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
              'No chats yet',
              style: AppTypography.headline(color: context.colors.textSecondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Meet new people from the Discover tab!',
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

  void _showFriendRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => const FriendRequestsModal(),
    );
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New Chat', style: AppTypography.headline(color: context.colors.textColor)),
            const SizedBox(height: 24),
            _OptionTile(
              icon: Icons.person_add_rounded,
              title: 'Add Friend',
              subtitle: 'Add by username',
              onTap: () {
                Navigator.pop(context);
                _showAddFriendDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat with Friends',
              subtitle: 'Select from friend list',
              onTap: () {
                Navigator.pop(context);
                _showFriendsList(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 20),
                Text('Add Friend', style: AppTypography.headline(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Send a friend request by entering username.',
                  style: AppTypography.body(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Glassy Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      hintText: 'Username...',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      icon: Icon(Icons.search_rounded, color: Colors.white30),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) return;
                            try {
                              final friendService = ref.read(friendServiceProvider);
                              await friendService.sendRequest(controller.text.trim());
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Friend request sent!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                String errorMessage = 'An error occurred';
                                if (e is DioException) {
                                   if (e.response?.data != null && e.response!.data is Map) {
                                      errorMessage = e.response!.data['detail'] ?? e.message ?? 'Unknown error';
                                   } else {
                                      errorMessage = e.message ?? 'Server error';
                                   }
                                } else {
                                  errorMessage = e.toString();
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFriendsList(BuildContext context) {
     final friendService = ref.read(friendServiceProvider);
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder(
            future: friendService.getFriends(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.error != null) return Center(child: Text('Hata oluştu'));
              final friends = snapshot.data as List<dynamic>; 
              
              if (friends.isEmpty) {
                 return const Center(child: Text('Henüz arkadaşın yok.'));
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friendReq = friends[index]; 
                  final friend = friendReq.friend;

                  return ListTile(
                    leading: CircleAvatar(child: Text(friend.username[0].toUpperCase())),
                    title: Text(friend.username, style: TextStyle(color: context.colors.textColor)),
                    onTap: () {
                      Navigator.pop(context);
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            conversationId: friend.id,
                            otherUsername: friend.username,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subheadline(color: context.colors.textColor)),
                Text(subtitle, style: AppTypography.caption1(color: context.colors.textMutedColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
          // Updated Icon to Person + Add
          child: const Icon(
            Icons.person_add_alt_1_rounded,
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
