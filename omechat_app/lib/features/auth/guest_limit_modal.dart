import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';

/// Modal shown when guest user reaches usage limits
class GuestLimitModal extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback? onDismiss;
  final String title;
  final String message;

  const GuestLimitModal({
    super.key,
    required this.onRegister,
    required this.onLogin,
    this.onDismiss,
    this.title = 'Limite Ulaştın!',
    this.message = 'Misafir olarak daha fazla işlem yapamazsın. Tüm özelliklere erişmek için hesap oluştur.',
  });

  /// Show the modal as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRegister,
    required VoidCallback onLogin,
  }) {
    HapticFeedback.heavyImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (context) => GuestLimitModal(
        onRegister: onRegister,
        onLogin: onLogin,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textMutedColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              
              // Lock icon with glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                title,
                style: AppTypography.title1(color: context.colors.textColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                style: AppTypography.body(color: context.colors.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Benefits list
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _BenefitRow(
                      icon: Icons.all_inclusive_rounded,
                      text: 'Sınırsız sohbet',
                    ),
                    const SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.person_rounded,
                      text: 'Profil özelleştirme',
                    ),
                    const SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.stars_rounded,
                      text: 'Puan ve seviye sistemi',
                    ),
                    const SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.history_rounded,
                      text: 'Sohbet geçmişi',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register button
              PrimaryButton(
                text: 'Hesap Oluştur',
                icon: Icons.person_add_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onRegister();
                },
                width: double.infinity,
              ),
              
              const SizedBox(height: 12),
              
              // Login button
              SecondaryButton(
                text: 'Zaten hesabım var',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onLogin();
                },
                width: double.infinity,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.success,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTypography.body(color: context.colors.textColor),
        ),
        const Spacer(),
        Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        ),
      ],
    );
  }
}

/// Helper widget to wrap actions that may be limited for guests
class GuestGuard extends StatelessWidget {
  final Widget child;
  final bool isGuest;
  final bool hasReachedLimit;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const GuestGuard({
    super.key,
    required this.child,
    required this.isGuest,
    required this.hasReachedLimit,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest && hasReachedLimit) {
      return GestureDetector(
        onTap: () => GuestLimitModal.show(
          context,
          onRegister: onRegister,
          onLogin: onLogin,
        ),
        child: AbsorbPointer(
          child: Opacity(
            opacity: 0.5,
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}
