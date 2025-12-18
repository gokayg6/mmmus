import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass_navbar.dart';
import '../../core/widgets/animated_background.dart';
import '../random_connect/random_connect_screen.dart';
import '../chat_list/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../points/points_screen.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Main Shell with floating glass navbar
/// 
/// Structure follows Stack pattern with background under glass
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
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
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    // Build navbar items with localized labels
    final navbarItems = [
      NavbarItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: l10n?.discover ?? 'Discover',
      ),
      NavbarItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: l10n?.chat ?? 'Chat',
      ),
      NavbarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n?.profile ?? 'Profile',
      ),
      NavbarItem(
        icon: Icons.stars_outlined,
        activeIcon: Icons.stars_rounded,
        label: l10n?.credits ?? 'Credits',
      ),
      NavbarItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: l10n?.settings ?? 'Settings',
      ),
    ];
    
    return Scaffold(
      // Omechat dark background: #0B0F1A
      backgroundColor: isDark ? const Color(0xFF0B0F1A) : AppColors.backgroundLight,
      body: Stack(
        children: [
          // 1&2) Content to be refracted (Background + Pages)
          // 1&2) Content (Background + Pages)
          Stack(
            children: [
              const AnimatedBackground(
                animate: false,
                child: SizedBox.expand(),
              ),
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                allowImplicitScrolling: false,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: _screens,
              ),
            ],
          ),
          
          // 3) iOS 26-style Liquid Glass Navbar with animated blob
          LiquidGlassNavbar(
            key: Key('navbar_${l10n?.localeName ?? 'en'}'), // Force rebuild on locale change
            currentIndex: _currentIndex,
            onTap: _onTabTap,
            items: navbarItems,
          ),
        ],
      ),
    );
  }
}
