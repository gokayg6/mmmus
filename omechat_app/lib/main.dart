import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/routing/app_router.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ProviderScope(
      overrides: [
        // Override the storage provider with actual instance
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const OmeChatApp(),
    ),
  );
}

/// OmeChat Application - Dark Orange Theme with Light Mode Support
class OmeChatApp extends ConsumerWidget {
  const OmeChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode from provider
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'OmeChat',
      debugShowCheckedModeBanner: false,
      
      // Theme with light mode support
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Initial route
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
      
      // Builder for global background and 240Hz optimization
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return MediaQuery(
          // Optimize for 240Hz
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.background : AppColors.backgroundLight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
