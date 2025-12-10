import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../core/routing/app_router.dart';

/// Premium Permissions Screen
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppTheme.durationSlow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
    ));
    
    _controller.forward();
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    
    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _micGranted = micStatus.isGranted;
    });
    
    if (_cameraGranted && _micGranted) {
      _navigateToMatchmaking();
    }
  }
  
  Future<void> _requestPermissions() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    
    try {
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _micGranted = micStatus.isGranted;
      });
      
      if (_cameraGranted && _micGranted) {
        HapticFeedback.mediumImpact();
        _navigateToMatchmaking();
      } else {
        HapticFeedback.heavyImpact();
        _showPermissionDeniedDialog();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _navigateToMatchmaking() {
    Navigator.pushReplacementNamed(context, AppRoutes.matchmaking);
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'İzin Gerekli',
          style: AppTypography.title3(),
        ),
        content: Text(
          'Video sohbet için kamera ve mikrofon izni gereklidir. Lütfen ayarlardan izin verin.',
          style: AppTypography.body(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: AppTypography.buttonMedium(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Ayarlara Git',
              style: AppTypography.buttonMedium(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Spacer(),
                    
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'İzinler Gerekli',
                      style: AppTypography.title1(),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Video sohbet için aşağıdaki izinlere\nihtiyacımız var',
                      style: AppTypography.body(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Permission cards
                    _PermissionCard(
                      icon: Icons.videocam_rounded,
                      title: 'Kamera Erişimi',
                      description: 'Video görüşmesi için kameranıza erişim',
                      isGranted: _cameraGranted,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _PermissionCard(
                      icon: Icons.mic_rounded,
                      title: 'Mikrofon Erişimi',
                      description: 'Sesli iletişim için mikrofon erişimi',
                      isGranted: _micGranted,
                    ),
                    
                    const Spacer(),
                    
                    // Buttons
                    PrimaryButton(
                      text: 'İzin Ver',
                      icon: Icons.check_rounded,
                      onPressed: _isLoading ? null : _requestPermissions,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SecondaryButton(
                      text: 'Geri Dön',
                      onPressed: () => Navigator.pop(context),
                      width: double.infinity,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppTheme.durationNormal,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedSwitcher(
              duration: AppTheme.durationNormal,
              child: Icon(
                isGranted ? Icons.check_rounded : icon,
                key: ValueKey(isGranted),
                color: isGranted ? AppColors.success : AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline(),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.footnote(),
                ),
              ],
            ),
          ),
          if (isGranted)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
