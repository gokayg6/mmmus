import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glowing_button.dart';

/// Subscription Screen - Premium plans
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedPlan = 1; // 0: weekly, 1: monthly, 2: yearly

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated glow background
          Positioned(
            top: -100,
            left: -50,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2 + _animController.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Premium badge
                  _buildPremiumBadge(),
                  
                  const SizedBox(height: 32),
                  
                  // Features
                  _buildFeaturesList(),
                  
                  const SizedBox(height: 32),
                  
                  // Plans
                  _buildPlanSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Subscribe button
                  GlowingButton.rectangle(
                    onPressed: _subscribe,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Premium\'a Geç',
                          style: AppTypography.buttonLarge(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Restore purchases
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Restore purchases
                    },
                    child: Text(
                      'Satın Alımları Geri Yükle',
                      style: AppTypography.footnote(color: AppColors.textSecondary),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Terms
                  Text(
                    'Abonelik otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
                    style: AppTypography.caption2(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text('Premium', style: AppTypography.largeTitle()),
        const SizedBox(height: 4),
        Text(
          'Sınırsız deneyimin kilidini aç',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPremiumBadge() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _animController.value * 0.03,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.button,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _FeatureItem(Icons.block_rounded, 'Reklamsız Deneyim', 'Hiç reklam görme'),
      _FeatureItem(Icons.bolt_rounded, 'Öncelikli Eşleşme', 'Daha hızlı eşleş'),
      _FeatureItem(Icons.filter_alt_rounded, 'Gelişmiş Filtreler', 'Cinsiyet, ülke, dil'),
      _FeatureItem(Icons.visibility_off_rounded, 'Gizli Mod', 'Görünmez ol'),
      _FeatureItem(Icons.verified_rounded, 'Premium Rozet', 'Profilinde göster'),
      _FeatureItem(Icons.support_agent_rounded, 'Öncelikli Destek', '7/24 destek'),
    ];
    
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREMIUM ÖZELLİKLER',
            style: AppTypography.caption1(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, style: AppTypography.headline()),
                      Text(f.subtitle, style: AppTypography.caption1(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PLAN SEÇ',
            style: AppTypography.caption1(color: AppColors.textMuted),
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildPlanCard(0, 'Haftalık', '₺29.99', '/hafta')),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanCard(1, 'Aylık', '₺79.99', '/ay', isBestValue: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanCard(2, 'Yıllık', '₺499', '/yıl', savings: '%50')),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(int index, String title, String price, String period, 
      {bool isBestValue = false, String? savings}) {
    final isSelected = _selectedPlan == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPlan = index);
      },
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderSoft,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Column(
          children: [
            if (isBestValue || savings != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBestValue ? 'EN İYİ' : savings!,
                  style: AppTypography.caption2(
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              )
            else
              const SizedBox(height: 22),
            Text(
              title,
              style: AppTypography.caption1(
                color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: AppTypography.title2().copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              period,
              style: AppTypography.caption2(
                color: isSelected ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe() {
    HapticFeedback.mediumImpact();
    // TODO: Implement in-app purchase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Premium', style: AppTypography.title2()),
        content: Text(
          'Satın alma özelliği yakında eklenecek!',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: AppTypography.buttonMedium(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  
  _FeatureItem(this.icon, this.title, this.subtitle);
}
