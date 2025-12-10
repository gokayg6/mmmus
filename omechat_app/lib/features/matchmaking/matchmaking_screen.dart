import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/orb_animation.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/online_count_badge.dart';
import '../../core/routing/app_router.dart';
import '../../services/api_client.dart';
import '../../services/websocket_client.dart';
import '../../services/webrtc_service.dart';

/// Premium Matchmaking Screen with orb animation
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  int _dotCount = 0;
  int _onlineCount = 0;
  StreamSubscription? _wsSubscription;
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    
    _initMatchmaking();
    
    // Animated dots for "Searching..."
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _textController.reset();
        _textController.forward();
      }
    });
    
    _textController.forward();
  }
  
  Future<void> _initMatchmaking() async {
    setState(() => _isConnecting = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final wsClient = ref.read(webSocketClientProvider);
      
      // Start session
      final sessionResponse = await apiClient.startSession(
        deviceType: 'ANDROID',
      );
      
      // Connect to WebSocket
      final baseUrl = apiClient.baseUrl;
      await wsClient.connect(baseUrl, sessionResponse.sessionToken);
      
      // Listen for messages
      _wsSubscription = wsClient.messages.listen((message) async {
        final type = message['type'];
        
        if (type == 'MATCH_FOUND') {
          HapticFeedback.mediumImpact();
          final connectionId = message['connection_id'];
          final isInitiator = message['is_initiator'];
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              AppRoutes.chat,
              arguments: {
                'connectionId': connectionId,
                'isInitiator': isInitiator,
              }
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
      
      // Periodic online count updates
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          _updateOnlineCount();
        } else {
          timer.cancel();
        }
      });
      
      setState(() => _isConnecting = false);
    } catch (e) {
      print('Matchmaking error: $e');
      if (mounted) {
        setState(() => _isConnecting = false);
        // Use mock count on error
        setState(() => _onlineCount = 1234);
      }
    }
  }
  
  @override
  void dispose() {
    _wsSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }
  
  void _cancelMatchmaking() {
    HapticFeedback.lightImpact();
    ref.read(webSocketClientProvider).leaveQueue();
    Navigator.pop(context);
  }
  
  Future<void> _updateOnlineCount() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final onlineCount = await apiClient.getOnlineCount();
      if (mounted) {
        setState(() => _onlineCount = onlineCount.onlineUsers);
      }
    } catch (e) {
      print('Error updating online count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with online count
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _cancelMatchmaking,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    OnlineCountBadge(count: _onlineCount),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Orb animation
              const OrbAnimation(size: 200),
              
              const SizedBox(height: 48),
              
              // Searching text
              Text(
                'Sana uygun birini arıyoruz${'.' * _dotCount}',
                style: AppTypography.title2(),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _isConnecting 
                    ? 'Bağlanıyor...' 
                    : 'Lütfen bekleyin',
                style: AppTypography.body(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              
              const Spacer(),
              
              // Cancel button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SecondaryButton(
                  text: 'İptal',
                  icon: Icons.close_rounded,
                  onPressed: _cancelMatchmaking,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
