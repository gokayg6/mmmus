import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glowing_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/tv_static_effect.dart';
import '../../services/features_service.dart';
import '../../services/api_client.dart';
import '../../services/websocket_client.dart';
import '../video_chat/video_chat_screen.dart';
import 'package:omechat/l10n/app_localizations.dart';

/// Random Connect Screen - Full-featured Omegle-style matching hub
class RandomConnectScreen extends ConsumerStatefulWidget {
  const RandomConnectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RandomConnectScreen> createState() => _RandomConnectScreenState();
}

class _RandomConnectScreenState extends ConsumerState<RandomConnectScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _statsController;
  late Animation<double> _bgAnimation;
  late Animation<double> _pulseAnimation;
  
  // Filter states (will be replaced with l10n values in build)
  String _selectedGender = 'everyone';
  String _selectedCountry = 'worldwide';
  String _selectedChatMode = 'video';
  final Set<String> _selectedInterests = {};
  
  // Search state
  bool _isSearching = false;
  bool _isConnecting = false;
  StreamSubscription? _wsSubscription;
  
  // Stats (from real API)
  int _onlineCount = 0;
  final int _totalChats = 156;
  final int _totalMinutes = 892;
  final int _streakDays = 5;
  
  // Available interests
  final List<String> _availableInterests = [
    'Music', 'Gaming', 'Sports', 'Movies', 'Technology', 
    'Travel', 'Food', 'Art', 'Books', 'Fashion',
    'Fitness', 'Photography', 'Dance', 'Comedy', 'Science'
  ];

  @override
  void initState() {
    super.initState();
    
    _bgController = AnimationController(
      duration: const Duration(milliseconds: 3000),  // 120Hz: ~360 frames
      vsync: this,
    )..repeat(reverse: true);
    
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),  // 120Hz: ~180 frames
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1000),  // 120Hz: ~120 frames
      vsync: this,
    )..forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featuresNotifierProvider.notifier).loadFeatures();
      _updateOnlineCount();
      // Periodic online count updates
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _updateOnlineCount();
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _bgController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Future<void> _startVideoChat() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSearching = true;
      _isConnecting = true;
    });
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final wsClient = ref.read(webSocketClientProvider);
      
      // Start session
      String? backendGender;
      if (_selectedGender == 'Kadın') {
        backendGender = 'FEMALE';
      } else if (_selectedGender == 'Erkek') {
        backendGender = 'MALE';
      }

      final sessionResponse = await apiClient.startSession(
        deviceType: 'ANDROID',
        gender: backendGender,
      );
      
      // Connect to WebSocket
      final baseUrl = apiClient.baseUrl;
      await wsClient.connect(baseUrl, sessionResponse.sessionToken);
      
      // Listen for messages
      _wsSubscription = wsClient.messages.listen((message) async {
        final type = message['type'];
        
        if (type == 'MATCH_FOUND') {
          HapticFeedback.mediumImpact();
          if (mounted) {
            final partnerData = message['partner'];
            final pName = partnerData != null ? partnerData['username']?.toString() ?? 'Yabancı' : 'Yabancı';
            final pAvatar = partnerData != null ? partnerData['avatar_url']?.toString() : null;
            final pId = partnerData != null ? partnerData['id']?.toString() : null;

            setState(() {
              _isSearching = false;
              _isConnecting = false;
            });
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => VideoChatScreen(
                  startConnected: true,
                  partnerUsername: pName,
                  partnerAvatar: pAvatar,
                  partnerId: pId,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        } else if (type == 'QUEUE_POSITION') {
          if (message.containsKey('online_count')) {
            if (mounted) {
              setState(() => _onlineCount = message['online_count'] as int);
            }
          }
        } else if (type == 'ONLINE_COUNT_UPDATE') {
          if (mounted) {
            setState(() => _onlineCount = message['count'] as int);
          }
        }
      });
      
      // Join queue after connection established
      await Future.delayed(const Duration(milliseconds: 500));
      wsClient.joinQueue();
      
      // Fetch online count
      _updateOnlineCount();
      
      setState(() => _isConnecting = false);
    } catch (e) {
      print('Matchmaking error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _stopSearching() {
    HapticFeedback.lightImpact();
    _wsSubscription?.cancel();
    ref.read(webSocketClientProvider).leaveQueue();
    ref.read(webSocketClientProvider).disconnect();
    setState(() {
      _isSearching = false;
      _isConnecting = false;
    });
  }

  Future<void> _updateOnlineCount() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/api/v1/public/online-count');
      if (mounted && response.data != null) {
        setState(() {
          _onlineCount = response.data['online_users'] ?? 0;
        });
      }
    } catch (e) {
      print('Failed to fetch online count: $e');
      // Keep current count on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!_isSearching) ...[
            _buildAnimatedBackground(),
            _buildRadialGlow(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  decelerationRate: ScrollDecelerationRate.fast,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildUserStats(),
                    const SizedBox(height: 20),
                    _buildStartButton(),
                    const SizedBox(height: 24),
                    _buildFiltersSection(),
                    const SizedBox(height: 20),
                    _buildInterestsSection(),
                    const SizedBox(height: 20),
                    _buildChatModeSection(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildPremiumBanner(),
                    const SizedBox(height: 20),
                    _buildLiveActivity(),
                    const SizedBox(height: 20),
                    _buildSafetyTips(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
          
          OmegleTvStaticEffect(
            isSearching: _isSearching,
            onSkip: _stopSearching,
            statusText: _getSearchStatusText(),
          ),
        ],
      ),
    );
  }

  String _getSearchStatusText() {
    if (_selectedGender != 'Herkes') {
      return '$_selectedGender aranıyor...';
    }
    if (_selectedCountry != 'Tüm Dünya') {
      return '$_selectedCountry\'dan birisi aranıyor...';
    }
    if (_selectedInterests.isNotEmpty) {
      return 'Ortak ilgi alanları aranıyor...';
    }
    return 'Birisi aranıyor...';
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.backgroundColor,
                Color.lerp(
                  context.colors.backgroundColor,
                  context.isDarkMode ? const Color(0xFF1A0A04) : const Color(0xFFFFF0E6),
                  _bgAnimation.value * 0.3,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadialGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15 + _bgAnimation.value * 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final featuresAsync = ref.watch(featuresNotifierProvider);
    final credits = featuresAsync.whenOrNull(data: (f) => f.credits) ?? 0;
    final isLoggedIn = featuresAsync.whenOrNull(data: (f) => f.credits >= 0) ?? false;
    // Check if actually logged in by checking if we have a valid response
    final hasData = featuresAsync.hasValue && !featuresAsync.hasError;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.discover ?? 'Discover', style: AppTypography.largeTitle(color: context.colors.textColor)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)?.findPartner ?? 'Meet new people', style: AppTypography.footnote(color: context.colors.textSecondaryColor)),
              ],
            ),
          ),
          // Login button for guests
          if (!hasData) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded, color: context.colors.textColor, size: 16),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)?.login ?? 'Login', style: AppTypography.caption1(color: context.colors.textColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Credits badge (only show when logged in)
          if (hasData) ...[
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/credits'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text('$credits', style: AppTypography.caption1(color: AppColors.warning)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _OnlineCountBadge(count: _onlineCount),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatItem(Icons.chat_bubble_rounded, '$_totalChats', AppLocalizations.of(context)?.chat ?? 'Chat', AppColors.primary),
            _buildStatDivider(),
            _buildStatItem(Icons.timer_rounded, '$_totalMinutes', 'min', AppColors.success),
            _buildStatDivider(),
            _buildStatItem(Icons.local_fire_department_rounded, '$_streakDays', 'Streak', AppColors.warning),
            _buildStatDivider(),
            _buildStatItem(Icons.favorite_rounded, '23', 'Likes', AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _statsController,
            builder: (context, child) {
              return Text(
                value,
                style: AppTypography.headline(color: context.colors.textColor),
              );
            },
          ),
          Text(label, style: AppTypography.caption2(color: context.colors.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: AppColors.borderSoft);
  }

  Widget _buildStartButton() {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(scale: _pulseAnimation.value, child: child);
            },
            child: GlowingButton(
              size: 140,
              showPulse: true,
              onPressed: _startVideoChat,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedChatMode == 'video' ? Icons.videocam_rounded : 
                    _selectedChatMode == 'text' ? Icons.chat_rounded : Icons.call_rounded,
                    color: context.colors.textColor,
                    size: 44,
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)?.startMatching?.toUpperCase() ?? 'START', style: AppTypography.caption1(color: context.colors.textColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedChatMode == 'video' ? (AppLocalizations.of(context)?.videoChat ?? 'Video Chat') : 
            _selectedChatMode == 'text' ? (AppLocalizations.of(context)?.textChat ?? 'Text Chat') : (AppLocalizations.of(context)?.voiceChat ?? 'Voice Chat'),
            style: AppTypography.title3(color: context.colors.textColor),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedGender != 'everyone') ...[
                _buildActiveFilter(_selectedGender, Icons.person_rounded),
                const SizedBox(width: 8),
              ],
              if (_selectedCountry != 'worldwide') ...[
                _buildActiveFilter(_selectedCountry, Icons.public_rounded),
                const SizedBox(width: 8),
              ],
              if (_selectedInterests.isNotEmpty)
                _buildActiveFilter('${_selectedInterests.length} ${AppLocalizations.of(context)?.interests ?? "Interests"}', Icons.interests_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilter(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption2(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.filters?.toUpperCase() ?? 'FILTERS', style: AppTypography.caption1(color: context.colors.textMutedColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenderFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildCountryFilter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    final featuresAsync = ref.watch(featuresNotifierProvider);
    final canUseGenderFilter = featuresAsync.whenOrNull(data: (f) => f.canUseGenderFilter) ?? false;
    
    return GestureDetector(
      onTap: () => _showGenderPicker(canUseGenderFilter),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wc_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)?.gender ?? 'Gender', style: AppTypography.caption1(color: context.colors.textSecondaryColor)),
                const Spacer(),
                if (!canUseGenderFilter)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 10, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text('30', style: AppTypography.caption2(color: AppColors.warning)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedGender == 'female' ? Icons.female_rounded : 
                    _selectedGender == 'male' ? Icons.male_rounded : Icons.people_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_selectedGender, style: AppTypography.body(color: context.colors.textColor)),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondaryColor, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker(bool canUseGenderFilter) {
    final l10n = AppLocalizations.of(context);
    final genders = [
      ('everyone', l10n?.everyone ?? 'Everyone', Icons.people_rounded, false),
      ('female', l10n?.female ?? 'Female', Icons.female_rounded, true),
      ('male', l10n?.male ?? 'Male', Icons.male_rounded, true),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GlassBottomSheet(
        title: l10n?.selectGender ?? 'Select Gender',
        icon: Icons.wc_rounded,
        children: genders.map((gender) {
          final isSelected = _selectedGender == gender.$1;
          final needsUnlock = gender.$4 && !canUseGenderFilter;
          
          return _GlassOptionTile(
            icon: gender.$3,
            title: gender.$2,
            isSelected: isSelected,
            isLocked: needsUnlock,
            lockCost: 30,
            onTap: () {
              Navigator.pop(ctx);
              if (needsUnlock) {
                _showUnlockDialog('gender_filter', l10n?.gender ?? 'Gender Filter', FeatureCosts.genderFilter);
              } else {
                setState(() => _selectedGender = gender.$1);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountryFilter() {
    final featuresAsync = ref.watch(featuresNotifierProvider);
    final canUseCountryFilter = featuresAsync.whenOrNull(data: (f) => f.canUseCountryFilter) ?? false;
    
    return GestureDetector(
      onTap: () => _showCountryPicker(canUseCountryFilter),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)?.country ?? 'Country', style: AppTypography.caption1(color: context.colors.textSecondaryColor)),
                const Spacer(),
                if (!canUseCountryFilter)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 10, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text('20', style: AppTypography.caption2(color: AppColors.warning)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Text(
                    _getCountryFlag(_selectedCountry),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_selectedCountry, style: AppTypography.body(color: context.colors.textColor)),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondaryColor, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryFlag(String country) {
    switch (country) {
      case 'Türkiye': return '🇹🇷';
      case 'ABD': return '🇺🇸';
      case 'Almanya': return '🇩🇪';
      case 'İngiltere': return '🇬🇧';
      case 'Fransa': return '🇫🇷';
      case 'İspanya': return '🇪🇸';
      case 'İtalya': return '🇮🇹';
      case 'Rusya': return '🇷🇺';
      case 'Japonya': return '🇯🇵';
      case 'Brezilya': return '🇧🇷';
      default: return '🌍';
    }
  }

  void _showCountryPicker(bool canUseCountryFilter) {
    final countries = [
      ('Tüm Dünya', '🌍', false),
      ('Türkiye', '🇹🇷', true),
      ('ABD', '🇺🇸', true),
      ('Almanya', '🇩🇪', true),
      ('İngiltere', '🇬🇧', true),
      ('Fransa', '🇫🇷', true),
      ('İspanya', '🇪🇸', true),
      ('İtalya', '🇮🇹', true),
      ('Rusya', '🇷🇺', true),
      ('Japonya', '🇯🇵', true),
      ('Brezilya', '🇧🇷', true),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GlassBottomSheet(
        title: 'Ülke Seç',
        icon: Icons.public_rounded,
        children: countries.map((country) {
          final isSelected = _selectedCountry == country.$1;
          final needsUnlock = country.$3 && !canUseCountryFilter;
          
          return _GlassOptionTile(
            emoji: country.$2,
            title: country.$1,
            isSelected: isSelected,
            isLocked: needsUnlock,
            lockCost: 20,
            onTap: () {
              Navigator.pop(ctx);
              if (needsUnlock) {
                _showUnlockDialog('country_filter', 'Ülke Filtresi', FeatureCosts.countryFilter);
              } else {
                setState(() => _selectedCountry = country.$1);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.interests_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.interests?.toUpperCase() ?? 'INTERESTS', style: AppTypography.caption1(color: context.colors.textMutedColor)),
              const Spacer(),
              if (_selectedInterests.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selectedInterests.clear()),
                  child: Text(AppLocalizations.of(context)?.clearAll ?? 'Clear', style: AppTypography.caption1(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 5) {
                      _selectedInterests.add(interest);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Max 5 interests allowed'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: AppTheme.durationFast,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.button : null,
                    color: isSelected ? null : context.colors.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected ? null : Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    interest,
                    style: AppTypography.caption1(color: isSelected ? Colors.white : context.colors.textSecondaryColor),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedInterests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Matching based on selected interests',
              style: AppTypography.caption2(color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatModeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.switch_video_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.chatMode?.toUpperCase() ?? 'CHAT MODE', style: AppTypography.caption1(color: context.colors.textMutedColor)),
            ],
          ),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _buildModeOption('video', Icons.videocam_rounded, AppLocalizations.of(context)?.videoChatMode ?? 'Video'),
                _buildModeOption('text', Icons.chat_rounded, AppLocalizations.of(context)?.textChatMode ?? 'Text'),
                _buildModeOption('voice', Icons.mic_rounded, AppLocalizations.of(context)?.voiceChatMode ?? 'Voice'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String mode, IconData icon, String label) {
    final isSelected = _selectedChatMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedChatMode = mode);
        },
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.button : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : context.colors.textSecondaryColor, size: 24),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.caption1(color: isSelected ? Colors.white : context.colors.textSecondaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.quickActions?.toUpperCase() ?? 'QUICK ACTIONS', style: AppTypography.caption1(color: context.colors.textMutedColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.speed_rounded,
                  title: 'Speed Match',
                  subtitle: '15 sec chat',
                  color: AppColors.warning,
                  onTap: () {
                    // TODO: Speed dating mode
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.group_rounded,
                  title: 'Group Chat',
                  subtitle: '3+ people',
                  color: AppColors.success,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coming soon!'), backgroundColor: AppColors.primary),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.subheadlineMedium(color: context.colors.textColor)),
            Text(subtitle, style: AppTypography.caption2(color: context.colors.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    final featuresAsync = ref.watch(featuresNotifierProvider);
    final isPremium = featuresAsync.whenOrNull(data: (f) => f.isPremium) ?? false;
    
    if (isPremium) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/subscription'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppGradients.button,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: context.colors.textColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)?.getPremium ?? 'Get Premium', style: AppTypography.headline(color: context.colors.textColor)),
                    Text(
                      AppLocalizations.of(context)?.premiumDescription ?? 'Unlimited filters, no ads, HD quality',
                      style: AppTypography.caption1(color: context.colors.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: context.colors.textSecondaryColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.liveActivity?.toUpperCase() ?? 'LIVE ACTIVITY', style: AppTypography.caption1(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem('2 people matched from Turkey', '1 min ago', Icons.favorite_rounded, AppColors.error),
                const SizedBox(height: 12),
                _buildActivityItem('12 new users joined', '3 min ago', Icons.person_add_rounded, AppColors.success),
                const SizedBox(height: 12),
                _buildActivityItem('156 active chats right now', 'Now', Icons.chat_bubble_rounded, AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppTypography.body(color: context.colors.textColor)),
        ),
        Text(time, style: AppTypography.caption2(color: context.colors.textMutedColor)),
      ],
    );
  }

  Widget _buildSafetyTips() {
    final l10n = AppLocalizations.of(context);
    final tips = [
      (l10n?.safetyTip1 ?? 'Never share personal information', Icons.security_rounded),
      (l10n?.safetyTip2 ?? 'Report inappropriate behavior', Icons.flag_rounded),
      ('You can turn off your camera for safety', Icons.videocam_off_rounded),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(l10n?.safetyTips?.toUpperCase() ?? 'SAFETY TIPS', style: AppTypography.caption1(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(tip.$2, color: AppColors.success.withOpacity(0.7), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tip.$1, style: AppTypography.caption1(color: context.colors.textSecondaryColor)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showUnlockDialog(String featureName, String displayName, int cost) {
    final featuresAsync = ref.read(featuresNotifierProvider);
    final userCredits = featuresAsync.whenOrNull(data: (f) => f.credits) ?? 0;
    final canAfford = userCredits >= cost;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_open_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Text(displayName, style: AppTypography.title2()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Krediniz', style: AppTypography.caption1(color: AppColors.textSecondary)),
                      Text('$userCredits', style: AppTypography.headline(color: AppColors.warning)),
                    ],
                  ),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Gerekli', style: AppTypography.caption1(color: AppColors.textSecondary)),
                      Text('$cost', style: AppTypography.headline(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.primaryDark.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Premium üyeler ücretsiz kullanır!', style: AppTypography.caption1(color: AppColors.primary))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: AppTypography.buttonMedium(color: AppColors.textSecondary)),
          ),
          if (!canAfford)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/credits');
              },
              child: Text('Kredi Al', style: AppTypography.buttonMedium(color: AppColors.warning)),
            ),
          if (canAfford)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _unlockFeature(featureName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text('Aç ($cost)', style: AppTypography.buttonMedium(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _unlockFeature(String featureName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
      
      final result = await ref.read(featuresNotifierProvider.notifier).unlockFeature(featureName);
      
      if (mounted) Navigator.pop(context);
      
      if (result != null && result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Özellik açıldı! Kalan: ${result.remainingCredits}', style: AppTypography.body(color: Colors.white))),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _OnlineCountBadge extends StatelessWidget {
  final int count;
  const _OnlineCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.online.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.online.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.online.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: AppTypography.caption1(color: AppColors.online)),
        ],
      ),
    );
  }
}

/// Glassmorphism Bottom Sheet
class _GlassBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _GlassBottomSheet({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: (context.isDarkMode ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textMutedColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.title2(color: context.colors.textColor)),
                          Text('Bir seçenek belirleyin', style: AppTypography.caption1(color: context.colors.textSecondaryColor)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Icon(Icons.close_rounded, color: context.colors.textSecondaryColor, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(height: 1, color: AppColors.borderSoft),
              // Options
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: children),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism Option Tile
class _GlassOptionTile extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String title;
  final bool isSelected;
  final bool isLocked;
  final int? lockCost;
  final VoidCallback onTap;

  const _GlassOptionTile({
    this.icon,
    this.emoji,
    required this.title,
    required this.isSelected,
    this.isLocked = false,
    this.lockCost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : context.colors.surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSoft,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Icon or Emoji
            if (icon != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.textColor.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? context.colors.textColor : AppColors.primary,
                  size: 24,
                ),
              )
            else if (emoji != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.textColor.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji!, style: const TextStyle(fontSize: 24)),
                ),
              ),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                title,
                style: AppTypography.body(
                  color: isSelected ? Colors.white : context.colors.textColor,
                ),
              ),
            ),
            // Lock or Check
            if (isLocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('$lockCost', style: AppTypography.caption1(color: AppColors.warning)),
                  ],
                ),
              ),
            ] else if (isSelected) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
