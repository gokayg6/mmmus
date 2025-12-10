import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glowing_button.dart';

/// Video Chat Screen - Omegle-style video chat interface
/// Shows remote video full screen with PiP self-view
class VideoChatScreen extends StatefulWidget {
  const VideoChatScreen({super.key});

  @override
  State<VideoChatScreen> createState() => _VideoChatScreenState();
}

class _VideoChatScreenState extends State<VideoChatScreen>
    with TickerProviderStateMixin {
  
  // Connection state
  ConnectionState _connectionState = ConnectionState.idle;
  
  // Controls state
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isChatVisible = false;
  
  // Timer
  int _callDuration = 0;
  Timer? _timer;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // PiP position
  Offset _pipPosition = const Offset(16, 100);
  
  // Chat messages
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Auto start searching when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSearch();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSearch() {
    HapticFeedback.mediumImpact();
    setState(() => _connectionState = ConnectionState.searching);
    
    // Real app: WebSocket connection logic here
    // For now: Just stay in searching state
  }

  void _onConnected() {
    HapticFeedback.heavyImpact();
    setState(() => _connectionState = ConnectionState.connected);
    _startTimer();
    
    // Simulate receiving a message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _addMessage('Merhaba! 👋', false);
      }
    });
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    _stopTimer();
    setState(() {
      _connectionState = ConnectionState.searching;
      _messages.clear();
      _callDuration = 0;
    });
    
    // Real app: WebSocket "next" signal here
  }

  void _onStop() {
    HapticFeedback.lightImpact();
    _stopTimer();
    setState(() {
      _connectionState = ConnectionState.idle;
      _messages.clear();
      _callDuration = 0;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleCamera() {
    HapticFeedback.lightImpact();
    setState(() => _isCameraOn = !_isCameraOn);
  }

  void _toggleMic() {
    HapticFeedback.lightImpact();
    setState(() => _isMicOn = !_isMicOn);
  }

  void _toggleChat() {
    HapticFeedback.lightImpact();
    setState(() => _isChatVisible = !_isChatVisible);
  }

  void _showReport() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ReportSheet(
        onReport: (reason) {
          Navigator.pop(context);
          _onNext(); // Move to next after reporting
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bildirim gönderildi', style: AppTypography.body()),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _addMessage(String text, bool isMe) {
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: isMe, time: DateTime.now()));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _addMessage(_chatController.text.trim(), true);
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Remote video / placeholder
          _buildRemoteVideo(),
          
          // Top bar
          _buildTopBar(),
          
          // PiP self-view
          if (_connectionState == ConnectionState.connected)
            _buildPipView(),
          
          // Center content (searching/idle)
          if (_connectionState != ConnectionState.connected)
            _buildCenterContent(),
          
          // Chat overlay
          if (_isChatVisible && _connectionState == ConnectionState.connected)
            _buildChatOverlay(),
          
          // Bottom control bar
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_connectionState == ConnectionState.connected) {
      // Placeholder for remote video
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: 120,
            color: AppColors.textMuted.withOpacity(0.3),
          ),
        ),
      );
    }
    return Container(color: AppColors.background);
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
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
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Status
                Expanded(
                  child: Text(
                    _getStatusText(),
                    style: AppTypography.headline(),
                  ),
                ),
                
                // Timer (when connected)
                if (_connectionState == ConnectionState.connected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_callDuration),
                          style: AppTypography.caption1(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(width: 12),
                
                // Online count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.online.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '2.5k',
                        style: AppTypography.caption1(color: AppColors.online),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_connectionState) {
      case ConnectionState.idle:
        return 'Keşfet';
      case ConnectionState.searching:
        return 'Aranıyor...';
      case ConnectionState.connected:
        return 'Bağlandı';
    }
  }

  Widget _buildPipView() {
    return Positioned(
      right: _pipPosition.dx,
      top: _pipPosition.dy + MediaQuery.of(context).padding.top + 60,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _pipPosition += details.delta;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            color: _isCameraOn ? const Color(0xFF2a2a4e) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                if (_isCameraOn)
                  Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          size: 28,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kamera Kapalı',
                          style: AppTypography.caption2(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                
                // Mic indicator
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isMicOn ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_connectionState == ConnectionState.searching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing loader
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Birisi aranıyor...', style: AppTypography.title2()),
            const SizedBox(height: 8),
            Text(
              'Lütfen bekleyin',
              style: AppTypography.body(color: context.colors.textSecondaryColor),
            ),
          ],
        ),
      );
    }
    
    // Idle state - show start button
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlowingButton(
            size: 140,
            showPulse: true,
            onPressed: _startSearch,
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text('Sohbet Başlat', style: AppTypography.title2()),
          const SizedBox(height: 8),
          Text(
            'Yeni insanlarla tanış',
            style: AppTypography.body(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('Sohbet', style: AppTypography.headline()),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleChat,
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
                
                // Input
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: AppTypography.body(),
                            decoration: InputDecoration(
                              hintText: 'Mesaj yaz...',
                              hintStyle: AppTypography.body(color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          gradient: message.isMe ? AppGradients.bubbleSent : null,
          color: message.isMe ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: message.isMe ? null : Border.all(color: AppColors.borderSoft),
        ),
        child: Text(
          message.text,
          style: AppTypography.body(
            color: message.isMe ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera toggle
                _buildControlButton(
                  icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  isActive: _isCameraOn,
                  onTap: _toggleCamera,
                ),
                
                // Mic toggle
                _buildControlButton(
                  icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  isActive: _isMicOn,
                  onTap: _toggleMic,
                ),
                
                // Next / Start button
                if (_connectionState == ConnectionState.connected)
                  GlowingButton(
                    size: 64,
                    onPressed: _onNext,
                    child: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  )
                else if (_connectionState == ConnectionState.searching)
                  _buildControlButton(
                    icon: Icons.close_rounded,
                    isActive: false,
                    isDestructive: true,
                    onTap: _onStop,
                  ),
                
                // Chat toggle
                _buildControlButton(
                  icon: Icons.chat_bubble_rounded,
                  isActive: _isChatVisible,
                  onTap: _connectionState == ConnectionState.connected ? _toggleChat : null,
                  isDisabled: _connectionState != ConnectionState.connected,
                ),
                
                // Report
                _buildControlButton(
                  icon: Icons.flag_rounded,
                  isActive: false,
                  isDestructive: true,
                  onTap: _connectionState == ConnectionState.connected ? _showReport : null,
                  isDisabled: _connectionState != ConnectionState.connected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surface.withOpacity(0.5)
              : isDestructive
                  ? AppColors.error.withOpacity(0.2)
                  : isActive
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDisabled
                ? Colors.transparent
                : isDestructive
                    ? AppColors.error.withOpacity(0.5)
                    : isActive
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.borderSoft,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? AppColors.textMuted
              : isDestructive
                  ? AppColors.error
                  : isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

/// Connection state enum
enum ConnectionState {
  idle,
  searching,
  connected,
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  
  ChatMessage({required this.text, required this.isMe, required this.time});
}

/// Report bottom sheet
class _ReportSheet extends StatelessWidget {
  final Function(String) onReport;
  
  const _ReportSheet({required this.onReport});

  @override
  Widget build(BuildContext context) {
    final reasons = [
      ('Müstehcen İçerik', Icons.no_adult_content_rounded),
      ('Taciz / Hakaret', Icons.person_off_rounded),
      ('Spam / Reklam', Icons.block_rounded),
      ('Bot / Sahte Hesap', Icons.smart_toy_rounded),
      ('Diğer', Icons.more_horiz_rounded),
    ];
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Sorunu Bildir', style: AppTypography.title2()),
              const SizedBox(height: 16),
              ...reasons.map((r) => ListTile(
                leading: Icon(r.$2, color: AppColors.error),
                title: Text(r.$1, style: AppTypography.body()),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () => onReport(r.$1),
              )),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
