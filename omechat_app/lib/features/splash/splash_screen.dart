import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

/// Splash Screen with animated logo glow - checks auth state
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo scale and fade animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Pulsing glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _logoController.forward();
    _glowController.repeat(reverse: true);
    
    // Navigate after delay
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    // Check auth state
    final authState = ref.read(authProvider);
    final storage = ref.read(storageServiceProvider);
    
    String nextRoute;
    
    if (authState.isAuthenticated) {
      // User is logged in - go to main app
      nextRoute = AppRoutes.main;
    } else if (storage.isOnboardingComplete()) {
      // Onboarding done but not logged in - go to auth
      nextRoute = AppRoutes.authGateway;
    } else {
      // First time - show onboarding
      nextRoute = AppRoutes.onboarding;
    }
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      // If auth state changes during splash, handle it
    });
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.background,
            ),
          ),
          
          // Orange radial glow from center
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(_glowAnimation.value * 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Logo and text
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo container with glow - Ome Text Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'O',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // App name
                        Text(
                          'OmeChat',
                          style: AppTypography.extraLargeTitle().copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Yeni İnsanlarla Tanış',
                          style: AppTypography.body(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary.withOpacity(0.7)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
