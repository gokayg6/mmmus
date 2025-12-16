import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../domain/models/points_models.dart';
import '../../data/repositories/points_repository.dart';
import '../../providers/data_providers.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Points Screen - Real gamification with PointsRepository
class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsControllerProvider);
    final availableActions = ref.watch(availableActionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                AppLocalizations.of(context)?.credits ?? 'My Credits',
                style: AppTypography.largeTitle(color: context.colors.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Earn points by chatting!',
                style: AppTypography.body(color: context.colors.textSecondaryColor),
              ),
              
              const SizedBox(height: 24),
              
              // Points card
              pointsAsync.when(
                loading: () => _buildLoadingCard(context),
                error: (_, __) => _buildErrorCard(context),
                data: (points) => _PointsCard(points: points),
              ),
              
              const SizedBox(height: 32),
              
              // How to earn
              Text(
                'How to Earn Points?',
                style: AppTypography.title2(color: context.colors.textColor),
              ),
              const SizedBox(height: 16),
              
              ...availableActions.map((action) => _ActionCard(action: action)),
              
              const SizedBox(height: 32),
              
              // Recent activity
              Text(
                'Recent Activity',
                style: AppTypography.title2(color: context.colors.textColor),
              ),
              const SizedBox(height: 16),
              
              pointsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (points) => _RecentActivityList(actions: points.recentActions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.textMutedColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 24,
            decoration: BoxDecoration(
              color: context.colors.textMutedColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Failed to load',
          style: AppTypography.body(color: context.colors.textMutedColor),
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final UserPoints points;
  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated points display
          _AnimatedPointsDisplay(points: points.totalPoints),
          
          const SizedBox(height: 16),
          
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              'Level ${points.level}',
              style: AppTypography.headline(color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress to next level
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To next level',
                    style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                  ),
                  Text(
                    '${points.pointsToNextLevel} points',
                    style: AppTypography.caption1(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: points.progressToNextLevel.clamp(0.0, 1.0),
                  backgroundColor: context.colors.textMutedColor.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedPointsDisplay extends StatefulWidget {
  final int points;
  const _AnimatedPointsDisplay({required this.points});

  @override
  State<_AnimatedPointsDisplay> createState() => _AnimatedPointsDisplayState();
}

class _AnimatedPointsDisplayState extends State<_AnimatedPointsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPointsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Column(
        children: [
          // Glowing points icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.points}',
            style: AppTypography.extraLargeTitle(color: context.colors.textColor),
          ),
          Text(
            'Total Points',
            style: AppTypography.caption1(color: context.colors.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final PointsActionInfo action;
  const _ActionCard({required this.action});

  IconData _getIcon() {
    switch (action.iconName) {
      case 'chat_bubble': return Icons.chat_bubble_rounded;
      case 'play_arrow': return Icons.play_arrow_rounded;
      case 'check_circle': return Icons.check_circle_rounded;
      case 'today': return Icons.today_rounded;
      case 'person': return Icons.person_rounded;
      case 'timer': return Icons.timer_rounded;
      case 'people': return Icons.people_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            
            // Description
            Expanded(
              child: Text(
                action.description,
                style: AppTypography.body(color: context.colors.textColor),
              ),
            ),
            
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+${action.points}',
                style: AppTypography.headline(color: AppColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<PointsAction> actions;
  const _RecentActivityList({required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: context.colors.textMutedColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No activity yet',
                style: AppTypography.body(color: context.colors.textMutedColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Start chatting to earn points!',
                style: AppTypography.caption1(color: context.colors.textMutedColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: actions.map((action) => _RecentActionTile(action: action)).toList(),
    );
  }
}

class _RecentActionTile extends StatelessWidget {
  final PointsAction action;
  const _RecentActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.description ?? PointsConfig.getActionDescription(action.type),
                style: AppTypography.body(color: context.colors.textColor),
              ),
            ),
            Text(
              '+${action.points}',
              style: AppTypography.headline(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}
