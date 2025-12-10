import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glowing_button.dart';
import '../../core/widgets/glass_container.dart';
import '../video_chat/video_chat_screen.dart';

/// Random Connect Screen - Entry point for Omegle-style matching
/// Tapping "Start" opens the Video Chat screen
class RandomConnectScreen extends StatefulWidget {
  const RandomConnectScreen({super.key});

  @override
  State<RandomConnectScreen> createState() => _RandomConnectScreenState();
}

class _RandomConnectScreenState extends State<RandomConnectScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late Animation<double> _bgAnimation;
  late Animation<double> _pulseAnimation;
  
  // Filter states
  String _selectedGender = 'Herkes';
  
  final int _onlineCount = 2847;

  @override
  void initState() {
    super.initState();
    
    // Background gradient animation
    _bgController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    
    // Pulse animation for start button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startVideoChat() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const VideoChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background gradient
          _buildAnimatedBackground(),
          
          // Orange radial glow
          _buildRadialGlow(),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Gender filter
                _buildGenderFilter(),
                
                const Spacer(),
                
                // Main start button
                _buildStartButton(),
                
                const Spacer(),
                
                // Features and tips
                _buildFeatures(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.backgroundColor,
                Color.lerp(
                  context.colors.backgroundColor,
                  context.isDarkMode ? const Color(0xFF1A0A04) : const Color(0xFFFFF0E6),
                  _bgAnimation.value * 0.3,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadialGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15 + _bgAnimation.value * 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keşfet', 
                style: AppTypography.largeTitle(color: context.colors.textColor)
              ),
              const SizedBox(height: 4),
              Text(
                'Yeni insanlarla tanış',
                style: AppTypography.footnote(color: context.colors.textSecondaryColor),
              ),
            ],
          ),
          const Spacer(),
          _OnlineCountBadge(count: _onlineCount),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    final options = ['Herkes', 'Kadın', 'Erkek'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: options.map((option) {
            final isSelected = _selectedGender == option;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedGender = option);
                },
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.button : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: AppTypography.subheadlineMedium(
                        color: isSelected ? Colors.white : context.colors.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing start button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: GlowingButton(
            size: 160,
            showPulse: true,
            onPressed: _startVideoChat,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 50,
                ),
                const SizedBox(height: 4),
                Text(
                  'BAŞLAT',
                  style: AppTypography.caption1(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        Text(
          'Görüntülü Sohbet', 
          style: AppTypography.title2(color: context.colors.textColor)
        ),
        const SizedBox(height: 8),
        Text(
          'Rastgele biriyle eşleş ve sohbet et',
          style: AppTypography.body(color: context.colors.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FeatureChip(icon: Icons.videocam_rounded, label: 'Video'),
              const SizedBox(width: 12),
              _FeatureChip(icon: Icons.chat_bubble_rounded, label: 'Sohbet'),
              const SizedBox(width: 12),
              _FeatureChip(icon: Icons.security_rounded, label: 'Anonim'),
            ],
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İpucu', style: AppTypography.caption1(color: AppColors.warning)),
                      Text(
                        'Kamera ve mikrofon izni verdiğinizden emin olun',
                        style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bağlanarak topluluk kurallarını kabul etmiş olursunuz',
            style: AppTypography.caption1(color: context.colors.textMutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnlineCountBadge extends StatelessWidget {
  final int count;
  const _OnlineCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.online.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.online.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.online.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count online',
            style: AppTypography.caption1(color: AppColors.online),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.caption1(color: context.colors.textSecondaryColor)),
        ],
      ),
    );
  }
}
