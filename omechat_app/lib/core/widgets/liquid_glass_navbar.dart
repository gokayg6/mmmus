import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// iOS 26-style Liquid Glass Navigation Bar
/// 
/// TWO-LAYER ARCHITECTURE (MANDATORY):
/// Layer 1: Static base glass (passive container)
/// Layer 2: Active liquid blob (interactive, moves and deforms)
/// 
/// The blob MUST feel alive with:
/// - Horizontal movement during tab changes
/// - Squash & stretch deformation
/// - Elastic drag interaction
/// - Viscous fluid physics
class LiquidGlassNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavbarItem> items;
  
  const LiquidGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavbar> createState() => _LiquidGlassNavbarState();
}

class _LiquidGlassNavbarState extends State<LiquidGlassNavbar> 
    with TickerProviderStateMixin {
  
  // Blob position and animation state
  late AnimationController _moveController;
  late AnimationController _shimmerController;
  late AnimationController _navbarScaleController;
  late AnimationController _glowController;
  late Animation<double> _moveAnimation;
  late Animation<double> _navbarScaleAnimation;
  late Animation<double> _glowAnimation;
  
  double _blobCenterX = 0.0;
  double _targetBlobX = 0.0;
  double _dragOffset = 0.0;
  double _stretchFactor = 1.0;
  double _blobScaleFactor = 1.0; // New: blob scale during transition
  bool _isDragging = false;
  
  // Blob dimensions (iOS 26 accurate proportions)
  static const double _blobBaseWidth = 70.0;  // 64-76px range
  static const double _blobBaseHeight = 45.0; // 42-48px range
  static const double _navbarHeight = 56.0;
  
  // Movement velocity for glow intensity
  double _movementVelocity = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Movement animation controller (tab change)
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    
    // Shimmer animation (light refraction during movement)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Navbar scale animation (tap feedback)
    _navbarScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _navbarScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02, // Very subtle scale (2%)
    ).animate(CurvedAnimation(
      parent: _navbarScaleController,
      curve: Curves.easeOut,
    ));
    
    // White glow animation (during tab change)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));
    
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutExpo, // iOS 26-style exponential ease
    );
    
    // Listen for animation updates
    _moveController.addListener(_updateStretchFactor);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize blob position on first build when context is available
    if (_blobCenterX == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _blobCenterX = _calculateBlobX(widget.currentIndex);
            _targetBlobX = _blobCenterX;
          });
        }
      });
    }
  }
  
  @override
  void didUpdateWidget(LiquidGlassNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateBlobToTab(widget.currentIndex);
    }
  }
  
  @override
  void dispose() {
    _moveController.dispose();
    _shimmerController.dispose();
    _navbarScaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  /// Calculate blob X position for given tab index
  double _calculateBlobX(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navbarWidth = screenWidth - 32; // 16px padding on each side
    final iconLayerPadding = 6.0; // Horizontal padding from icon layer
    final effectiveWidth = navbarWidth - (iconLayerPadding * 2);
    final itemWidth = effectiveWidth / widget.items.length;
    // Center of each item, accounting for icon layer padding
    return iconLayerPadding + (index * itemWidth) + (itemWidth / 2);
  }
  
  /// Animate blob to target tab with squash & stretch
  void _animateBlobToTab(int targetIndex) {
    final endX = _calculateBlobX(targetIndex);
    
    _targetBlobX = endX;
    
    // Trigger white glow effect
    _glowController.forward(from: 0.0).then((_) {
      _glowController.reverse();
    });
    
    // Shimmer SYNCHRONIZED with movement (not pre-emptive)
    // Start shimmer at exact same time as blob movement
    _shimmerController.forward(from: 0.0);
    
    // Animate position
    _moveController.forward(from: 0.0).then((_) {
      setState(() {
        _blobCenterX = endX;
        _stretchFactor = 1.0;
        _blobScaleFactor = 1.0; // Reset blob scale
      });
    });
  }
  
  /// Update stretch factor based on movement progress (squash & stretch)
  void _updateStretchFactor() {
    final progress = _moveAnimation.value;
    
    // Maximum stretch at mid-transition (0.5 progress)
    // Using parabolic function: stretch = 1 - k * (progress - 0.5)^2
    const maxStretch = 0.65; // 65% of original width (horizontal compression)
    const stretchAmount = 1.0 - maxStretch;
    final stretch = 1.0 + stretchAmount * (1.0 - 4 * math.pow(progress - 0.5, 2));
    
    // Blob scale: grows at start, returns to normal at end
    // Scale peaks at 35% progress (1.4x), returns to 1.0 by 100%
    final blobScale = progress < 0.35
        ? 1.0 + (progress / 0.35) * 0.4  // Grow to 1.4x (extends beyond navbar)
        : 1.4 - ((progress - 0.35) / 0.65) * 0.4; // Shrink back to 1.0
    
    // Calculate movement velocity for glow intensity
    // Velocity is derivative of position (rate of change)
    final velocity = _moveController.velocity.abs();
    
    setState(() {
      _stretchFactor = stretch.clamp(maxStretch, 1.3);
      _blobScaleFactor = blobScale.clamp(1.0, 1.4); // Allow larger scale
      _movementVelocity = velocity; // Track for glow
      
      // Interpolate blob position smoothly
      if (_targetBlobX != 0.0) {
        final startX = _calculateBlobX(widget.currentIndex);
        _blobCenterX = startX + (_targetBlobX - startX) * progress;
      }
    });
  }
  
  /// Handle drag gesture (elastic blob following)
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dx;
      
      // Elastic lag - blob follows with interpolation
      final targetX = _calculateBlobX(widget.currentIndex) + _dragOffset;
      _blobCenterX = _blobCenterX + (targetX - _blobCenterX) * 0.3; // 30% follow
      
      // Stretch based on drag velocity
      final velocity = details.delta.dx.abs();
      _stretchFactor = 1.0 + (velocity * 0.015).clamp(0.0, 0.18);
    });
  }
  
  /// Handle drag end (spring back)
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });
    
    // Spring back to selected tab with damping
    _animateBlobToTab(widget.currentIndex);
  }
  
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 16,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _navbarScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _navbarScaleAnimation.value,
                child: child,
              );
            },
            child: _buildTwoLayerNavbar(),
          ),
        ),
      ),
    );
  }
  
  /// Build the two-layer navbar structure
  Widget _buildTwoLayerNavbar() {
    return SizedBox(
      height: _navbarHeight,
      child: Stack(
        children: [
          // LAYER 1: Static base glass (passive)
          _buildStaticBaseGlass(),
          
          // White glow overlay (during transitions) - BRIGHT and FULL COVERAGE
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              if (_glowAnimation.value == 0.0) return const SizedBox.shrink();
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4 * _glowAnimation.value),  // Very bright
                        Colors.white.withOpacity(0.3 * _glowAnimation.value),  // Bright
                        Colors.white.withOpacity(0.2 * _glowAnimation.value),  // Medium
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // LAYER 2: Active liquid blob (interactive)
          _buildLiquidBlobLayer(),
          
          // LAYER 3: Icons on top (no blend, sharp)
          _buildIconLayer(),
        ],
      ),
    );
  }
  
  /// LAYER 1: Static base glass container
  Widget _buildStaticBaseGlass() {
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 10,
        glassColor: Color(0x1AFFFFFF), // 10% white tint
        lightIntensity: 1.0,
      ),
      child: LiquidGlass(
        shape: const LiquidRoundedSuperellipse(borderRadius: 24),
        child: Container(
          height: _navbarHeight,
          decoration: const BoxDecoration(
            // Very subtle background tint
            color: Color(0x1A000000),
          ),
        ),
      ),
    );
  }
  
  /// LAYER 2: Active liquid blob with blend group
  Widget _buildLiquidBlobLayer() {
    // Blob dimensions with stretch applied
    final blobWidth = _blobBaseWidth * _stretchFactor;
    final blobHeight = _blobBaseHeight / math.sqrt(_stretchFactor); // Maintain volume
    
    // Movement-based glow intensity (fades when motion stops)
    final isMoving = _moveController.isAnimating || _isDragging;
    final glowIntensity = isMoving ? (1.0 + _movementVelocity * 0.3).clamp(1.0, 1.6) : 0.0;
    
    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: 12, // Increased for more glass depth
        glassColor: const Color(0x14FFFFFF), // 8% tint - true glass-liquid (not flat)
        lightIntensity: 1.0 + (glowIntensity * 0.4), // Boost during movement
      ),
      child: LiquidGlassBlendGroup(
        blend: 42, // Blend intensity (35-50 range)
        child: Stack(
          children: [
            // Liquid blob positioned under selected tab
            AnimatedPositioned(
              duration: _isDragging 
                  ? Duration.zero 
                  : const Duration(milliseconds: 550),
              curve: Curves.easeOutExpo,
              left: _blobCenterX - (blobWidth / 2),
              top: (_navbarHeight - blobHeight) / 2, // Perfect vertical center
              child: Transform.scale(
                scale: _blobScaleFactor, // Blob scales during transition
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                  // Movement-based highlight glow
                  final highlightOpacity = isMoving 
                      ? (0.15 * _shimmerController.value).clamp(0.0, 0.15)
                      : 0.0;
                  
                  return Stack(
                    children: [
                      // Subtle glow ONLY during movement
                      if (isMoving)
                        Positioned.fill(
                          child: SizedBox.expand(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(blobHeight * 0.45),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha((highlightOpacity * 255).toInt()),
                                    blurRadius: 16 * glowIntensity,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // TRUE GLASS BLOB (not Container color)
                      LiquidGlass.grouped(
                        shape: LiquidRoundedSuperellipse(
                          borderRadius: blobHeight * 0.45,
                        ),
                        child: Container(
                          width: blobWidth,
                          height: blobHeight,
                          // NO decoration - glass is handled by LiquidGlass
                          // The translucent appearance comes from LiquidGlassSettings
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// LAYER 3: Icon layer (sits on top, sharp)
  Widget _buildIconLayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isSelected = index == widget.currentIndex;
          
          return Expanded(
            child: _NavbarIconWidget(
              item: item,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                // Trigger navbar scale animation
                _navbarScaleController.forward().then((_) {
                  _navbarScaleController.reverse();
                });
                widget.onTap(index);
              },
            ),
          );
        }),
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

/// Individual navbar icon widget (no glass effects on icons themselves)
class _NavbarIconWidget extends StatefulWidget {
  final NavbarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavbarIconWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavbarIconWidget> createState() => _NavbarIconWidgetState();
}

class _NavbarIconWidgetState extends State<_NavbarIconWidget> 
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
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.curveSpring,
    ));
    
    if (widget.isSelected) {
      _scaleController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(_NavbarIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        child: SizedBox(
          height: 56, // Match navbar height for perfect vertical centering
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center, // Vertical center
            children: [
              // Icon (sharp, no blur) - vertically centered with blob
              Icon(
                widget.isSelected 
                    ? (widget.item.activeIcon ?? widget.item.icon)
                    : widget.item.icon,
                size: 22,
                color: widget.isSelected 
                    ? AppColors.primary 
                    : AppColors.textMuted,
              ),
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
}
