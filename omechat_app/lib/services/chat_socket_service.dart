import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

/// WebSocket client for Authenticated Chat
class ChatSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  
  Stream<Map<String, dynamic>> get friendEvents => _messageController.stream
      .where((m) => m['type'] == 'FRIEND_REQUEST' || m['type'] == 'FRIEND_ACCEPTED');
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _serverUrl;
  String? _token;
  
  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  /// Connect to WebSocket server
  Future<void> connect(String baseUrl, String token) async {
    if (_isConnected) return;

    // http:// -> ws:// conversion
    final wsBaseUrl = baseUrl.replaceFirst('http', 'ws');
    _serverUrl = '$wsBaseUrl/ws/chat';
    _token = token;
    
    try {
      final uri = Uri.parse('$_serverUrl?token=$token');
      print('Chat WS Connecting to: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('Chat WS Connected');
      
    } catch (e) {
      print('Chat WS Connect Error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from server
  void disconnect() {
    print('Chat WS Disconnecting...');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
  
  void _onMessage(dynamic data) {
    try {
      print('Chat WS Received: $data');
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(message);
    } catch (e) {
      print('Chat WebSocket message parse error: $e');
    }
  }
  
  void _onError(dynamic error) {
    print('Chat WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }
  
  void _onDone() {
    print('Chat WebSocket closed');
    _isConnected = false;
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) return;
    if (_serverUrl == null || _token == null) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      print('Chat WS Reconnecting (Attempt ${_reconnectAttempts + 1})...');
      _reconnectAttempts++;
      final base = _serverUrl!.replaceAll('/ws/chat', '').replaceFirst('ws', 'http');
      connect(base, _token!);
    });
  }
  
  void dispose() {
    disconnect();
    _messageController.close();
  }
}

// Riverpod provider
final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final client = ChatSocketService();
  ref.onDispose(() => client.dispose());
  return client;
});
