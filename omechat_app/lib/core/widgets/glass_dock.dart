import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

/// iOS/tvOS-style bottom navigation dock with glassmorphism
/// Enhanced with bigger hit areas and hover/active effects
/// Fully theme-aware for light and dark modes
class GlassDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassDockItem> items;
  
  const GlassDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blurControlPanel,
            sigmaY: AppTheme.blurControlPanel,
          ),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              // Theme-aware glass background
              color: isDark 
                  ? AppColors.glassDark 
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
              border: Border.all(
                color: isDark 
                    ? AppColors.glassBorder 
                    : AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: isDark 
                  ? AppShadows.glassDock
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                
                return Expanded(
                  child: _DockItemWidget(
                    item: item,
                    isSelected: isSelected,
                    isDarkMode: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassDockItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  
  const GlassDockItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class _DockItemWidget extends StatefulWidget {
  final GlassDockItem item;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;
  
  const _DockItemWidget({
    required this.item,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_DockItemWidget> createState() => _DockItemWidgetState();
}

class _DockItemWidgetState extends State<_DockItemWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppTheme.curveSharp,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get icon color based on state and theme
  Color _getIconColor() {
    if (widget.isSelected) {
      return AppColors.primary;
    }
    if (_isHovered || _isPressed) {
      return widget.isDarkMode 
          ? AppColors.textPrimary.withOpacity(0.8)
          : AppColors.textPrimaryLight.withOpacity(0.9);
    }
    return widget.isDarkMode 
        ? AppColors.textMuted 
        : AppColors.textMutedLight;
  }

  // Get label color based on state and theme
  Color _getLabelColor() {
    if (widget.isSelected) {
      return AppColors.primary;
    }
    if (_isHovered || _isPressed) {
      return widget.isDarkMode 
          ? AppColors.textSecondary 
          : AppColors.textSecondaryLight;
    }
    return widget.isDarkMode 
        ? AppColors.textMuted 
        : AppColors.textMutedLight;
  }

  @override
  Widget build(BuildContext context) {
    // Radius adjusted to be concentric with navbar (24 - padding ~4 = 20)
    final borderRadius = BorderRadius.circular(20);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _controller.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _controller.reverse();
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          _controller.reverse();
          setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            // Padding moved inside to allow glass background to fill
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: widget.isSelected ? Border.all(
                color: AppColors.primary.withOpacity(widget.isDarkMode ? 0.3 : 0.25),
                width: 1,
              ) : null,
              // No color here, handled inside for glass effect
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                // Only blur when selected to avoid performance hit and visual noise
                filter: ImageFilter.blur(
                  sigmaX: widget.isSelected ? 8.0 : 0.0,
                  sigmaY: widget.isSelected ? 8.0 : 0.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppColors.primary.withOpacity(widget.isDarkMode ? 0.15 : 0.12)
                        : (_isHovered || _isPressed)
                            ? AppColors.primary.withOpacity(widget.isDarkMode ? 0.08 : 0.06)
                            : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with glow
                      AnimatedContainer(
                        duration: AppTheme.durationNormal,
                        curve: AppTheme.curveSpring,
                        transform: Matrix4.identity()
                          ..scale(widget.isSelected ? 1.1 : 1.0),
                        transformAlignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect for selected item
                            if (widget.isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(widget.isDarkMode ? 0.6 : 0.4),
                                      blurRadius: 14,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            Icon(
                              widget.isSelected 
                                  ? (widget.item.activeIcon ?? widget.item.icon)
                                  : widget.item.icon,
                              size: 22,
                              color: _getIconColor(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // Label
                      AnimatedDefaultTextStyle(
                        duration: AppTheme.durationNormal,
                        style: AppTypography.tabLabel(
                          color: _getLabelColor(),
                        ),
                        child: Text(widget.item.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
