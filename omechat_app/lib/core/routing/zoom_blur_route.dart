import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A custom page route that implements a "Zoom + Blur" transition.
/// 
/// Transition details:
/// - **Exit Page**: Scales down (1.0 -> 0.95), Fades out (1.0 -> 0.0), and Blurs (0px -> 10px).
/// - **Enter Page**: Scales up (1.1 -> 1.0) and Fades in (0.0 -> 1.0).
class ZoomBlurPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ZoomBlurPageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );

            final secondaryCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );

            // Entry transition (for the new page)
            final entryScale = Tween<double>(begin: 1.1, end: 1.0).animate(curve);
            final entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

            // Exit transition (for the previous page - when this page pushes another)
            // Note: Since we can't easily affect the page *underneath* without a custom Navigator or
            // complex logic, we usually only control the incoming page here.
            // HOWEVER, standard PageRouteBuilder affects the *incoming* page with `animation`.
            // To achieve the effect where the *outgoing* page blurs, we use `secondaryAnimation` 
            // of the *outgoing* page (which is the `animation` of the *incoming* page).
            
            // Actually, to keep it simple and robust:
            // We just animate the INCOMING page nicely.
            // To blur the OUTGOING page, we wrap the child in a Stack that handles secondaryAnimation.

            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curve),
              child: FadeTransition(
                opacity: entryFade,
                child: ScaleTransition(
                  scale: entryScale,
                  child: _SecondaryTransition(
                    animation: secondaryCurve, // The animation when THIS page is being covered
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

class _SecondaryTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _SecondaryTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value == 0) return child!;
        
        final blur = animation.value * 10.0;
        final scale = 1.0 - (animation.value * 0.05);
        final opacity = 1.0 - (animation.value * 0.5);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
