import 'package:flutter/material.dart';
import '../../core/widgets/liquid_glass_navbar.dart';

/// Demo screen showing how to use the iOS 26-style Liquid Glass Navigation Bar
/// 
/// INTEGRATION EXAMPLE:
/// Replace the existing CustomGlassNavbar with LiquidGlassNavbar
class LiquidGlassNavbarDemo extends StatefulWidget {
  const LiquidGlassNavbarDemo({super.key});

  @override
  State<LiquidGlassNavbarDemo> createState() => _LiquidGlassNavbarDemoState();
}

class _LiquidGlassNavbarDemoState extends State<LiquidGlassNavbarDemo> {
  int _selectedIndex = 0;

  // Define navigation items
  final List<NavbarItem> _navItems = const [
    NavbarItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chats',
    ),
    NavbarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Friends',
    ),
    NavbarItem(
      icon: Icons.videocam_outlined,
      activeIcon: Icons.videocam,
      label: 'Random',
    ),
    NavbarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  // Screen content for each tab
  final List<Widget> _screens = [
    _DemoContent(title: 'Chats', icon: Icons.chat_bubble),
    _DemoContent(title: 'Friends', icon: Icons.people),
    _DemoContent(title: 'Random Connect', icon: Icons.videocam),
    _DemoContent(title: 'Profile', icon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Current screen content
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          
          // iOS 26-style Liquid Glass Navigation Bar
          LiquidGlassNavbar(
            currentIndex: _selectedIndex,
            items: _navItems,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}

/// Demo content widget for each tab
class _DemoContent extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DemoContent({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050304),
            Color(0xFF120806),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: const Color(0xFFFF7A1A),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap tabs to see blob animation\nDrag on navbar to interact',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8A7A6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
