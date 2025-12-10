import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/online_count_badge.dart';
import '../../core/routing/app_router.dart';
import '../../services/api_client.dart';

/// Home Screen - Main matchmaking entry point
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _onlineCount = 0;
  Timer? _onlineCountTimer;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.durationSlow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
    ));
    
    _controller.forward();
    _fetchOnlineCount();
    _startOnlineCountTimer();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _onlineCountTimer?.cancel();
    super.dispose();
  }
  
  void _startOnlineCountTimer() {
    _onlineCountTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchOnlineCount();
    });
  }
  
  Future<void> _fetchOnlineCount() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getOnlineCount();
      if (mounted) {
        setState(() => _onlineCount = response.onlineUsers);
      }
    } catch (e) {
      // Silently fail, use mock data
      if (mounted && _onlineCount == 0) {
        setState(() => _onlineCount = 1234);
      }
    }
  }
  
  void _startChat() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, AppRoutes.permissions);
  }
  
  void _showFeatureSheet(BuildContext context, String title, String description, IconData icon) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FeatureBottomSheet(
        title: title,
        description: description,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'OmeChat',
                          style: AppTypography.title2(),
                        ),
                      ],
                    ),
                    
                    // Online count
                    OnlineCountBadge(count: _onlineCount),
                  ],
                ),
                
                const Spacer(),
                
                // Main content
                Center(
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'Bağlanmaya\nHazır mısın?',
                        style: AppTypography.extraLargeTitle(),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        'Şu anda $_onlineCount kişi çevrimiçi',
                        style: AppTypography.body(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Start button with animated press effect
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          _startChat();
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: AnimatedScale(
                          scale: _isPressed ? 0.95 : 1.0,
                          duration: AppTheme.durationFast,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withOpacity(
                                    _isPressed ? 0.6 : 0.4,
                                  ),
                                  blurRadius: _isPressed ? 50 : 40,
                                  spreadRadius: _isPressed ? 10 : 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Başla',
                                  style: AppTypography.headline(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Feature cards
                Row(
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.flash_on_rounded,
                        title: 'Hızlı',
                        subtitle: 'Anında eşleş',
                        onTap: () => _showFeatureSheet(
                          context,
                          'Hızlı Eşleşme',
                          'Gelişmiş algoritmamız sayesinde saniyeler içinde yeni insanlarla tanışabilirsiniz. Bekleme süresi minimumda tutulur.',
                          Icons.flash_on_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.shield_rounded,
                        title: 'Güvenli',
                        subtitle: 'Moderasyon',
                        onTap: () => _showFeatureSheet(
                          context,
                          'Güvenlik & Kurallar',
                          'Topluluk kurallarımız ve aktif moderasyon ekibimiz ile güvenli bir ortam sağlıyoruz. Uygunsuz davranışlar anında raporlanabilir.',
                          Icons.shield_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.language_rounded,
                        title: 'Global',
                        subtitle: 'Dünya çapında',
                        onTap: () => _showFeatureSheet(
                          context,
                          'Dünya Genelinde',
                          'Dünyanın dört bir yanından kullanıcılarla bağlantı kurun. Farklı kültürlerden insanlarla tanışma fırsatı.',
                          Icons.language_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF0EA5E9),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: AppTypography.subheadlineMedium(),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: AppTypography.caption2(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  
  const _FeatureBottomSheet({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            title,
            style: AppTypography.title2(),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            description,
            style: AppTypography.body(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          SecondaryButton(
            text: 'Tamam',
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
