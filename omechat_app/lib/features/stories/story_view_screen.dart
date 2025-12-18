import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';

class StoryViewScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  const StoryViewScreen({Key? key, required this.story}) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward().whenComplete(() {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _progressController.stop(),
        onTapUp: (_) => _progressController.forward(),
        onTap: () => Navigator.pop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Image
            Image.network(
              widget.story['imageUrl'],
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              },
              errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[900]),
            ),
            
            // Text Overlay (Gradient)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            
            // Header (Progress + User)
            SafeArea(
              child: Column(
                children: [
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        );
                      },
                    ),
                  ),
                  
                  // User Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(widget.story['avatar']),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.story['username'],
                          style: AppTypography.subheadline(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '12h',
                          style: AppTypography.caption1(color: Colors.white70),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Reply Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                       Expanded(
                         child: GlassContainer(
                           height: 48,
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           borderRadius: 24,
                           backgroundColor: Colors.white10,
                           borderColor: Colors.white24,
                           child: Align(
                             alignment: Alignment.centerLeft,
                             child: Text(
                               'Reply...',
                               style: AppTypography.body(color: Colors.white70),
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(width: 12),
                       CircleAvatar(
                         backgroundColor: Colors.transparent,
                         child: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                       ),
                       const SizedBox(width: 12),
                       CircleAvatar(
                         backgroundColor: Colors.transparent,
                         child: const Icon(Icons.send, color: Colors.white, size: 28),
                       ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
