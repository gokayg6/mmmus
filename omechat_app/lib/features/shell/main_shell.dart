import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_dock.dart';
import '../../core/widgets/animated_background.dart';
import '../random_connect/random_connect_screen.dart';
import '../chat_list/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../points/points_screen.dart';

/// Main Shell with bottom glass dock navigation
/// 5 tabs: Keşfet, Mesajlar, Profil, Puan, Ayarlar
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> 
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // 5 screens for full app experience
  final List<Widget> _screens = const [
    RandomConnectScreen(),  // Main video matching screen
    ChatListScreen(),       // Messages/chats list
    ProfileScreen(),        // User profile
    PointsScreen(),         // Points/gamification
    SettingsScreen(),       // App settings
  ];
  
  // 5 dock items with proper icons
  final List<GlassDockItem> _dockItems = const [
    GlassDockItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Keşfet',
    ),
    GlassDockItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Mesajlar',
    ),
    GlassDockItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
    GlassDockItem(
      icon: Icons.stars_outlined,
      activeIcon: Icons.stars_rounded,
      label: 'Puan',
    ),
    GlassDockItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Ayarlar',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onTabTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background
          const AnimatedBackground(
            animate: false,
            child: SizedBox.expand(),
          ),
          
          // Screen content with PageView for smooth transitions
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _screens,
          ),
          
          // Bottom dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassDock(
              currentIndex: _currentIndex,
              onTap: _onTabTap,
              items: _dockItems,
            ),
          ),
        ],
      ),
    );
  }
}
