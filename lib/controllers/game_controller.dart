import 'package:get/get.dart';
import 'package:crazygame/models/game_state.dart';
import 'package:crazygame/services/websocket_service.dart';
import 'package:crazygame/services/voice_chat_service.dart';
import 'package:crazygame/models/game_event.dart';

class GameController extends GetxController {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final VoiceChatService _voiceService = Get.find<VoiceChatService>();

  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _chatMessages = <String>[].obs;
  final _isVoiceChatEnabled = false.obs;
  final _isReconnecting = false.obs;

  // Game settings
  final RxBool _isSoundEnabled = true.obs;
  final RxBool _isMusicEnabled = true.obs;
  final RxBool _isVibrationEnabled = true.obs;
  final RxBool _isAutoPlayEnabled = false.obs;
  final RxInt _turnTimeLimit = 60.obs;
  final RxDouble _gameSpeed = 1.0.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<String> get chatMessages => _chatMessages;
  bool get isVoiceChatEnabled => _isVoiceChatEnabled.value;
  bool get isReconnecting => _isReconnecting.value;
  GameState? get gameState => _wsService.gameState;
  bool get isConnected => _wsService.isConnected;

  // Getters for settings
  bool get isSoundEnabled => _isSoundEnabled.value;
  bool get isMusicEnabled => _isMusicEnabled.value;
  bool get isVibrationEnabled => _isVibrationEnabled.value;
  bool get isAutoPlayEnabled => _isAutoPlayEnabled.value;
  int get turnTimeLimit => _turnTimeLimit.value;
  double get gameSpeed => _gameSpeed.value;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    ever(_wsService.error, _handleWebSocketError);
  }

  void _handleWebSocketError(String? error) {
    if (error != null) {
      _error.value = error;
      if (error.contains('Failed to connect after')) {
        _isReconnecting.value = false;
      } else if (error.contains('Connection closed')) {
        _isReconnecting.value = true;
      }
    }
  }

  void clearError() {
    _error.value = null;
  }

  Future<void> _initializeServices() async {
    try {
      _isLoading.value = true;
      await _voiceService.initialize();
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> joinGame(String roomId) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await _wsService.connect(roomId);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  void playCard(Card card) {
    try {
      _wsService.playCard(card);
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void undoPlayCard() {
    try {
      _wsService.undoPlayCard();
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void drawCard() {
    try {
      _wsService.drawCard();
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void sendChatMessage(String message) {
    try {
      _wsService.sendChatMessage(message);
      _chatMessages.add(message);
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void toggleVoiceChat() {
    try {
      _isVoiceChatEnabled.value = !_isVoiceChatEnabled.value;
      _wsService.toggleVoiceChat(_isVoiceChatEnabled.value);

      if (_isVoiceChatEnabled.value) {
        _voiceService.connectToPeer(gameState?.currentPlayerId ?? '');
      }

      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void toggleMute() {
    try {
      _voiceService.toggleMute();
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    }
  }

  void retryConnection() {
    if (gameState != null) {
      joinGame(gameState!.roomId);
    }
  }

  // Settings methods
  void toggleSound(bool value) {
    _isSoundEnabled.value = value;
    _saveSettings();
  }

  void toggleMusic(bool value) {
    _isMusicEnabled.value = value;
    _saveSettings();
  }

  void toggleVibration(bool value) {
    _isVibrationEnabled.value = value;
    _saveSettings();
  }

  void toggleAutoPlay(bool value) {
    _isAutoPlayEnabled.value = value;
    _saveSettings();
  }

  void setTurnTimeLimit(int? value) {
    if (value != null) {
      _turnTimeLimit.value = value;
      _saveSettings();
    }
  }

  void setGameSpeed(double value) {
    _gameSpeed.value = value;
    _saveSettings();
  }

  void resetSettings() {
    _isSoundEnabled.value = true;
    _isMusicEnabled.value = true;
    _isVibrationEnabled.value = true;
    _isAutoPlayEnabled.value = false;
    _turnTimeLimit.value = 60;
    _gameSpeed.value = 1.0;
    _saveSettings();
  }

  void saveSettings() {
    _saveSettings();
  }

  void _saveSettings() {
    // TODO: Implement settings persistence
    // This could be done using shared_preferences or a local database
  }

  // Game history
  final RxList<GameEvent> _gameHistory = <GameEvent>[].obs;
  List<GameEvent> get gameHistory => _gameHistory;

  void addGameEvent(GameEvent event) {
    _gameHistory.insert(0, event);
    if (_gameHistory.length > 100) {
      _gameHistory.removeLast();
    }
  }

  @override
  void onClose() {
    _wsService.disconnect();
    super.onClose();
  }
}
