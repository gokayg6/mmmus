import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/tv_static_effect.dart';
import '../../services/webrtc_service.dart';
import '../../services/websocket_client.dart';
import '../../services/api_client.dart';

/// Video Chat Screen - Omegle-style video chat with real WebRTC
class VideoChatScreen extends ConsumerStatefulWidget {
  final bool startConnected;
  
  const VideoChatScreen({super.key, this.startConnected = false});

  @override
  ConsumerState<VideoChatScreen> createState() => _VideoChatScreenState();
}

class _VideoChatScreenState extends ConsumerState<VideoChatScreen>
    with TickerProviderStateMixin {
  
  bool _isSearching = false;
  bool _isConnected = false;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _showChat = false;
  bool _isConnecting = false;
  
  int _callDuration = 0;
  Timer? _timer;
  
  late AnimationController _pulseController;
  
  final List<_ChatMsg> _messages = [];
  final _chatController = TextEditingController();
  
  // WebRTC
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  StreamSubscription? _wsSubscription;
  String? _connectionId;
  bool _isInitiator = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _initRenderers();
    
    if (widget.startConnected) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _startRealConnection();
      });
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    _chatController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    ref.read(webRTCServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _startRealConnection() async {
    // Request permissions first
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera ve mikrofon izni gereklidir'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _isSearching = false;
    });
    
    try {
      final webrtc = ref.read(webRTCServiceProvider);
      final ws = ref.read(webSocketClientProvider);
      
      // Setup stream handlers
      webrtc.onLocalStream = (stream) {
        _localRenderer.srcObject = stream;
        if (mounted) setState(() {});
      };
      
      webrtc.onRemoteStream = (stream) {
        _remoteRenderer.srcObject = stream;
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConnected = true;
            _callDuration = 0;
          });
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _callDuration++);
          });
        }
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
          if (mounted) {
            setState(() => _isConnected = false);
          }
        }
      };
      
      // Get ICE servers from session first
      final apiClient = ref.read(apiClientProvider);
      List<Map<String, dynamic>> iceServers = [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ];
      
      try {
        final sessionResponse = await apiClient.startSession(deviceType: 'ANDROID');
        iceServers = sessionResponse.iceServers;
        webrtc.setIceServers(iceServers);
      } catch (e) {
        print('Using default ICE servers: $e');
        webrtc.setIceServers(iceServers);
      }
      
      // Initialize local stream AFTER setting ICE servers
      await webrtc.initLocalStream(video: true, audio: true);
      
      // Create peer connection immediately
      await webrtc.createPeerConnection();
      
      // WebSocket listener for signaling
      _wsSubscription = ws.messages.listen((message) async {
        final type = message['type'];
        
        switch (type) {
          case 'MATCH_FOUND':
            _connectionId = message['connection_id'] as String?;
            _isInitiator = message['is_initiator'] as bool? ?? false;
            
            // Peer connection should already be created
            if (webrtc.peerConnection == null) {
              await webrtc.createPeerConnection();
            }
            
            if (_isInitiator) {
              final offer = await webrtc.createOffer();
              if (_connectionId != null && offer.sdp != null) {
                ws.sendOffer(_connectionId!, offer.sdp!);
              }
            }
            break;
            
          case 'OFFER':
            await webrtc.setRemoteDescription(message['sdp'], 'offer');
            final answer = await webrtc.createAnswer();
            if (_connectionId != null) {
              ws.sendAnswer(_connectionId!, answer.sdp!);
            }
            break;
            
          case 'ANSWER':
            await webrtc.setRemoteDescription(message['sdp'], 'answer');
            break;
            
          case 'ICE_CANDIDATE':
            await webrtc.addIceCandidate(message['candidate']);
            break;
            
          case 'CHAT_MESSAGE':
            if (mounted) {
              setState(() {
                _messages.add(_ChatMsg(message['text'] ?? '', false));
              });
            }
            break;
            
          case 'MATCH_ENDED':
            _handleMatchEnded();
            break;
        }
      });
      
    } catch (e) {
      print('Connection error: $e');
      if (mounted) {
        setState(() {
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
  
  void _handleMatchEnded() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _messages.clear();
      });
      Navigator.pop(context);
    }
  }

  void _next() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    ref.read(webSocketClientProvider).next();
    _handleMatchEnded();
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
  
  void _sendMsg() {
    if (_chatController.text.trim().isEmpty || _connectionId == null) return;
    
    final text = _chatController.text.trim();
    final ws = ref.read(webSocketClientProvider);
    ws.sendChatMessage(_connectionId!, text);
    
    setState(() {
      _messages.add(_ChatMsg(text, true));
      _chatController.clear();
    });
  }
  
  void _addFriend() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arkadaş eklendi!'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implement add friend API call
  }

  void _stop() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Show TV static when searching
    if (_isSearching) {
      return Scaffold(
        backgroundColor: context.colors.backgroundColor,
        body: OmegleTvStaticEffect(
          isSearching: true,
          onSkip: _stop,
          statusText: 'Birisi aranıyor',
        ),
      );
    }
    
    // Connected view
    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                
                // Center - Remote video placeholder
                Expanded(child: _buildRemoteView()),
                
                // Bottom controls
                _buildControls(),
              ],
            ),
          ),
          
          // Self view (PiP)
          if (_isConnected) _buildSelfView(),
          
          // Chat overlay
          if (_showChat) _buildChatOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.7, -0.5),
              radius: 1.5,
              colors: [
                AppColors.primary.withOpacity(0.15 * pulse),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, 0.8),
                radius: 1.2,
                colors: [
                  AppColors.primary.withOpacity(0.1 * (1 - pulse)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: _stop,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: context.colors.textColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.videocam, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('OmeChat', style: TextStyle(color: context.colors.textColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Add Friend button (sağ üst köşe)
            if (_isConnected)
              GestureDetector(
                onTap: _addFriend,
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                ),
              ),
            
            // Timer
            if (_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatTime(_callDuration), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteView() {
    if (_isConnected && _remoteRenderer.srcObject != null) {
      // Show real remote video
      return RTCVideoView(
        _remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: false,
      );
    }
    
    // Show connecting/searching animation
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing rings
              Stack(
                alignment: Alignment.center,
                children: [
                  // Ring 3
                  Transform.scale(
                    scale: 1.0 + pulse * 0.15,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                      ),
                    ),
                  ),
                  // Ring 2
                  Transform.scale(
                    scale: 1.0 + pulse * 0.1,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
                      ),
                    ),
                  ),
                  // Ring 1
                  Transform.scale(
                    scale: 1.0 + pulse * 0.05,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                      ),
                    ),
                  ),
                  // Avatar
                  Builder(
                    builder: (context) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.25),
                            AppColors.primary.withOpacity(0.1),
                            context.colors.surfaceColor,
                          ],
                        ),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5 + pulse * 0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3 * pulse),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(Icons.person, size: 50, color: context.colors.textMutedColor),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 28),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Yabancı',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Connection quality
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.signal_cellular_alt, color: Colors.green.withOpacity(0.8), size: 16),
                  const SizedBox(width: 6),
                  Text('İyi bağlantı', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera
          _controlBtn(
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
            label: 'Kamera',
            active: _isCameraOn,
            onTap: _toggleCamera,
          ),
          
          // Mic
          _controlBtn(
            icon: _isMicOn ? Icons.mic : Icons.mic_off,
            label: 'Mikrofon',
            active: _isMicOn,
            onTap: _toggleMic,
          ),
          
          // Next button
          GestureDetector(
            onTap: _next,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20)],
              ),
              child: const Icon(Icons.skip_next, color: Colors.white, size: 36),
            ),
          ),
          
          // Chat
          _controlBtn(
            icon: Icons.chat_bubble,
            label: 'Sohbet',
            active: _showChat,
            onTap: () => setState(() => _showChat = !_showChat),
          ),
          
          // Report
          _controlBtn(
            icon: Icons.flag,
            label: 'Bildir',
            active: false,
            danger: true,
            onTap: _showReportSheet,
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool active,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final color = danger ? Colors.red : (active ? AppColors.primary : Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (danger ? Colors.red : (active ? AppColors.primary : Colors.white)).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color.withOpacity(active || danger ? 1 : 0.7), size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSelfView() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 80,
      child: Container(
        width: 110,
        height: 150,
        decoration: BoxDecoration(
          color: _isCameraOn ? const Color(0xFF1A1A2A) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 15),
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Real local video or placeholder
              if (_isCameraOn && _localRenderer.srcObject != null)
                SizedBox.expand(
                  child: RTCVideoView(
                    _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: true,
                  ),
                )
              else
                Center(
                  child: _isCameraOn
                      ? const Icon(Icons.person, size: 40, color: Colors.white38)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_off, size: 28, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(height: 4),
                            Text('Kapalı', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                          ],
                        ),
                ),
              // "Sen" label
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Sen', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
              // Mic indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _isMicOn ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_isMicOn ? Icons.mic : Icons.mic_off, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('Sohbet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showChat = false),
                        child: const Icon(Icons.close, color: Colors.white54, size: 22),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _msgBubble(_messages[i]),
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
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Mesaj yaz...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMsg(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMsg,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _msgBubble(_ChatMsg msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: msg.isMe ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]) : null,
          color: msg.isMe ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Sorunu Bildir', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ...['Müstehcen İçerik', 'Taciz / Hakaret', 'Spam', 'Diğer'].map((r) => ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text(r, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _next();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Bildirim gönderildi'), backgroundColor: Colors.green),
                );
              },
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isMe;
  _ChatMsg(this.text, this.isMe);
}
