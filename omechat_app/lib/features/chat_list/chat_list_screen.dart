import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/models/chat_models.dart';
import '../../services/dummy_data_service.dart';
import '../chat_detail/chat_detail_screen.dart';
import 'widgets/neon_drawer.dart';
import '../stories/story_view_screen.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Chat List Screen - Ultimate Dark Neon Edition (Dummy Data)
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Data
  late List<Conversation> _allConversations;
  late List<Conversation> _filteredConversations;
  late List<Map<String, dynamic>> _stories;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Tabs
  int _selectedTab = 0; // 0: All, 1: Personal, 2: Work

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadData() {
    _allConversations = DummyDataService().getDummyChats();
    _filteredConversations = List.from(_allConversations);
    _stories = DummyDataService().getDummyStories();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(_allConversations);
      } else {
        _filteredConversations = _allConversations.where((chat) {
          return chat.otherUsername.toLowerCase().contains(query) ||
                 chat.lastMessage.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _deleteChat(String id) {
    setState(() {
      _allConversations.removeWhere((c) => c.id == id);
      _filteredConversations.removeWhere((c) => c.id == id);
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat deleted'), backgroundColor: Colors.red),
    );
  }

  void _pinChat(Conversation chat) {
    setState(() {
      // Move to top
      _allConversations.remove(chat);
      _allConversations.insert(0, chat);
      // Update filtered list too
      if (_filteredConversations.contains(chat)) {
        _filteredConversations.remove(chat);
        _filteredConversations.insert(0, chat);
      }
    });
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat pinned'), backgroundColor: AppColors.primary),
    );
  }

  void _muteChat(String id) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat muted'), backgroundColor: Colors.orangeAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const NeonDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('New Message Action'), 
               backgroundColor: AppColors.primary
             )
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(),
            
            // --- STORIES ---
            if (!_isSearching) _buildStoriesRow(),
            
            // --- FOLDERS TABS ---
            if (!_isSearching) _buildFolderTabs(),
            
            // --- SEARCH BAR (Animated Height) ---
             AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               height: _isSearching ? 60 : 0,
               child: _isSearching ? _buildSearchBar() : const SizedBox.shrink(),
             ),

            // --- CHAT LIST ---
            Expanded(
              child: _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredConversations[index];
                        return _buildConversationTile(chat);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSearching ? 'Search' : (AppLocalizations.of(context)?.messages ?? 'Messages'),
              style: AppTypography.largeTitle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 26),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassContainer(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        borderRadius: 12,
        backgroundColor: Colors.white10,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search chats...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white38),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesRow() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildMyStory();
          final story = _stories[index - 1];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  Widget _buildMyStory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white10,
                ),
                child: const Icon(Icons.person, color: Colors.white38, size: 30),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add, color: Colors.black, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('My Story', style: AppTypography.caption1(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => StoryViewScreen(story: story)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary, // Neon Orange Ring
                  width: 2.5,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(story['imageUrl']), // using image url as avatar for variety
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                story['username'].split(' ')[0], 
                style: AppTypography.caption1(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTabs() {
    final tabs = ['All Chats', 'Personal', 'Work'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: isSelected 
                    ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2))
                    : null,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                tabs[index],
                style: AppTypography.subheadline(
                  color: isSelected ? AppColors.primary : Colors.white38,
                ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation chat) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          _deleteChat(chat.id);
          return true;
        } else {
          // Pin / Archive
          _pinChat(chat);
          return false; // Don't dismiss, just action
        }
      },
      background: Container(
        color: AppColors.primary.withOpacity(0.2), // Left swipe (Pin)
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.push_pin, color: AppColors.primary),
      ),
      secondaryBackground: Container(
        color: Colors.red.withOpacity(0.8), // Right swipe (Delete)
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(userId: chat.otherUserId),
              ),
            );
          },
          highlightColor: AppColors.primary.withOpacity(0.1),
          splashColor: AppColors.primary.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Avatar with Online Dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(chat.otherAvatarUrl ?? ''),
                      child: chat.otherAvatarUrl == null 
                          ? Text(chat.initials, style: const TextStyle(color: Colors.white)) 
                          : null,
                    ),
                    if (chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C73E),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat.otherUsername,
                            style: AppTypography.headline(color: Colors.white),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.done_all, color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(chat.lastActivity),
                                style: AppTypography.caption1(
                                  color: chat.hasUnread ? AppColors.primary : Colors.white38
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              style: AppTypography.subheadline(
                                color: chat.hasUnread ? Colors.white : Colors.white54
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No chats found',
            style: AppTypography.headline(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inHours < 24) {
      return "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
    }
    return "${time.day}/${time.month}";
  }
}
