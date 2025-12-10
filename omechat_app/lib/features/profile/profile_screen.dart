import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../providers/auth_provider.dart';

/// Profile Screen - User profile and statistics
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  
  void _showEditProfileSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EditProfileSheet(
        onSave: (username) async {
          // TODO: Implement profile update via API
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil güncellendi'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
  
  void _showStatSheet(String title, String description) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.title2()),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTypography.body(color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              text: 'Tamam',
              onPressed: () => Navigator.pop(context),
              width: double.infinity,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = !authState.isAuthenticated;
    final user = authState.user;
    
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Profil',
              style: AppTypography.largeTitle(color: context.colors.textColor),
            ),
            
            const SizedBox(height: 32),
            
            // Profile card
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isGuest 
                            ? '?' 
                            : (user?.username.substring(0, 1).toUpperCase() ?? 'U'),
                        style: AppTypography.extraLargeTitle(color: Colors.white),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    isGuest ? 'Misafir' : (user?.username ?? 'Kullanıcı'),
                    style: AppTypography.title2(color: context.colors.textColor),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGuest 
                          ? AppColors.warning.withOpacity(0.2)
                          : AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGuest ? 'Misafir' : 'Kayıtlı Üye',
                      style: AppTypography.caption1(
                        color: isGuest ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Edit profile button
                  SecondaryButton(
                    text: 'Profili Düzenle',
                    icon: Icons.edit_rounded,
                    onPressed: _showEditProfileSheet,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Statistics
            Text(
              'İstatistikler',
              style: AppTypography.headline(color: context.colors.textColor),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.chat_rounded,
                    value: '0',
                    label: 'Sohbet',
                    onTap: () => _showStatSheet(
                      'Sohbet Sayısı',
                      'Toplam gerçekleştirdiğiniz sohbet sayısı. Her yeni eşleşme sayılır.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_rounded,
                    value: '0',
                    label: 'Dakika',
                    onTap: () => _showStatSheet(
                      'Toplam Süre',
                      'Toplam sohbet süreniz dakika cinsinden. Aktif bağlantılar sayılır.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_rounded,
                    value: '0',
                    label: 'Tanışma',
                    onTap: () => _showStatSheet(
                      'Tanışma Sayısı',
                      'Farklı kişilerle gerçekleştirdiğiniz tanışma sayısı.',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Achievements section
            Text(
              'Başarılar',
              style: AppTypography.headline(color: context.colors.textColor),
            ),
            
            const SizedBox(height: 16),
            
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yakında',
                    style: AppTypography.headline(color: context.colors.textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Başarılar sistemi üzerinde çalışıyoruz',
                    style: AppTypography.body(
                      color: context.colors.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
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

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                widget.icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: AppTypography.title1(color: context.colors.textColor),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: AppTypography.caption1(color: context.colors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Function(String) onSave;
  
  const _EditProfileSheet({required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedGender = 'Belirtilmedi';
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Profili Düzenle',
            style: AppTypography.title2(color: context.colors.textColor),
          ),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _usernameController,
            style: AppTypography.body(color: context.colors.textColor),
            decoration: InputDecoration(
              hintText: 'Yeni kullanıcı adı',
              hintStyle: AppTypography.body(color: context.colors.textMutedColor),
              prefixIcon: Icon(Icons.person_outline_rounded, color: context.colors.textSecondaryColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.textMutedColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _bioController,
            style: AppTypography.body(color: context.colors.textColor),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Kendinden bahset...',
              hintStyle: AppTypography.body(color: context.colors.textMutedColor),
              prefixIcon: Icon(Icons.edit_note_rounded, color: context.colors.textSecondaryColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.textMutedColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          // Gender Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.textMutedColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                isExpanded: true,
                dropdownColor: context.colors.surfaceColor,
                icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textSecondaryColor),
                style: AppTypography.body(color: context.colors.textColor),
                items: ['Belirtilmedi', 'Erkek', 'Kadın', 'Diğer'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedGender = newValue!),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          PrimaryButton(
            text: 'Kaydet',
            icon: Icons.check_rounded,
            onPressed: () {
              if (_usernameController.text.isNotEmpty) {
                widget.onSave(_usernameController.text.trim());
              }
            },
            width: double.infinity,
          ),
          
          const SizedBox(height: 12),
          
          SecondaryButton(
            text: 'İptal',
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
