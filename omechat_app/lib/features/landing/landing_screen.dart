import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/routing/app_router.dart';
import '../../services/api_client.dart';
import '../../services/webrtc_service.dart';

// State provider for session initialization
final sessionInitProvider = FutureProvider.autoDispose<void>((ref) async {
  // Just a placeholder to track state
});

/// Landing Screen - Main entry point for users
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _selectedGender = 3; // 0: Male, 1: Female, 2: Other, 3: No preference
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppTheme.durationNormal,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppTheme.curveDefault,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.curveDefault,
      ),
    );
    
    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _handleStartChat() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      final genderMap = ['MALE', 'FEMALE', 'OTHER', 'UNSPECIFIED'];
      final selectedGenderStr = genderMap[_selectedGender];
      
      // 1. Generate device fingerprint (simplified)
      final deviceFingerprint = const Uuid().v4();
      
      // 2. Start session via API
      final apiClient = ref.read(apiClientProvider);
      final session = await apiClient.startSession(
        deviceType: 'ANDROID', // TODO: Platform.isIOS ? 'IOS' : 'ANDROID'
        gender: selectedGenderStr,
        deviceFingerprint: deviceFingerprint,
      );
      
      print('Session Started: ${session.sessionId}');
      
      // 3. Configure WebRTC ICE servers
      ref.read(webRTCServiceProvider).setIceServers(session.iceServers);
      
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.permissions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo and title
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'OmeChat',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Description
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Text(
                    'Dünyanın dört bir yanından yeni insanlarla tanış.\nAnında video ve metin sohbeti başlat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Gender selection
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cinsiyetiniz (isteğe bağlı)',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGenderSelector(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Start button
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PrimaryButton(
                      text: 'Sohbete Başla',
                      icon: Icons.play_arrow_rounded,
                      onPressed: _isLoading ? null : _handleStartChat,
                      isLoading: _isLoading,
                      width: double.infinity,
                      height: 60,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Terms text
                Text(
                  'Devam ederek Kullanım Koşulları ve\nGizlilik Politikası\'nı kabul etmiş olursunuz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGenderSelector() {
    final options = ['Erkek', 'Kadın', 'Diğer', 'Farketmez'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = _selectedGender == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedGender = index);
              },
              child: AnimatedContainer(
                duration: AppTheme.durationFast,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  options[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
