import 'package:get/get.dart';
import 'package:crazygame/models/game_state.dart';
import 'package:crazygame/services/websocket_service.dart';
import 'package:crazygame/services/voice_chat_service.dart';

class GameController extends GetxController {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final VoiceChatService _voiceService = Get.find<VoiceChatService>();

  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _chatMessages = <String>[].obs;
  final _isVoiceChatEnabled = false.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<String> get chatMessages => _chatMessages;
  bool get isVoiceChatEnabled => _isVoiceChatEnabled.value;
  GameState? get gameState => _wsService.gameState;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
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
      await _wsService.connect(roomId);
      _error.value = null;
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

  @override
  void onClose() {
    _wsService.disconnect();
    super.onClose();
  }
}
