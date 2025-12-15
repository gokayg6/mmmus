import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../services/friend_service.dart';

class FriendRequestsModal extends ConsumerWidget {
  const FriendRequestsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendService = ref.watch(friendServiceProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Arkadaş İstekleri',
                  style: AppTypography.headline(color: context.colors.textColor),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: context.colors.textMutedColor),
                ),
              ],
            ),
          ),
          
          Flexible(
            child: FutureBuilder(
              future: friendService.getIncomingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.error != null) {
                  return Center(
                    child: Text(
                      'Hata oluştu',
                      style: AppTypography.body(color: Colors.red),
                    ),
                  );
                }
                
                final requests = snapshot.data as List<dynamic>? ?? [];
                
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read_rounded,
                          size: 64,
                          color: context.colors.textMutedColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bekleyen istek yok',
                          style: AppTypography.body(color: context.colors.textMutedColor),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final friend = req.friend;
                    
                    return GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: AppTheme.radiusMedium,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              friend.username[0].toUpperCase(),
                              style: AppTypography.headline(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              friend.username,
                              style: AppTypography.subheadline(color: context.colors.textColor),
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.check_rounded,
                            color: Colors.green,
                            onTap: () async {
                              try {
                                await friendService.acceptRequest(req.id);
                                if (context.mounted) {
                                  Navigator.pop(context); // Refresh parent/close modal
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Arkadaşlık isteği kabul edildi!')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.close_rounded,
                            color: Colors.red,
                            onTap: () {
                              // Reject logic implementation (not yet in core backend but we can just ignore or add reject endpoint)
                              // For now just pop
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
