import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Custom Floating Glass Navbar using liquid_glass_renderer
/// 
/// PERFORMANCE NOTES (from official pub.dev docs):
/// - LiquidGlass is computationally expensive
/// - Max 16 shapes in LiquidGlassBlendGroup
/// - Keep LiquidGlassLayer area as small as possible
/// - RepaintBoundary helps prevent unnecessary repaints
/// - Moving shapes forces all shapes in group to re-render
class CustomGlassNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavbarItem> items;
  
  const CustomGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<CustomGlassNavbar> createState() => _CustomGlassNavbarState();
}

class _CustomGlassNavbarState extends State<CustomGlassNavbar> {
  
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 16,
      child: RepaintBoundary(
        child: _buildLiquidGlassNavbar(),
      ),
    );
  }
  
  Widget _buildLiquidGlassNavbar() {
    // MANDATORY STRUCTURE per pub.dev docs:
    // LiquidGlassLayer is the REQUIRED parent
    // LiquidGlass with shape inside
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 10,
        // Omechat glass color: subtle white tint (10% opacity)
        glassColor: Color(0x1AFFFFFF),
        lightIntensity: 1.2,
      ),
      child: LiquidGlass(
        // LiquidRoundedSuperellipse for smooth rounded squircle
        shape: const LiquidRoundedSuperellipse(borderRadius: 24),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = index == widget.currentIndex;
              
              return Expanded(
                child: _NavbarItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTap(index);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Navbar item data model
class NavbarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  
  const NavbarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Individual navbar item widget with GlassGlow effect
class _NavbarItemWidget extends StatefulWidget {
  final NavbarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavbarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavbarItemWidget> createState() => _NavbarItemWidgetState();
}

class _NavbarItemWidgetState extends State<_NavbarItemWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15, // Scale up when selected
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.curveSpring,
    ));
    
    // Set initial animation state
    if (widget.isSelected) {
      _scaleController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(_NavbarItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate scale when selection changes
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _scaleController.reverse();
    }
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with GlassGlow for selected state (per docs)
              _buildIcon(),
              const SizedBox(height: 2),
              // Label
              AnimatedDefaultTextStyle(
                duration: AppTheme.durationNormal,
                style: AppTypography.tabLabel(
                  color: widget.isSelected 
                      ? AppColors.primary 
                      : AppColors.textMuted,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIcon() {
    final icon = Icon(
      widget.isSelected 
          ? (widget.item.activeIcon ?? widget.item.icon)
          : widget.item.icon,
      size: 20,
      color: widget.isSelected ? AppColors.primary : AppColors.textMuted,
    );
    
    // MANDATORY: Use GlassGlow for selected items (per pub.dev docs)
    // Using Color.withAlpha instead of deprecated withOpacity
    if (widget.isSelected) {
      return GlassGlow(
        // Purple accent glow per Omechat spec (0.3 opacity = 77 alpha)
        glowColor: Colors.purpleAccent.withAlpha(77),
        glowRadius: 1.0,
        child: icon,
      );
    }
    
    return icon;
  }
}
