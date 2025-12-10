import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Glass Container Widget
/// Glassmorphism effect with blur, transparency, and animated borders
class GlassContainer extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool enableTilt;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  
  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusLarge,
    this.blurRadius = AppTheme.blurGlass,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.onTap,
    this.enableTilt = false,
    this.boxShadow,
    this.gradient,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppTheme.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: AppTheme.curveDefault),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? 
      (isDark ? AppColors.glassDark : const Color(0x33FFFFFF));
    final bColor = widget.borderColor ?? 
      (isDark ? AppColors.glassBorder : const Color(0x20000000));
    
    Widget container = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurRadius,
          sigmaY: widget.blurRadius,
        ),
        child: AnimatedContainer(
          duration: AppTheme.durationNormal,
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.gradient == null ? bgColor : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed ? AppColors.primary.withOpacity(0.5) : bColor,
              width: widget.borderWidth,
            ),
            boxShadow: widget.boxShadow ?? [
              if (_isPressed)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
    
    if (widget.onTap != null) {
      container = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: container,
        ),
      );
    }
    
    return container;
  }
}

/// Glass Top Bar - Blurred navigation bar
class GlassTopBar extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  
  const GlassTopBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassDark,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSoft,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showBackButton && Navigator.canPop(context))
                leading ?? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.pop(context),
                )
              else if (leading != null)
                leading!,
              if (title != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass Card - Elevated glass container for cards
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusLarge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: AppColors.card,
      borderColor: AppColors.borderSoft,
      onTap: onTap,
      child: child,
    );
  }
}
