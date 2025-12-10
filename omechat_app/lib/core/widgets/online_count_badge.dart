import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Premium Online Count Badge with glass capsule effect
class OnlineCountBadge extends StatelessWidget {
  final int count;
  final bool showPulse;
  final bool compact;
  
  const OnlineCountBadge({
    super.key,
    required this.count,
    this.showPulse = true,
    this.compact = false,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassMedium,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing dot
              if (showPulse)
                _PulsingDot()
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.online,
                  ),
                ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                _formatCount(count),
                style: compact 
                    ? AppTypography.caption1(color: Colors.white)
                    : AppTypography.onlineCount(),
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: AppTypography.caption1(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.online,
            boxShadow: [
              BoxShadow(
                color: AppColors.online.withOpacity(_animation.value * 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Connection Status Badge
class ConnectionStatusBadge extends StatelessWidget {
  final String status;
  final bool isConnected;
  
  const ConnectionStatusBadge({
    super.key,
    required this.status,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected 
            ? AppColors.success.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: isConnected 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: AppTypography.caption1(
              color: isConnected ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
