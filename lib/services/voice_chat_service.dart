import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class VoiceChatService extends GetxService {
  final _localStream = webrtc.RTCVideoRenderer();
  final _remoteStream = webrtc.RTCVideoRenderer();
  WebSocketChannel? _channel;
  webrtc.RTCPeerConnection? _peerConnection;
  final _isConnected = false.obs;
  final _isMuted = false.obs;
  final _isSpeakerOn = true.obs;
  final _error = Rx<String?>(null);

  bool get isMuted => _isMuted.value;
  bool get isConnected => _isConnected.value;
  String? get error => _error.value;

  Future<void> initialize() async {
    await _localStream.initialize();
    await _remoteStream.initialize();
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  Future<void> connect(String roomId) async {
    try {
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      _peerConnection = await webrtc.createPeerConnection(configuration);

      _peerConnection?.onIceCandidate = (candidate) {
        _channel?.sink.add({
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      };

      _peerConnection?.onTrack = (event) {
        if (event.track.kind == 'video') {
          _remoteStream.srcObject = event.streams[0];
        }
      };

      final stream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      _localStream.srcObject = stream;
      stream.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, stream);
      });

      _channel = WebSocketChannel.connect(
        Uri.parse('wss://your-signaling-server.com/$roomId'),
      );

      _channel?.stream.listen((message) {
        _handleSignalingMessage(message);
      });

      _isConnected.value = true;
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
      _isConnected.value = false;
    }
  }

  Future<void> connectToPeer(String peerId) async {
    if (!_isConnected.value || _peerConnection == null) return;

    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      _channel?.sink.add(json.encode({
        'type': 'offer',
        'peerId': peerId,
        'sdp': offer.sdp,
      }));

      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void _handleSignalingMessage(dynamic message) {
    // Handle signaling messages
  }

  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    _localStream.srcObject?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted.value;
    });
  }

  void toggleSpeaker() {
    _isSpeakerOn.value = !_isSpeakerOn.value;
    // Implement speaker toggle logic
  }

  Future<void> disconnect() async {
    await _localStream.dispose();
    await _remoteStream.dispose();
    await _peerConnection?.close();
    _channel?.sink.close();
    _isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
