import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/online_count_badge.dart';
import '../../core/routing/app_router.dart';
import '../../core/haptics/haptic_engine.dart';
import 'widgets/glass_message_bubble.dart';
import 'widgets/liquid_input_bar.dart';
import 'widgets/telegram_style_widgets.dart';
import '../../services/websocket_client.dart';
import '../../services/webrtc_service.dart';
import '../../services/api_client.dart';
import '../../providers/database_providers.dart';
import '../../providers/auth_provider.dart';
import '../../domain/models/chat_models.dart';

/// Premium Chat Screen - Cinematic video chat with controls
class ChatScreen extends ConsumerStatefulWidget {
  final String? connectionId;
  final bool? isInitiator;

  const ChatScreen({
    super.key,
    this.connectionId,
    this.isInitiator,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  // Renderers
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  
  // Controls state
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isChatExpanded = false;
  bool _isConnecting = true;
  bool _isConnected = false;
  
  // Chat
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  // Connection
  String? _connectionId;
  bool _isInitiator = false;
  StreamSubscription? _wsSubscription;
  
  // PiP position
  Offset _pipPosition = const Offset(20, 100);
  
  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initRenderers();
    _initAnimations();
    
    // Defer state updates to post-frame to avoid rebuild contention
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      String? connId;
      bool initiator = false;

      if (args != null) {
        connId = args['connectionId'];
        initiator = args['isInitiator'] ?? false;
      } else if (widget.connectionId != null) {
        connId = widget.connectionId;
        initiator = widget.isInitiator ?? false;
      }

      if (connId != null) {
        setState(() {
          _connectionId = connId;
          _isInitiator = initiator;
        });
        _startCall();
        print('CHAT_SCREEN: Initialized with ID: $connId');
      } else {
        print('CHAT_SCREEN ERROR: No Connection ID provided!');
      }
    });
  }
  
  void _initAnimations() {
    _fadeController = AnimationController(duration: AppTheme.durationMedium, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }
  
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }
  
  Future<void> _startCall() async {
    final webrtc = ref.read(webRTCServiceProvider);
    final ws = ref.read(webSocketClientProvider);
    
    webrtc.onLocalStream = (stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    };
    
    webrtc.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
      _fadeController.forward();
    };
    
    webrtc.onIceCandidate = (candidate) {
      if (_connectionId != null) {
        ws.sendIceCandidate(_connectionId!, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };
    
    webrtc.onConnectionStateChange = (state) {
      if (state == 'disconnected' || state == 'failed' || state == 'closed') {
        setState(() => _isConnected = false);
      }
    };
    
    await webrtc.initLocalStream();
    
    _wsSubscription = ws.messages.listen((message) async {
      final type = message['type'];
      switch (type) {
        case 'OFFER':
          await webrtc.setRemoteDescription(message['sdp'], 'offer');
          final answer = await webrtc.createAnswer();
          if (_connectionId != null) ws.sendAnswer(_connectionId!, answer.sdp!);
          break;
        case 'ANSWER':
          await webrtc.setRemoteDescription(message['sdp'], 'answer');
          break;
        case 'ICE_CANDIDATE':
          await webrtc.addIceCandidate(message['candidate']);
          break;
        case 'MATCH_ENDED':
          _handleMatchEnded(message['reason'] ?? 'Bağlantı sonlandı');
          break;
      }
    });
    
    if (_isInitiator && _connectionId != null) {
      final offer = await webrtc.createOffer();
      ws.sendOffer(_connectionId!, offer.sdp!);
    }
  }
  
  @override
  void dispose() {
    _wsSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  void _toggleCamera() {
    HapticFeedback.lightImpact();
    setState(() => _isCameraOn = !_isCameraOn);
    ref.read(webRTCServiceProvider).toggleCamera(_isCameraOn);
  }
  
  void _toggleMic() {
    HapticFeedback.lightImpact();
    setState(() => _isMicOn = !_isMicOn);
    ref.read(webRTCServiceProvider).toggleMicrophone(_isMicOn);
  }
  
  void _handleNext() {
    HapticFeedback.mediumImpact();
    ref.read(webSocketClientProvider).next();
    Navigator.pushReplacementNamed(context, AppRoutes.matchmaking);
  }
  
  void _handleMatchEnded(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(reason), backgroundColor: AppColors.warning),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.matchmaking);
  }
  
  void _handleReport() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ReportBottomSheet(),
    );
  }
  
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    if (_connectionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hata: Bağlantı ID yok!'), backgroundColor: Colors.red),
        );
        return;
    }
    
    final repository = ref.read(offlineChatRepositoryProvider);
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id ?? 'unknown';

    try {
    // Get other username from widget args/params if available, specifically for new chats
    // We might need to access the widget's otherUsername if it was passed!
    // However, ChatScreen currently only takes connectionId. 
    // We should probably pass otherUsername to ChatScreen or fetch it.
    // For now, let's try to lookup from existing chat or fallback.
    
    // Better strategy: Pass it from the screen widget if available.
    // The previous logic didn't seem to store `otherUsername` in the state consistently for new chats.
    // We need to ensure `ChatScreen` knows the name.
    
    // TEMPORARY FIX: If this is a match screen transition, we might not have name easily.
    // But if it came from ChatList -> ChatDetail which uses ChatScreen logic...
    // Wait, ChatScreen is for Video? ChatDetailScreen is for Text?
    // User sidebar says: `ChatScreen` (c:\...\chat_screen.dart) "Premium Chat Screen - Cinematic video chat"
    // User request implies text chat inside this screen too.
    
    // Use "Kullanıcı" as fallback if we can't find it, but logic should be to pass it in.
    // Assuming for now we don't have it easily in state without refactor.
    // BUT! connectionId might be the ID.
    
    await repository.sendMessage(
        _connectionId!, 
        text, 
        currentUserId,
        receiverName: 'Kullanıcı', // Placeholder until we pass name properly
    );
        _chatController.clear();
        HapticFeedback.lightImpact();
        
        // Auto-scroll logic could be enhanced, but simple delay works for MVP
        Future.delayed(const Duration(milliseconds: 300), () {
            if (_chatScrollController.hasClients) {
                _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: AppTheme.durationFast,
                curve: Curves.easeOut,
                );
            }
        });
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mesaj gönderilemedi: $e'), backgroundColor: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body: Stack(
        children: [
          // Remote Video
          Container(
            color: context.colors.surfaceColor,
            child: _isConnected
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: RTCVideoView(
                        _remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 24),
                        const Text('Bağlanıyor...', style: TextStyle(color: Colors.white70)),
                        if (_connectionId != null)
                             Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text('ID: $_connectionId', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                             ),
                      ],
                    ),
                  ),
          ),
          
          // Top Bar
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          
          // PiP
          Positioned(
            right: _pipPosition.dx,
            top: _pipPosition.dy + MediaQuery.of(context).padding.top + 60,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _pipPosition = Offset(
                    (_pipPosition.dx - details.delta.dx).clamp(10, MediaQuery.of(context).size.width - 130),
                    (_pipPosition.dy + details.delta.dy).clamp(0, MediaQuery.of(context).size.height - 300),
                  );
                });
              },
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isCameraOn
                      ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                      : Container(color: AppColors.surfaceDark, child: const Icon(Icons.videocam_off_rounded, color: AppColors.error)),
                ),
              ),
            ),
          ),
          
          // Chat Panel
          AnimatedPositioned(
            duration: AppTheme.durationMedium,
            curve: AppTheme.curveSpring,
            bottom: _isChatExpanded ? 110 : -250,
            left: 0,
            right: 0,
            child: _buildChatPanel(),
          ),
          
          // Bottom Controls
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomControls()),
        ],
      ),
    );
  }
  
  Widget _buildTopBar() {
    return ClipRRect(
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
                height: 56 + MediaQuery.of(context).padding.top,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16),
                decoration: BoxDecoration(color: AppColors.glassDark),
                child: Row(
                    children: [
                        Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.videocam_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(_isConnected ? 'Bağlandı' : 'Bağlanıyor...', style: AppTypography.headline()),
                                // VISUAL DEBUG: Show ID
                                Text(_connectionId ?? 'ID Yok', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                        ),
                        const Spacer(),
                        GlassIconButton(icon: Icons.flag_outlined, size: 40, onPressed: _handleReport, iconColor: AppColors.warning),
                    ],
                ),
            ),
        ),
    );
  }
  
  Widget _buildChatPanel() {
    if (_connectionId == null) {
        return GlassContainer(
            height: 300,
            child: const Center(child: Text('Bağlantı hatası: ID yok', style: TextStyle(color: Colors.white))),
        );
    }

    final repository = ref.watch(offlineChatRepositoryProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? 'unknown';
    
    return GlassContainer(
      height: 300,
      blurRadius: AppTheme.blurBottomSheet,
      borderRadius: 0,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: repository.watchMessages(_connectionId!, currentUserId),
              builder: (context, snapshot) {
                 if (snapshot.hasError) {
                     return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                 }
                 
                 final messages = snapshot.data ?? [];
                 
                 if (messages.isEmpty) {
                     return const Center(child: Text('Henüz mesaj yok', style: TextStyle(color: Colors.white30)));
                 }

                   return ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isLast = index == messages.length - 1 || 
                          messages[index + 1].senderId != message.senderId;
                      
                      return TelegramBubble(
                        text: message.content,
                        isOwn: message.senderId == currentUserId,
                        timestamp: message.createdAt,
                        showTail: isLast,
                        isRead: true,
                        onLongPress: () => HapticEngine.longPress(),
                      );
                    },
                  );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }
  
  Widget _buildChatInput() {
    return LiquidInputBar(
      controller: _chatController,
      hintText: 'Mesaj yaz...',
      onSend: _sendMessage,
      onVoice: () {
        HapticEngine.buttonPress();
        // TODO: Implement voice recording
      },
      onAttachment: () {
        HapticEngine.buttonPress();
        // TODO: Implement attachment picker
      },
    );
  }
  
  Widget _buildBottomControls() {
    return SafeArea(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isChatExpanded = !_isChatExpanded);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isChatExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_isChatExpanded ? 'Sohbeti Kapat' : 'Mesaj Gönder', style: AppTypography.caption1()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.glassDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GlassIconButton(icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded, onPressed: _toggleMic, isActive: _isMicOn),
                      GestureDetector(
                        onTap: _handleNext,
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))]),
                          child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      GlassIconButton(icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, onPressed: _toggleCamera, isActive: _isCameraOn),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isOwn;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isOwn,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: message.isOwn ? AppColors.buttonGradient : null,
          color: message.isOwn ? null : AppColors.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isOwn ? 18 : 4),
            bottomRight: Radius.circular(message.isOwn ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: AppTypography.body(),
        ),
      ),
    );
  }
}

class ReportBottomSheet extends StatelessWidget {
  const ReportBottomSheet({super.key});

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
          const SizedBox(height: 20),
          Text(
            'Kullanıcıyı Bildir',
            style: AppTypography.title2(),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kullanıcıyı neden bildirmek istiyorsunuz?',
            style: AppTypography.body(color: Colors.white.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          _ReportOption(
            icon: Icons.warning_rounded,
            title: 'Uygunsuz İçerik',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _ReportOption(
            icon: Icons.person_off_rounded,
            title: 'Taciz / Zorbalık',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _ReportOption(
            icon: Icons.speaker_notes_off_rounded,
            title: 'Spam / Reklam',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _ReportOption(
            icon: Icons.more_horiz_rounded,
            title: 'Diğer',
            onTap: () => Navigator.pop(context),
          ),
          
          const SizedBox(height: 24),
          SecondaryButton(
            text: 'İptal',
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  
  const _ReportOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.warning, size: 24),
            const SizedBox(width: 16),
            Text(title, style: AppTypography.body()),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
