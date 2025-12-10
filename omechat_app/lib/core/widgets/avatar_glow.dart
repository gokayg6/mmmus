import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_theme.dart';

/// Avatar with Animated Glow Ring
/// Features pulsing orange glow and optional online indicator
class AvatarGlow extends StatefulWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool isOnline;
  final bool showGlow;
  final bool animateGlow;
  final VoidCallback? onTap;
  final Widget? badge;
  
  const AvatarGlow({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 60,
    this.isOnline = false,
    this.showGlow = true,
    this.animateGlow = true,
    this.onTap,
    this.badge,
  });

  @override
  State<AvatarGlow> createState() => _AvatarGlowState();
}

class _AvatarGlowState extends State<AvatarGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    if (widget.showGlow && widget.animateGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowOpacity = widget.animateGlow 
              ? _glowAnimation.value 
              : 0.6;
          
          return Container(
            width: widget.size + 16,
            height: widget.size + 16,
            decoration: widget.showGlow ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(glowOpacity * 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ) : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gradient ring
                if (widget.showGlow)
                  Container(
                    width: widget.size + 8,
                    height: widget.size + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primary.withOpacity(glowOpacity),
                          AppColors.primarySoft.withOpacity(glowOpacity),
                          AppColors.primary.withOpacity(glowOpacity),
                          AppColors.primaryDark.withOpacity(glowOpacity),
                          AppColors.primary.withOpacity(glowOpacity),
                        ],
                      ),
                    ),
                  ),
                
                // Inner container (masks gradient ring)
                Container(
                  width: widget.size + 4,
                  height: widget.size + 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                ),
                
                // Avatar
                _buildAvatar(),
                
                // Online indicator
                if (widget.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: widget.size * 0.25,
                      height: widget.size * 0.25,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.online.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Custom badge
                if (widget.badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: widget.badge!,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // Initials avatar
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.button,
      ),
      child: Center(
        child: Text(
          widget.initials ?? '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Small Avatar without glow (for lists)
class SmallAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool isOnline;
  
  const SmallAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 44,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imageUrl == null ? AppGradients.button : null,
            image: imageUrl != null ? DecorationImage(
              image: NetworkImage(imageUrl!),
              fit: BoxFit.cover,
            ) : null,
            border: Border.all(
              color: AppColors.borderOrange,
              width: 1.5,
            ),
          ),
          child: imageUrl == null ? Center(
            child: Text(
              initials ?? '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ) : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
