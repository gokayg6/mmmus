import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/avatar_glow.dart';
import '../../models/call.dart';
import '../../mock/mock_data.dart';

/// Calls Screen
/// Recent calls list with call type icons
class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final List<Call> _calls = MockData.calls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Calls',
                    style: AppTypography.largeTitle(),
                  ),
                  const Spacer(),
                  // New call button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_call,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabButton(label: 'All', isActive: true, onTap: () {}),
                  const SizedBox(width: 8),
                  _TabButton(label: 'Missed', isActive: false, onTap: () {}),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Calls list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _calls.length,
                itemBuilder: (context, index) {
                  final call = _calls[index];
                  return _CallTile(call: call);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Call Tile Widget
class _CallTile extends StatelessWidget {
  final Call call;
  
  const _CallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: AppTheme.radiusMedium,
        child: Row(
          children: [
            // Avatar
            SmallAvatar(
              initials: call.user.initials,
              imageUrl: call.user.avatarUrl,
              size: 48,
            ),
            
            const SizedBox(width: 14),
            
            // Name and call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.user.name,
                    style: AppTypography.headline(
                      color: call.isMissed 
                          ? AppColors.error 
                          : AppColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Direction icon
                      Icon(
                        call.direction == CallDirection.incoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        color: call.isMissed 
                            ? AppColors.error 
                            : AppColors.textSecondaryDark,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      // Type icon
                      Icon(
                        call.type == CallType.video
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        color: AppColors.textSecondaryDark,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(call.timestamp),
                        style: AppTypography.caption1(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      if (call.duration != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          call.formattedDuration,
                          style: AppTypography.caption1(
                            color: AppColors.textTertiaryDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Call button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  call.type == CallType.video
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Tab Button Widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: AppTypography.subheadlineMedium(
            color: isActive ? Colors.white : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}
