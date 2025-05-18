import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import 'package:crazygame/models/game_state.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final _gameState = Rx<GameState?>(null);
  final _isConnected = false.obs;
  final _error = Rx<String?>(null);

  GameState? get gameState => _gameState.value;
  bool get isConnected => _isConnected.value;
  String? get error => _error.value;

  Future<void> connect(String roomId) async {
    try {
      final wsUrl = Uri.parse('wss://your-backend-url.com/game/$roomId');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          _gameState.value = GameState.fromJson(data);
        },
        onError: (error) {
          _error.value = error.toString();
          _isConnected.value = false;
        },
        onDone: () {
          _isConnected.value = false;
        },
      );

      _isConnected.value = true;
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
      _isConnected.value = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected.value = false;
  }

  void playCard(Card card) {
    if (!_isConnected.value || _channel == null) return;

    _channel!.sink.add(json.encode({
      'type': 'play_card',
      'card': card.toJson(),
    }));
  }

  void undoPlayCard() {
    if (!_isConnected.value || _channel == null) return;

    _channel!.sink.add(json.encode({
      'type': 'undo_play_card',
    }));
  }

  void drawCard() {
    if (!_isConnected.value || _channel == null) return;

    _channel!.sink.add(json.encode({
      'type': 'draw_card',
    }));
  }

  void sendChatMessage(String message) {
    if (!_isConnected.value || _channel == null) return;

    _channel!.sink.add(json.encode({
      'type': 'chat_message',
      'message': message,
    }));
  }

  void toggleVoiceChat(bool isEnabled) {
    if (!_isConnected.value || _channel == null) return;

    _channel!.sink.add(json.encode({
      'type': 'voice_chat',
      'enabled': isEnabled,
    }));
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
