import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';

class NeonDrawer extends StatelessWidget {
  const NeonDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background.withOpacity(0.9),
      child: Column(
        children: [
          // User Account Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?u=0'), // Self User
                  fit: BoxFit.cover,
                ),
              ),
            ),
            accountName: Text(
              'Gökhan (You)',
              style: AppTypography.headline(color: Colors.white),
            ),
            accountEmail: Text(
              '+90 555 123 45 67',
              style: AppTypography.body(color: Colors.white70),
            ),
            otherAccountsPictures: [
              IconButton(
                onPressed: () {}, // Toggle Night Mode
                icon: const Icon(Icons.dark_mode, color: AppColors.primary),
              ),
            ],
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                 _buildDrawerItem(context, Icons.group_add_outlined, 'New Group'),
                 _buildDrawerItem(context, Icons.person_outline_rounded, 'Contacts'),
                 _buildDrawerItem(context, Icons.call_outlined, 'Calls'),
                 _buildDrawerItem(context, Icons.bookmark_border_rounded, 'Saved Messages'),
                 _buildDrawerItem(context, Icons.settings_outlined, 'Settings'),
                 const Divider(color: Colors.white10),
                 _buildDrawerItem(context, Icons.person_add_outlined, 'Invite Friends'),
                 _buildDrawerItem(context, Icons.help_outline_rounded, 'Telegram Features'),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'OmeChat v1.0.0 (Neon Edition)',
              style: AppTypography.caption1(color: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 26),
      title: Text(
        title, 
        style: AppTypography.body(color: Colors.white).copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // Close Drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title Clicked!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(milliseconds: 500),
          ),
        );
      },
    );
  }
}
