import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glowing_button.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Subscription Screen - Premium plans
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedPlan = 1; // 0: weekly, 1: monthly, 2: 3-month, 3: yearly

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Premium badge
                  _buildPremiumBadge(),
                  
                  const SizedBox(height: 24),
                  
                  // Features
                  _buildFeaturesList(),
                  
                  const SizedBox(height: 24),
                  
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
                          AppLocalizations.of(context)?.goPremium ?? 'Premium\'a Geç',
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
                      AppLocalizations.of(context)?.restorePurchases ?? 'Satın Alımları Geri Yükle',
                      style: AppTypography.footnote(color: AppColors.textSecondary),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Terms
                  Text(
                    AppLocalizations.of(context)?.subscriptionAutoRenews ?? 'Abonelik otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
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
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.button.createShader(bounds),
          child: Text(
            'Premium',
            style: AppTypography.largeTitle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)?.unlockUnlimited ?? 'Sınırsız deneyimin kilidini aç',
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
        width: 100,
        height: 100,
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
          size: 50,
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _FeatureItem(Icons.block_rounded, AppLocalizations.of(context)?.adFree ?? 'Reklamsız Kullanım', AppLocalizations.of(context)?.noAdsDesc ?? 'Hiç reklam görme'),
      _FeatureItem(Icons.wc_rounded, AppLocalizations.of(context)?.genderSelect ?? 'Cinsiyet Seçme', AppLocalizations.of(context)?.freeGenderFilter ?? 'Ücretsiz cinsiyet filtresi'),
      _FeatureItem(Icons.public_rounded, AppLocalizations.of(context)?.countrySelect ?? 'Ülke Seçme', AppLocalizations.of(context)?.selectAnyCountry ?? 'İstediğin ülkeyi seç'),
      _FeatureItem(Icons.hd_rounded, AppLocalizations.of(context)?.hdVideo ?? 'HD Görüntü', AppLocalizations.of(context)?.highQualityVideo ?? 'Yüksek kalite video'),
      _FeatureItem(Icons.star_rounded, AppLocalizations.of(context)?.highlighted ?? 'Öne Çıkarılma', AppLocalizations.of(context)?.priorityInMatching ?? 'Eşleşmede öncelik'),
      _FeatureItem(Icons.verified_rounded, AppLocalizations.of(context)?.vipBadge ?? 'VIP Rozet', AppLocalizations.of(context)?.weeklyVipBadge ?? 'Haftalık özel rozet'),
      _FeatureItem(Icons.replay_rounded, AppLocalizations.of(context)?.unlimitedReconnect ?? 'Sınırsız Reconnect', AppLocalizations.of(context)?.reconnectSamePerson ?? 'Aynı kişiyle tekrar bağlan'),
      _FeatureItem(Icons.palette_rounded, AppLocalizations.of(context)?.customTheme ?? 'Özel Tema', AppLocalizations.of(context)?.nightModeTheme ?? 'Gece modu özel teması'),
      _FeatureItem(Icons.speed_rounded, AppLocalizations.of(context)?.unlimitedNext ?? 'Sınırsız Next', AppLocalizations.of(context)?.noWaitTime ?? 'Bekleme süresi yok'),
    ];
    
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.premiumFeatures ?? 'PREMIUM ÖZELLİKLER',
                style: AppTypography.caption1(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(f.icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, style: AppTypography.subheadlineMedium()),
                      Text(f.subtitle, style: AppTypography.caption2(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
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
            AppLocalizations.of(context)?.selectPlan ?? 'PLAN SEÇ',
            style: AppTypography.caption1(color: AppColors.textMuted),
          ),
        ),
        // First row - Weekly & Monthly
        Row(
          children: [
            Expanded(child: _buildPlanCard(0, AppLocalizations.of(context)?.weekly ?? 'Haftalık', '₺69,99', AppLocalizations.of(context)?.perWeek ?? '/hafta')),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanCard(1, AppLocalizations.of(context)?.monthly ?? 'Aylık', '₺129,99', AppLocalizations.of(context)?.perMonth ?? '/ay', isBestValue: true)),
          ],
        ),
        const SizedBox(height: 8),
        // Second row - 3 Month & Yearly
        Row(
          children: [
            Expanded(child: _buildPlanCard(2, AppLocalizations.of(context)?.threeMonths ?? '3 Aylık', '₺229,99', AppLocalizations.of(context)?.perThreeMonths ?? '/3 ay', savings: '%40')),
            const SizedBox(width: 8),
            Expanded(child: _buildPlanCard(3, AppLocalizations.of(context)?.yearly ?? 'Yıllık', '₺599,99', AppLocalizations.of(context)?.perYear ?? '/yıl', savings: '%60')),
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
        padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBestValue ? (AppLocalizations.of(context)?.bestValue ?? 'EN İYİ') : savings!,
                  style: AppTypography.caption2(
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              )
            else
              const SizedBox(height: 24),
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
    final plans = ['Haftalık - ₺69,99', 'Aylık - ₺129,99', '3 Aylık - ₺229,99', 'Yıllık - ₺599,99'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Premium', style: AppTypography.title2()),
          ],
        ),
        content: Text(
          '${plans[_selectedPlan]} planı seçtiniz.\n\nSatın alma özelliği yakında eklenecek!',
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
