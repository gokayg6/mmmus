import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';

/// Explore Screen - Upcoming features
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  
  void _showComingSoonSheet(BuildContext context, String title, String description) {
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
            
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              title,
              style: AppTypography.title2(),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              description,
              style: AppTypography.body(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Yakında',
                style: AppTypography.subheadlineMedium(
                  color: AppColors.warning,
                ),
              ),
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
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Keşfet',
              style: AppTypography.largeTitle(),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Yeni özellikler yakında',
              style: AppTypography.body(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Coming soon card
            GlassContainer(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Yakında',
                    style: AppTypography.title2(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Yeni keşfet özellikleri üzerinde\nçalışıyoruz. Takipte kalın!',
                    style: AppTypography.body(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // CTAs
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'Premium\'a Geç',
                    icon: Icons.workspace_premium_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/subscription');
                    },
                    width: double.infinity,
                    gradient: AppColors.primaryGradient,
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'Kredi Al',
                    icon: Icons.account_balance_wallet_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/credits');
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Feature preview cards
            Text(
              'Yakında Gelecekler',
              style: AppTypography.headline(),
            ),
            
            const SizedBox(height: 16),
            
            _ComingSoonCard(
              icon: Icons.interests_rounded,
              title: 'İlgi Alanları',
              description: 'Ortak ilgi alanlarına göre eşleş',
              onTap: () => _showComingSoonSheet(
                context,
                'İlgi Alanları',
                'Müzik, spor, oyun gibi ilgi alanlarınızı seçin ve benzer ilgi alanlarına sahip insanlarla eşleşin.',
              ),
            ),
            
            const SizedBox(height: 12),
            
            _ComingSoonCard(
              icon: Icons.filter_list_rounded,
              title: 'Gelişmiş Filtreler',
              description: 'Yaş ve konum bazlı filtreleme',
              onTap: () => _showComingSoonSheet(
                context,
                'Gelişmiş Filtreler',
                'Yaş aralığı, konum ve dil tercihlerine göre eşleşme filtrelerinizi özelleştirin.',
              ),
            ),
            
            const SizedBox(height: 12),
            
            _ComingSoonCard(
              icon: Icons.star_rounded,
              title: 'Premium Üyelik',
              description: 'Özel özellikler ve öncelikli eşleşme',
              onTap: () => _showComingSoonSheet(
                context,
                'Premium Üyelik',
                'Reklamsız deneyim, öncelikli eşleşme, özel filtreler ve daha fazlası için Premium üyelik.',
              ),
            ),
            
            const SizedBox(height: 12),
            
            _ComingSoonCard(
              icon: Icons.translate_rounded,
              title: 'Anlık Çeviri',
              description: 'Farklı dillerde sohbet',
              onTap: () => _showComingSoonSheet(
                context,
                'Anlık Çeviri',
                'Farklı dillerdeki insanlarla anlık çeviri özelliği sayesinde sorunsuz iletişim kurun.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<_ComingSoonCard> {
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
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.primary,
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
                      style: AppTypography.subheadlineMedium(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: AppTypography.footnote(),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
