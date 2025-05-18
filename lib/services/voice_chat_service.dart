import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceChatService extends GetxService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _isMuted = false.obs;
  final _isConnected = false.obs;
  final _error = Rx<String?>(null);

  bool get isMuted => _isMuted.value;
  bool get isConnected => _isConnected.value;
  String? get error => _error.value;

  Future<void> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize WebRTC
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      // Get local audio stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // Add local stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _isConnected.value = true;
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
      _isConnected.value = false;
    }
  }

  void toggleMute() {
    if (_localStream == null) return;

    _isMuted.value = !_isMuted.value;
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted.value;
    });
  }

  Future<void> connectToPeer(String peerId) async {
    if (_peerConnection == null) return;

    try {
      // Create and send offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send offer to signaling server
      // Implementation depends on your signaling server
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          answer['sdp'],
          answer['type'],
        ),
      );
    } catch (e) {
      _error.value = e.toString();
    }
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection == null) return;

    try {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      _error.value = e.toString();
    }
  }

  @override
  void onClose() {
    _localStream?.dispose();
    _peerConnection?.close();
    super.onClose();
  }
}
