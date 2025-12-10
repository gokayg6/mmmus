import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../core/routing/app_router.dart';
import '../../services/storage_service.dart';

/// Premium iOS-style Onboarding Screen
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.chat_bubble_rounded,
      title: 'Anonim Metin Sohbet',
      subtitle: 'Dünyanın dört bir yanından insanlarla anında mesajlaşmaya başla.',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingPageData(
      icon: Icons.shield_rounded,
      title: 'Güvenli & Denetimli',
      subtitle: 'Topluluk kuralları ve moderasyon ile güvenli bir ortam sağlıyoruz.',
      gradient: AppColors.accentGradient,
    ),
    OnboardingPageData(
      icon: Icons.flash_on_rounded,
      title: 'Anında Eşleşme',
      subtitle: 'Gelişmiş eşleştirme sistemimizle saniyeler içinde yeni insanlarla tanış.',
      gradient: AppColors.buttonGradient,
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppTheme.durationMedium,
        curve: AppTheme.curveDefault,
      );
    } else {
      _completeOnboarding();
    }
  }
  
  void _skip() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }
  
  Future<void> _completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingComplete(true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.authGateway);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextLinkButton(
                    text: 'Atla',
                    onPressed: _skip,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),
              
              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: AppTheme.durationNormal,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive 
                            ? AppColors.primary 
                            : Colors.white.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ),
              
              // Next button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: PrimaryButton(
                  text: _currentPage < _pages.length - 1 ? 'Devam' : 'Başla',
                  icon: _currentPage < _pages.length - 1 
                      ? Icons.arrow_forward_rounded 
                      : Icons.play_arrow_rounded,
                  onPressed: _nextPage,
                  width: double.infinity,
                  height: 56,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  
  OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: data.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            data.title,
            style: AppTypography.title1(),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            data.subtitle,
            style: AppTypography.body(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Glass card with feature highlight
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Deneyim',
                        style: AppTypography.subheadlineMedium(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ücretsiz kullanmaya başla',
                        style: AppTypography.footnote(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
