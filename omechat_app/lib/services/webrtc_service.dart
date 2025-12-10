import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

/// WebRTC service for managing peer connections
class WebRTCService {
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  
  List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];
  
  // Callbacks
  Function(webrtc.MediaStream)? onLocalStream;
  Function(webrtc.MediaStream)? onRemoteStream;
  Function(webrtc.RTCIceCandidate)? onIceCandidate;
  Function(String)? onConnectionStateChange;
  
  /// Set ICE servers from backend config
  void setIceServers(List<Map<String, dynamic>> servers) {
    _iceServers = servers;
  }
  
  /// Initialize local media stream
  Future<void> initLocalStream({
    bool video = true,
    bool audio = true,
  }) async {
    final mediaConstraints = {
      'audio': audio,
      'video': video ? {
        'facingMode': 'user',
        'width': {'ideal': 640}, // Mobile friendly resolution
        'height': {'ideal': 480},
      } : false,
    };
    
    try {
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      print('Local stream initialized: ${_localStream?.id}');
      onLocalStream?.call(_localStream!);
    } catch (e) {
      print('Error accessing media devices: $e');
      rethrow;
    }
  }
  
  /// Create peer connection
  Future<void> createPeerConnection() async {
    final configuration = {
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    };
    
    print('Creating PeerConnection with config: $configuration');
    _peerConnection = await webrtc.createPeerConnection(configuration);
    
    // Add local stream tracks
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
    
    // Listen for remote stream
    _peerConnection!.onTrack = (event) {
      print('Track received: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };
    
    // Listen for ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      print('New ICE candidate: ${candidate.candidate?.substring(0, 20)}...');
      onIceCandidate?.call(candidate);
    };
    
    // Listen for connection state changes
    _peerConnection!.onConnectionState = (state) {
      print('Connection state change: ${state.name}');
      onConnectionStateChange?.call(state.name);
    };
  }
  
  /// Create offer (for initiator)
  Future<webrtc.RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) await createPeerConnection();
    
    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      print('Offer created: ${offer.sdp?.substring(0, 50)}...');
      return offer;
    } catch (e) {
      print('Error creating offer: $e');
      rethrow;
    }
  }
  
  /// Create answer (for non-initiator)
  Future<webrtc.RTCSessionDescription> createAnswer() async {
    // Note: PeerConnection should already be created before calling createAnswer
    if (_peerConnection == null) await createPeerConnection(); // Safeguard
    
    try {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      print('Answer created: ${answer.sdp?.substring(0, 50)}...');
      return answer;
    } catch (e) {
      print('Error creating answer: $e');
      rethrow;
    }
  }
  
  /// Set remote description
  Future<void> setRemoteDescription(String sdp, String type) async {
    if (_peerConnection == null) await createPeerConnection();
    
    try {
      final description = webrtc.RTCSessionDescription(sdp, type);
      await _peerConnection!.setRemoteDescription(description);
      print('Remote description set: $type');
    } catch (e) {
      print('Error setting remote description: $e');
      rethrow;
    }
  }
  
  /// Add ICE candidate
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection == null) return;
    
    try {
      final candidate = webrtc.RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
      print('ICE candidate added');
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }
  
  /// Toggle camera
  void toggleCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }
  
  /// Toggle microphone
  void toggleMicrophone(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }
  
  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await webrtc.Helper.switchCamera(videoTracks[0]);
      }
    }
  }
  
  /// Close connection and release resources
  Future<void> dispose() async {
    print('Disposing WebRTC service...');
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
  }
  
  // Getters
  webrtc.MediaStream? get localStream => _localStream;
  webrtc.MediaStream? get remoteStream => _remoteStream;
  webrtc.RTCPeerConnection? get peerConnection => _peerConnection;
}

// Riverpod provider
final webRTCServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});
