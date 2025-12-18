import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Profile Screen - User profile and statistics
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  
  void _showEditProfileSheet() {
    HapticFeedback.lightImpact();
    
    final authState = ref.read(authProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EditProfileSheet(
        user: authState.user,
        onSave: (username, bio, gender, location, avatarUrl) async {
          final success = await ref.read(authProvider.notifier).updateProfile(
            username: username,
            bio: bio,
            gender: gender,
            location: location,
            avatarUrl: avatarUrl,
          );
          
          if (mounted) {
            Navigator.pop(context);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)?.profileUpdated ?? 'Profile updated'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update profile'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
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
                color: context.colors.textMutedColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.title2(color: context.colors.textColor)),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTypography.body(color: context.colors.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              text: 'OK',
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
              AppLocalizations.of(context)?.profile ?? 'Profile',
              style: AppTypography.serifTitle(color: context.colors.textColor),
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
                        color: context.colors.textColor.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: isGuest 
                          ? Text(
                              '?', 
                              style: AppTypography.extraLargeTitle(color: context.colors.textColor)
                            )
                          : user?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.avatarUrl!.startsWith('http') 
                                        ? user!.avatarUrl! 
                                        : '${ref.read(apiClientProvider).baseUrl}${user!.avatarUrl}',
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (_, __, ___) => Text(
                                      user!.username.substring(0, 1).toUpperCase(),
                                      style: AppTypography.extraLargeTitle(color: context.colors.textColor),
                                    ),
                                  ),
                                )
                              : Text(
                                  user?.username.substring(0, 1).toUpperCase() ?? 'U',
                                  style: AppTypography.extraLargeTitle(color: context.colors.textColor),
                                ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    isGuest ? (AppLocalizations.of(context)?.guestMode ?? 'Guest') : (user?.username ?? 'User'),
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
                      isGuest ? (AppLocalizations.of(context)?.guestMode ?? 'Guest') : (AppLocalizations.of(context)?.registered ?? 'Registered'),
                      style: AppTypography.caption1(
                        color: isGuest ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bio
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user!.bio!,
                        style: AppTypography.body(color: context.colors.textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Location and Gender
                  if ((user?.location != null && user!.location!.isNotEmpty) || 
                      (user?.gender != null && user!.gender != 'Not specified'))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (user?.location != null && user!.location!.isNotEmpty) ...[
                          Icon(Icons.location_on_rounded, size: 16, color: context.colors.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            user!.location!,
                            style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                          ),
                          if (user?.gender != null && user!.gender != 'Not specified')
                            const SizedBox(width: 16),
                        ],
                        if (user?.gender != null && user!.gender != 'Not specified') ...[
                          Icon(
                            user!.gender == 'Male' ? Icons.male_rounded :
                            user!.gender == 'Female' ? Icons.female_rounded :
                            Icons.person_rounded,
                            size: 16,
                            color: context.colors.textSecondaryColor
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user!.gender!,
                            style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                          ),
                        ],
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Edit profile button
                  SecondaryButton(
                    text: AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
                    icon: Icons.edit_rounded,
                    onPressed: _showEditProfileSheet,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Premium & Wallet Section
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/subscription');
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.diamond_rounded, color: AppColors.warning, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)?.premium ?? 'Premium',
                            style: AppTypography.headline(color: context.colors.textColor),
                          ),
                          Text(
                            AppLocalizations.of(context)?.upgrade ?? 'Upgrade',
                            style: AppTypography.caption1(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/credits');
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${user?.credits ?? 0}',
                            style: AppTypography.headline(color: context.colors.textColor),
                          ),
                          Text(
                            AppLocalizations.of(context)?.buyCredits ?? 'Buy Credits',
                            style: AppTypography.caption1(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            // Statistics
            Text(
              AppLocalizations.of(context)?.statistics ?? 'Statistics',
              style: AppTypography.headline(color: context.colors.textColor),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.chat_rounded,
                    value: '0',
                    label: AppLocalizations.of(context)?.chats ?? 'Chats',
                    onTap: () => _showStatSheet(
                      AppLocalizations.of(context)?.chatCount ?? 'Chat Count',
                      AppLocalizations.of(context)?.chatCountDesc ?? 'Total number of chats you have completed. Each new match counts.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_rounded,
                    value: '0',
                    label: AppLocalizations.of(context)?.totalMinutes ?? 'Minutes',
                    onTap: () => _showStatSheet(
                      AppLocalizations.of(context)?.totalTime ?? 'Total Time',
                      AppLocalizations.of(context)?.totalTimeDesc ?? 'Your total chat time in minutes. Active connections count.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_rounded,
                    value: '0',
                    label: AppLocalizations.of(context)?.meetings ?? 'Meetings',
                    onTap: () => _showStatSheet(
                      AppLocalizations.of(context)?.meetingCount ?? 'Meeting Count',
                      AppLocalizations.of(context)?.meetingCountDesc ?? 'Number of people you have met so far.',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Achievements section
            Text(
              AppLocalizations.of(context)?.achievements ?? 'Achievements',
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
                    AppLocalizations.of(context)?.comingSoon ?? 'Coming Soon',
                    style: AppTypography.headline(color: context.colors.textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.achievementsComingSoon ?? 'We are working on the achievements system',
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

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile? user;
  final Function(String username, String bio, String gender, String location, String? avatarUrl) onSave;
  
  const _EditProfileSheet({
    required this.user,
    required this.onSave,
  });

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  final ImagePicker _picker = ImagePicker();
  String _selectedGender = 'Not specified';
  File? _selectedImage;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _bioController = TextEditingController(text: widget.user?.bio ?? '');
    _locationController = TextEditingController(text: widget.user?.location ?? '');
    
    if (widget.user?.gender != null && widget.user!.gender!.isNotEmpty) {
      if (['Male', 'Female', 'Other'].contains(widget.user!.gender)) {
        _selectedGender = widget.user!.gender!;
      }
    }
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.errorSelectingPhoto ?? "Error selecting photo"}: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textMutedColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text(AppLocalizations.of(context)?.camera ?? 'Camera', style: AppTypography.body(color: context.colors.textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text(AppLocalizations.of(context)?.gallery ?? 'Gallery', style: AppTypography.body(color: context.colors.textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text(AppLocalizations.of(context)?.removePhoto ?? 'Remove Photo', style: AppTypography.body(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedImage = null);
                  },
                ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return GlassContainer(
      borderRadius: 28,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.textMutedColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
                      style: AppTypography.title1(color: context.colors.textColor),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Profile Photo Section
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _selectedImage == null 
                                  ? AppColors.primaryGradient 
                                  : null,
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _selectedImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: context.colors.textColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Text(
                      AppLocalizations.of(context)?.tapToChangePhoto ?? 'Tap photo to change',
                      style: AppTypography.caption1(color: context.colors.textMutedColor),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Username Field
                  _buildStyledTextField(
                    controller: _usernameController,
                    hintText: AppLocalizations.of(context)?.username ?? 'Username',
                    icon: Icons.person_outline_rounded,
                    context: context,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bio Field
                  _buildStyledTextField(
                    controller: _bioController,
                    hintText: AppLocalizations.of(context)?.tellAboutYourself ?? 'Bio',
                    icon: Icons.edit_note_rounded,
                    context: context,
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                   // Location Field
                  _buildStyledTextField(
                    controller: _locationController,
                    hintText: 'Location (City, Country)',
                    icon: Icons.location_on_rounded,
                    context: context,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Gender Dropdown
                  _buildStyledDropdown(context),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  PrimaryButton(
                    text: AppLocalizations.of(context)?.save ?? 'Save',
                    icon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_usernameController.text.isNotEmpty) {
                        setState(() => _isLoading = true);
                        
                        try {
                          String? avatarUrl;
                          
                          // If new image selected, upload it first
                          if (_selectedImage != null) {
                            final api = ref.read(apiClientProvider);
                            // Ensure we use the full URL if backend returns relative path
                            final relativeUrl = await api.uploadAvatar(_selectedImage!);
                            if (relativeUrl.startsWith('http')) {
                              avatarUrl = relativeUrl;
                            } else {
                              // Prepend base URL if relative
                              avatarUrl = relativeUrl; // ApiClient/Backend logic will handle full url construction if needed, 
                              // but here we just pass what backend gave us. 
                              // Ideally backend returns relative path and we store that.
                            }
                          }
                          
                          if (mounted) {
                             // Now call the parent onSave which calls authProvider.updateProfile
                             // We need to pass the avatarUrl to onSave
                             widget.onSave(
                               _usernameController.text.trim(),
                               _bioController.text.trim(),
                               _selectedGender,
                               _locationController.text.trim(),
                               avatarUrl, // We need to update onSave signature to accept avatarUrl
                             );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                            );
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
                    width: double.infinity,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Cancel Button
                  SecondaryButton(
                    text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    width: double.infinity,
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required BuildContext context,
    int maxLines = 1,
  }) {
    return GlassContainer(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTypography.body(color: context.colors.textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body(color: context.colors.textMutedColor),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight,
          icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textSecondaryColor),
          style: AppTypography.body(color: context.colors.textColor),
          items: ['Not specified', 'Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    value == 'Male' ? Icons.male_rounded :
                    value == 'Female' ? Icons.female_rounded :
                    value == 'Other' ? Icons.transgender_rounded :
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedGender = newValue!),
        ),
      ),
    );
  }
}
