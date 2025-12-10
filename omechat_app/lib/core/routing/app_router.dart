import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../core/routing/zoom_blur_route.dart';

import '../../features/auth/auth_gateway_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/permissions/permissions_screen.dart';
import '../../features/matchmaking/matchmaking_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat_list/chat_list_screen.dart';
import '../../features/chat_detail/chat_detail_screen.dart';
import '../../features/random_connect/random_connect_screen.dart';
import '../../features/calls/calls_screen.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String authGateway = '/auth-gateway';
  static const String register = '/register';
  static const String login = '/login';
  static const String shell = '/shell';
  static const String home = '/home';
  static const String permissions = '/permissions';
  static const String matchmaking = '/matchmaking';
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';
  static const String randomConnect = '/random-connect';
  static const String calls = '/calls';
  static const String settings = '/settings';
  
  // Main app route (alias for shell)
  static const String main = '/shell';
  
  // Legacy route - redirect to shell
  static const String landing = '/landing';
}

/// App Router - Handles navigation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      
      case AppRoutes.auth:
        return _buildRoute(const AuthGatewayScreen(), settings);
      
      case AppRoutes.authGateway:
        return _buildRoute(const AuthGatewayScreen(), settings);
      
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen(), settings);
      
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      
      case AppRoutes.shell:
        return _buildRoute(const MainShell(), settings);
      
      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);
      
      case AppRoutes.permissions:
        return _buildRoute(const PermissionsScreen(), settings);
      
      case AppRoutes.matchmaking:
        return _buildRoute(const MatchmakingScreen(), settings);
      
      case AppRoutes.chat:
        return _buildRoute(const ChatScreen(), settings);
      
      case AppRoutes.chatList:
        return _buildRoute(const ChatListScreen(), settings);
      
      case AppRoutes.chatDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final conversationId = args?['conversationId'] as String?;
        final otherUsername = args?['otherUsername'] as String?;
        if (conversationId != null && otherUsername != null) {
          return _buildRoute(ChatDetailScreen(
            conversationId: conversationId,
            otherUsername: otherUsername,
            otherAvatarUrl: args?['otherAvatarUrl'] as String?,
          ), settings);
        }
        return _buildRoute(const ChatListScreen(), settings);
      
      case AppRoutes.randomConnect:
        return _buildRoute(const RandomConnectScreen(), settings);
      
      case AppRoutes.calls:
        return _buildRoute(const CallsScreen(), settings);
      
      // Legacy route - redirect to shell
      case AppRoutes.landing:
        return _buildRoute(const MainShell(), settings);
      
      default:
        return _buildRoute(
          Scaffold(
            backgroundColor: const Color(0xFF080404),
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          settings,
        );
    }
  }
  
  /// Build premium Zoom + Blur page route
  static PageRoute _buildRoute(Widget page, RouteSettings settings) {
    return ZoomBlurPageRoute(
      page: page,
      settings: settings,
    );
  }
  
  /// Build fade transition route
  static Route<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  /// Build bottom sheet route with blur
  static Route<T> bottomSheetRoute<T>(Widget sheet) {
    return PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => sheet,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}
