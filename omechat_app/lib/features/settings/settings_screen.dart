import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import 'package:omechat/l10n/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'language_settings_screen.dart';

/// Settings Screen - App configuration with theme toggle and logout
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _soundEffects = true;
  bool _haptics = true;


  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    
    // Get current language display name
    final currentLang = SupportedLanguage.fromCode(languageState.locale.languageCode);
    
    // Get localized strings
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.settings ?? 'Settings', 
                      style: AppTypography.largeTitle(
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.customizePreferences ?? 'Customize app preferences',
                      style: AppTypography.footnote(
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Settings sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User section (if logged in)
                  if (authState.isAuthenticated) ...[
                    _SectionHeader(title: l10n?.account ?? 'Account'),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.primary,
                            title: authState.user?.username ?? 'Kullanıcı',
                            subtitle: authState.user?.email ?? '',
                          ),
                          _Divider(),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            iconColor: AppColors.error,
                            title: l10n?.logout ?? 'Logout',
                            onTap: () => _showLogoutConfirmation(l10n),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Appearance section
                  _SectionHeader(title: l10n?.appearance ?? 'Appearance'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          iconColor: isDarkMode ? AppColors.primary : AppColors.warning,
                          title: l10n?.darkMode ?? 'Dark Mode',
                          subtitle: isDarkMode ? (l10n?.darkThemeActive ?? 'Dark theme active') : (l10n?.lightThemeActive ?? 'Light theme active'),
                          trailing: Switch(
                            value: isDarkMode,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              ref.read(themeProvider.notifier).setTheme(
                                v ? ThemeMode.dark : ThemeMode.light
                              );
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: AppColors.primarySoft,
                          title: l10n?.language ?? 'Language',
                          subtitle: currentLang.displayName,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LanguageSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Notifications section
                  _SectionHeader(title: l10n?.notificationsSection ?? 'Notifications'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_rounded,
                          iconColor: AppColors.warning,
                          title: l10n?.notifications ?? 'Notifications',
                          subtitle: l10n?.pushNotifications ?? 'Push notifications',
                          trailing: Switch(
                            value: _notifications,
                            onChanged: (v) => setState(() => _notifications = v),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: AppColors.success,
                          title: l10n?.soundEffects ?? 'Sound Effects',
                          subtitle: l10n?.appSounds ?? 'App sounds',
                          trailing: Switch(
                            value: _soundEffects,
                            onChanged: (v) => setState(() => _soundEffects = v),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.vibration_rounded,
                          iconColor: AppColors.primary,
                          title: l10n?.vibration ?? 'Vibration',
                          subtitle: l10n?.hapticFeedback ?? 'Haptic feedback',
                          trailing: Switch(
                            value: _haptics,
                            onChanged: (v) => setState(() => _haptics = v),
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy section
                  _SectionHeader(title: l10n?.privacy ?? 'Privacy'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.shield_rounded,
                          iconColor: AppColors.success,
                          title: l10n?.privacyPolicy ?? 'Privacy Policy',
                          onTap: () {},
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          iconColor: AppColors.textSecondary,
                          title: l10n?.termsOfService ?? 'Terms of Service',
                          onTap: () {},
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          iconColor: AppColors.error,
                          title: l10n?.deleteMyData ?? 'Delete My Data',
                          onTap: () => _showDeleteConfirmation(l10n),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About section
                  _SectionHeader(title: l10n?.about ?? 'About'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.primary,
                          title: l10n?.appVersion ?? 'App Version',
                          subtitle: '1.0.0 (Build 1)',
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.star_outline_rounded,
                          iconColor: AppColors.warning,
                          title: l10n?.rateApp ?? 'Rate App',
                          onTap: () {},
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.share_rounded,
                          iconColor: AppColors.primarySoft,
                          title: l10n?.shareWithFriends ?? 'Share with Friends',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Admin section
                  _SectionHeader(title: l10n?.admin ?? 'Admin'),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: AppColors.error,
                          title: l10n?.adminPanel ?? 'Admin Panel',
                          subtitle: l10n?.appManagement ?? 'App management',
                          onTap: () => Navigator.pushNamed(context, '/admin'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom padding for dock
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(AppLocalizations? l10n) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n?.logoutConfirmTitle ?? 'Logout', style: AppTypography.title2()),
        content: Text(
          l10n?.logoutConfirmMessage ?? 'Are you sure you want to logout from your account?',
          style: AppTypography.body(color: context.colors.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel', style: AppTypography.buttonMedium(color: context.colors.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.authGateway, 
                (route) => false,
              );
            },
            child: Text(l10n?.logout ?? 'Logout', style: AppTypography.buttonMedium(color: AppColors.error)),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(AppLocalizations? l10n) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n?.deleteDataTitle ?? 'Delete Data?', style: AppTypography.title2()),
        content: Text(
          l10n?.deleteDataMessage ?? 'All your data will be permanently deleted. This action cannot be undone.',
          style: AppTypography.body(color: context.colors.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel', style: AppTypography.buttonMedium(color: context.colors.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.authGateway, 
                (route) => false,
              );
            },
            child: Text(l10n?.delete ?? 'Delete', style: AppTypography.buttonMedium(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption1(color: context.colors.textMutedColor),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body(color: context.colors.textColor)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 66),
      color: AppColors.borderSoft,
    );
  }
}

