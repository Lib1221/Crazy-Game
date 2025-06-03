import 'dart:async';
import 'dart:convert';
import 'package:crazygame/models/card.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import 'package:crazygame/models/game_state.dart';
import 'package:crazygame/config/app_config.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final _gameState = Rx<GameState?>(null);
  final _isConnected = false.obs;
  final _error = Rx<String?>(null);
  final _reconnectAttempts = 0.obs;
  Timer? _reconnectTimer;
  String? _currentRoomId;

  GameState? get gameState => _gameState.value;
  bool get isConnected => _isConnected.value;
  Rx<String?> get error => _error;

  Future<void> connect(String roomId) async {
    _currentRoomId = roomId;
    await _connect();
  }

  Future<void> _connect() async {
    if (_currentRoomId == null) return;

    try {
      final wsUrl = Uri.parse(AppConfig.getGameWebSocketUrl(_currentRoomId!));
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _gameState.value = GameState.fromJson(data);
            _error.value = null;
            _reconnectAttempts.value = 0;
          } catch (e) {
            _error.value = 'Failed to parse game state: ${e.toString()}';
          }
        },
        onError: (error) {
          _handleConnectionError(error.toString());
        },
        onDone: () {
          _handleConnectionError('Connection closed');
        },
      );

      _isConnected.value = true;
      _error.value = null;
      _reconnectAttempts.value = 0;
    } catch (e) {
      _handleConnectionError(e.toString());
    }
  }

  void _handleConnectionError(String errorMessage) {
    _error.value = errorMessage;
    _isConnected.value = false;

    if (_reconnectAttempts.value < AppConfig.reconnectAttempts) {
      _reconnectAttempts.value++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(AppConfig.reconnectDelay, _connect);
    } else {
      _error.value =
          'Failed to connect after ${AppConfig.reconnectAttempts} attempts';
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected.value = false;
    _currentRoomId = null;
    _reconnectAttempts.value = 0;
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (!_isConnected.value || _channel == null) {
      _error.value = 'Not connected to game server';
      return;
    }

    try {
      _channel!.sink.add(json.encode(message));
    } catch (e) {
      _error.value = 'Failed to send message: ${e.toString()}';
    }
  }

  void playCard(Card card) {
    _sendMessage({
      'type': 'play_card',
      'card': card.toJson(),
    });
  }

  void undoPlayCard() {
    _sendMessage({
      'type': 'undo_play_card',
    });
  }

  void drawCard() {
    _sendMessage({
      'type': 'draw_card',
    });
  }

  void sendChatMessage(String message) {
    _sendMessage({
      'type': 'chat_message',
      'message': message,
    });
  }

  void toggleVoiceChat(bool isEnabled) {
    _sendMessage({
      'type': 'voice_chat',
      'enabled': isEnabled,
    });
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
