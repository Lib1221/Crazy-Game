import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'database_service.dart';
import 'game_service.dart';
import 'user_service.dart';

class RealtimeChatService {
  static final RealtimeChatService _instance = RealtimeChatService._internal();
  factory RealtimeChatService() => _instance;

  final DatabaseService _databaseService;
  final AuthService _authService;
  final UserService _userService;
  late ChatService _chatService;
  final GameService _gameService;
  static final Map<String, GlobalKey> _globalChatKeys = {};

  RealtimeChatService._internal()
      : _databaseService = DatabaseService(),
        _authService = AuthService(DatabaseService()),
        _userService = UserService(DatabaseService()),
        _gameService = GameService(DatabaseService()) {
    _chatService = ChatService(_databaseService, _userService, _authService);
  }

  // Auth Methods
  String? get currentUserId => _authService.currentUserId;
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  Future<void> signIn(String email, String password) =>
      _authService.signIn(email, password);
  Future<void> signUp(String email, String password, String name) =>
      _authService.signUp(email, password, name);
  Future<void> logout() => _authService.logout();
  Future<void> storeUserInfo(
          {required String userId,
          required String name,
          required String email}) =>
      _authService.storeUserInfo(userId: userId, name: name, email: email);

  // User Methods
  Future<Map<String, dynamic>?> getUserInfo(String userId) =>
      _userService.getUserInfo(userId);
  Future<Map<String, dynamic>?> searchUserByEmail(String email) =>
      _userService.searchUserByEmail(email);
  Future<List<Map<String, dynamic>>> searchUsers(String email) =>
      _userService.searchUsers(email);

  // Chat Methods
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) =>
      _chatService.getChatMessages(chatId);
  Future<void> sendMessage(
          {required String chatId,
          required String content,
          String? chatType}) =>
      _chatService.sendMessage(
          chatId: chatId, content: content, chatType: chatType);
  Stream<List<Map<String, dynamic>>> getMessages(String chatId,
          {String? chatType}) =>
      _chatService.getMessages(chatId, chatType: chatType);
  Stream<List<Map<String, dynamic>>> getUserChats() =>
      _chatService.getUserChats();
  Future<void> markMessagesAsRead(String chatId, {String? chatType}) =>
      _chatService.markMessagesAsRead(chatId, chatType: chatType);
  Stream<int> getUnreadMessageCount(String chatId, {String? chatType}) =>
      _chatService.getUnreadMessageCount(chatId, chatType: chatType);
  Future<String> getOrCreateDirectChat(
          String otherUserId, String otherUserName, String otherUserEmail) =>
      _chatService.getOrCreateDirectChat(
          otherUserId, otherUserName, otherUserEmail);
  Future<String> createGroupChat(
          {required String groupName,
          required List<String> participantEmails}) =>
      _chatService.createGroupChat(
          groupName: groupName, participantEmails: participantEmails);
  Future<Map<String, dynamic>> getGroupChatInfo(String groupChatId) =>
      _chatService.getGroupChatInfo(groupChatId);
  Stream<List<Map<String, dynamic>>> getUserGroupChats() =>
      _chatService.getUserGroupChats();
  Future<void> addParticipantToGroup(
          {required String groupChatId, required String email}) =>
      _chatService.addParticipantToGroup(
          groupChatId: groupChatId, email: email);
  Future<void> removeParticipantFromGroup(
          {required String groupChatId, required String userId}) =>
      _chatService.removeParticipantFromGroup(
          groupChatId: groupChatId, userId: userId);
  Future<Map<String, dynamic>> getGroupParticipants(String groupChatId) =>
      _chatService.getGroupParticipants(groupChatId);
  Future<void> updateGroupName(
          {required String groupChatId, required String newName}) =>
      _chatService.updateGroupName(groupChatId: groupChatId, newName: newName);
  Future<Map<String, dynamic>> getChatInfo(String chatId) =>
      _chatService.getChatInfo(chatId);
  Stream<List<Map<String, dynamic>>> getGroupChatsData() =>
      _chatService.getGroupChatsData();
  GlobalKey getChatKey(String chatId) {
    if (!_globalChatKeys.containsKey(chatId)) {
      _globalChatKeys[chatId] = GlobalKey();
    }
    return _globalChatKeys[chatId]!;
  }

  void disposeKeys(String chatId) {
    _globalChatKeys.remove(chatId);
  }

  void resetAllChatKeys() {
    _globalChatKeys.clear();
  }

  bool isChatActive(String chatId) {
    return _globalChatKeys.containsKey(chatId);
  }

  // Get chat participant info
  Future<Map<String, dynamic>> getChatParticipantInfo(String chatId) async {
    try {
      final chatInfo = await _chatService.getChatInfo(chatId);
      final participants = chatInfo['participants'] as Map<String, dynamic>?;
      if (participants == null) return {};

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      // Get other participant's info
      final otherParticipant = participants.entries.firstWhere(
        (p) => p.key != currentUser.uid,
        orElse: () => participants.entries.first,
      );

      return otherParticipant.value as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  // Get group chat turn
  Stream<Map<String, dynamic>> getGroupChatTurn(String groupChatId) {
    return _databaseService
        .getRef('group_chats/$groupChatId/turn')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return {
          'currentTurnUserId': null,
          'currentTurnIndex': 0,
          'turnOrder': [],
        };
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // Game Methods
  Stream<Map<String, dynamic>> getGameState(String chatId) =>
      _gameService.getGameState(chatId);
  Future<void> updateGameState(
          {required String chatId,
          required int number,
          required String userId}) =>
      _gameService.updateGameState(
          chatId: chatId, number: number, userId: userId);
  Stream<List<Map<String, dynamic>>> getNumberSelectors(String groupChatId) =>
      _gameService.getNumberSelectors(groupChatId);
  Stream<List<Map<String, dynamic>>> getUserSelectedNumbers(
          String groupChatId, String userId) =>
      _gameService.getUserSelectedNumbers(groupChatId, userId);
  Future<void> resetGameState(String chatId) =>
      _gameService.resetGameState(chatId);
  Stream<Map<String, dynamic>> getGameStartState(String groupChatId) =>
      _gameService.getGameStartState(groupChatId);
  Future<void> markUserReady(String groupChatId) =>
      _gameService.markUserReady(groupChatId);
  Future<void> startGame(String groupChatId) =>
      _gameService.startGame(groupChatId);
  Stream<Map<String, dynamic>> getTurnTimer(String groupChatId) =>
      _gameService.getTurnTimer(groupChatId);
  Future<void> startTurnTimer(String groupChatId, String userId) =>
      _gameService.startTurnTimer(groupChatId, userId);
  Future<void> checkTurnTimeout(String groupChatId) =>
      _gameService.checkTurnTimeout(groupChatId);
  Future<void> resetGameStartState(String groupChatId) =>
      _gameService.resetGameStartState(groupChatId);
  Future<void> resetTurnTimer(String groupChatId) =>
      _gameService.resetTurnTimer(groupChatId);
  GlobalKey getGameKey(String groupChatId) =>
      _gameService.getGameKey(groupChatId);
  void disposeGameKeys(String groupChatId) =>
      _gameService.disposeKeys(groupChatId);
  void resetAllGameKeys() => _gameService.resetAllKeys();
  bool isGameActive(String groupChatId) =>
      _gameService.isGameActive(groupChatId);
  Stream<int> getRemainingTime(String groupChatId) =>
      _gameService.getRemainingTime(groupChatId);
  Stream<Map<String, dynamic>> getCurrentTurnInfo(String groupChatId) =>
      _gameService.getCurrentTurnInfo(groupChatId);
  Stream<Map<String, List<int>>> getAllSelectedNumbers(String groupChatId) =>
      _gameService.getAllSelectedNumbers(groupChatId);
  Future<void> updateGroupChatTurn({
    required String groupChatId,
    required String currentTurnUserId,
    required int currentTurnIndex,
    required List<String> turnOrder,
  }) =>
      _gameService.updateGroupChatTurn(
        groupChatId: groupChatId,
        currentTurnUserId: currentTurnUserId,
        currentTurnIndex: currentTurnIndex,
        turnOrder: turnOrder,
      );

  // Dispose method to clean up resources
  void dispose() {
    resetAllChatKeys();
    resetAllGameKeys();
  }
}
