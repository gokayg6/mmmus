import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/haptics/haptic_engine.dart';
import '../chat/widgets/telegram_style_widgets.dart';
import '../../services/dummy_data_service.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  // We can fetch user details from DummyDataService using userId if needed
  // For now we assume we might need to lookup user info
  
  const ChatDetailScreen({
    super.key, 
    required this.userId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  
  bool _isTyping = false;
  
  // Local Chat State
  List<Map<String, dynamic>> _messages = [];
  Map<String, String>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadDummyMessages();
    
    // Simulate other user typing occasionally
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isTyping = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isTyping = false);
      });
    });
  }
  
  void _loadDummyMessages() {
    // Generate some random messages for this session
    final texts = [
      "Merhaba, nasılsın?",
      "Projeyi bitirdin mi?",
      "Akşam buluşuyor muyuz?",
      "Evet, kesinlikle!",
      "Harika görünüyor 🔥",
      "Tamamdır, haberleşiriz.",
      "Görüşürüz 👋"
    ];
    
    _messages = List.generate(15, (index) {
      final isOwn = _random.nextBool();
      return {
        'text': texts[_random.nextInt(texts.length)],
        'isOwn': isOwn,
        'time': DateTime.now().subtract(Duration(minutes: index * 10)),
        'isRead': true,
      };
    }).reversed.toList();
    
    // Find user info from dummy service just for display
    // In a real app we'd fetch from ID. Here we just mock it.
    _currentUser = {
      'name': 'User ${widget.userId}', 
      'avatar': 'https://i.pravatar.cc/150?u=${widget.userId}'
    };
  }
  
  void _sendMessage() {
    final text = _messageController.text;
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': text,
        'isOwn': true,
        'time': DateTime.now(),
        'isRead': false,
      });
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Simulate reply
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _messages.add({
                'text': "Buna şu an cevap veremem ama çok iyi fikir! 👍",
                'isOwn': false,
                'time': DateTime.now(),
                'isRead': true,
              });
            });
            _scrollToBottom();
            HapticFeedback.lightImpact();
          }
        });
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Black background
      // --- CUSTOM APP BAR ---
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.95), // Semi-transparent black
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_currentUser?['avatar'] ?? ''),
              radius: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?['name'] ?? 'Chat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _isTyping ? 'typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12, 
                    color: _isTyping ? AppColors.primary : AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white10, height: 1),
        ),
      ),
      
      // --- BODY ---
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                
                // Show date separator occasionally
                if (index == 0) {
                  return Column(
                    children: [
                      TelegramDateSeparator(date: DateTime.now()),
                      TelegramBubble(
                        text: msg['text'],
                        isOwn: msg['isOwn'],
                        timestamp: msg['time'],
                        isRead: msg['isRead'],
                      ),
                    ],
                  );
                }
                
                return TelegramBubble(
                  text: msg['text'],
                  isOwn: msg['isOwn'],
                  timestamp: msg['time'],
                  isRead: msg['isRead'],
                );
              },
            ),
          ),
          
          if (_isTyping)
            TelegramTypingIndicator(username: _currentUser?['name'] ?? 'User'),
            
          // --- INPUT BAR ---
          TelegramInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            onVoice: () {},
            onAttachment: () {},
            onEmoji: () {},
          ),
        ],
      ),
    );
  }
}
