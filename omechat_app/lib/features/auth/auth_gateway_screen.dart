import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';

/// Premium Auth Gateway Screen with 3 glassmorphism cards
class AuthGatewayScreen extends ConsumerStatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  ConsumerState<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends ConsumerState<AuthGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _blobController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _blobController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _blobController.dispose();
    super.dispose();
  }
  
  void _navigateToRegister() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.register);
  }
  
  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.login);
  }
  
  Future<void> _continueAsGuest() async {
    HapticFeedback.mediumImpact();
    // Guest mode - skip auth and go directly to main app
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated gradient blobs
          ..._buildAnimatedBlobs(),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Dünyayla Tanışmaya\nHazır mısın?',
                      style: AppTypography.largeTitle(),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      'Anonim görüntülü sohbet,\niOS kalitesinde deneyim.',
                      style: AppTypography.body(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Auth option cards
                    _AuthOptionCard(
                      icon: Icons.person_add_rounded,
                      title: 'Kayıt Ol',
                      subtitle: 'Profil oluştur, istatistiklerini kaydet.',
                      gradient: AppColors.primaryGradient,
                      isPrimary: true,
                      onTap: _navigateToRegister,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _AuthOptionCard(
                      icon: Icons.login_rounded,
                      title: 'Giriş Yap',
                      subtitle: 'Mevcut hesabınla devam et.',
                      onTap: _navigateToLogin,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _AuthOptionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Misafir Olarak Devam Et',
                      subtitle: 'Hesap oluşturmadan hızlıca bağlan.',
                      onTap: _continueAsGuest,
                    ),
                    
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildAnimatedBlobs() {
    return [
      // Top-left blob - Orange glow
      AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) {
          final offset = math.sin(_blobController.value * 2 * math.pi) * 30;
          return Positioned(
            top: -100 + offset,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      
      // Bottom-right blob - Darker orange glow
      AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) {
          final offset = math.cos(_blobController.value * 2 * math.pi) * 40;
          return Positioned(
            bottom: -150 + offset,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryDark.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      
      // Center blob - Soft orange glow
      AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) {
          final offset = math.sin(_blobController.value * 2 * math.pi + 1) * 20;
          return Positioned(
            top: 200 + offset,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primarySoft.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}

class _AuthOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Gradient? gradient;
  final bool isPrimary;
  
  const _AuthOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
    this.isPrimary = false,
  });

  @override
  State<_AuthOptionCard> createState() => _AuthOptionCardState();
}

class _AuthOptionCardState extends State<_AuthOptionCard> {
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
        scale: _isPressed ? 0.97 : 1.0,
        duration: AppTheme.durationFast,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? widget.gradient : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: widget.isPrimary ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ] : null,
          ),
          child: widget.isPrimary
              ? _buildContent()
              : GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(),
                ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return Container(
      padding: widget.isPrimary ? const EdgeInsets.all(20) : EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.icon,
              color: widget.isPrimary ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.headline(),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: AppTypography.footnote(),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
}
