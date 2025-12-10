import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket connection state
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// WebSocket client for signaling
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<ConnectionState>.broadcast();
  
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<ConnectionState> get state => _stateController.stream;
  
  ConnectionState _currentState = ConnectionState.disconnected;
  ConnectionState get currentState => _currentState;
  
  String? _sessionToken;
  String? _serverUrl;
  
  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  /// Connect to WebSocket server
  Future<void> connect(String baseUrl, String sessionToken) async {
    // http:// -> ws:// conversion
    final wsBaseUrl = baseUrl.replaceFirst('http', 'ws');
    _serverUrl = '$wsBaseUrl/ws/signaling';
    _sessionToken = sessionToken;
    
    _updateState(ConnectionState.connecting);
    
    try {
      final uri = Uri.parse('$_serverUrl?session_token=$sessionToken');
      print('WS Connecting to: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      
    } catch (e) {
      print('WS Connect Error: $e');
      _updateState(ConnectionState.error);
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from server
  void disconnect() {
    print('WS Disconnecting...');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateState(ConnectionState.disconnected);
  }
  
  /// Send a message to the server
  void send(Map<String, dynamic> message) {
    if (_currentState != ConnectionState.connected) {
      print('WS Send Failed: Not connected');
      return;
    }
    
    try {
      final jsonStr = jsonEncode(message);
      // print('WS sending: $jsonStr');
      _channel?.sink.add(jsonStr);
    } catch (e) {
      print('WebSocket send error: $e');
    }
  }
  
  /// Join matchmaking queue
  void joinQueue() {
    send({'type': 'JOIN_QUEUE'});
  }
  
  /// Leave matchmaking queue
  void leaveQueue() {
    send({'type': 'LEAVE_QUEUE'});
  }
  
  /// Request next partner
  void next() {
    send({'type': 'NEXT'});
  }
  
  /// Send WebRTC offer
  void sendOffer(String connectionId, String sdp) {
    send({
      'type': 'OFFER',
      'connectionId': connectionId,
      'sdp': sdp,
    });
  }
  
  /// Send WebRTC answer
  void sendAnswer(String connectionId, String sdp) {
    send({
      'type': 'ANSWER',
      'connectionId': connectionId,
      'sdp': sdp,
    });
  }
  
  /// Send ICE candidate
  void sendIceCandidate(String connectionId, Map<String, dynamic> candidate) {
    send({
      'type': 'ICE_CANDIDATE',
      'connectionId': connectionId,
      'candidate': candidate,
    });
  }
  
  /// Send chat message
  void sendChatMessage(String connectionId, String text) {
    send({
      'type': 'CHAT_MESSAGE',
      'connectionId': connectionId,
      'text': text,
    });
  }
  
  void _onMessage(dynamic data) {
    try {
      // print('WS Received: $data');
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(message);
    } catch (e) {
      print('WebSocket message parse error: $e');
    }
  }
  
  void _onError(dynamic error) {
    print('WebSocket error: $error');
    _updateState(ConnectionState.error);
    _scheduleReconnect();
  }
  
  void _onDone() {
    print('WebSocket closed');
    _updateState(ConnectionState.disconnected);
    // Don't reconnect if explicitly disconnected or permanent close?
    // For now simple reconnect logic
    if (_reconnectAttempts < maxReconnectAttempts) {
        _scheduleReconnect();
    }
  }
  
  void _updateState(ConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) return;
    if (_serverUrl == null || _sessionToken == null) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      print('WS Reconnecting (Attempt ${_reconnectAttempts + 1})...');
      _reconnectAttempts++;
      // Re-use connect logic
      final base = _serverUrl!.replaceAll('/ws/signaling', '').replaceFirst('ws', 'http');
      connect(base, _sessionToken!);
    });
  }
  
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}

// Riverpod provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(() => client.dispose());
  return client;
});
