import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class GameService {
  final DatabaseService _databaseService;
  final Map<String, GlobalKey> _gameKeys = {};

  GameService(this._databaseService);

  // Get real-time game state
  Stream<Map<String, dynamic>> getGameState(String chatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(chatId)
        .child('game')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return {
          'selectedNumbers': [],
          'numberSelectors': [],
        };
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // Update game state
  Future<void> updateGameState({
    required String chatId,
    required int number,
    required String userId,
  }) async {
    try {
      final gameRef = _databaseService.database
          .ref()
          .child('group_chats')
          .child(chatId)
          .child('game');
      final turnRef = _databaseService.getRef('group_chats/$chatId/turn');

      // Get current turn data
      final turnSnapshot = await turnRef.get();
      if (!turnSnapshot.exists) return;

      final turnData = Map<String, dynamic>.from(turnSnapshot.value as Map);
      if (turnData['currentTurnUserId'] != userId) return; // Not user's turn

      // Get current game state
      final snapshot = await gameRef.get();
      Map<String, dynamic> currentState = {
        'selectedNumbers': [],
        'numberSelectors': [],
        'userNumbers': {},
        'lastUpdated': ServerValue.timestamp,
      };

      if (snapshot.value != null) {
        currentState = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Update selected numbers
      List<dynamic> selectedNumbers =
          List<dynamic>.from(currentState['selectedNumbers'] ?? []);
      if (!selectedNumbers.contains(number)) {
        selectedNumbers.add(number);
      }

      // Update number selectors as array of objects
      List<dynamic> numberSelectors =
          List<dynamic>.from(currentState['numberSelectors'] ?? []);
      numberSelectors.add({
        'number': number,
        'userId': userId,
        'timestamp': ServerValue.timestamp,
      });

      // Update user's selected numbers
      Map<dynamic, dynamic> userNumbers =
          Map<dynamic, dynamic>.from(currentState['userNumbers'] ?? {});
      List<dynamic> userSelectedNumbers =
          List<dynamic>.from(userNumbers[userId] ?? []);
      if (!userSelectedNumbers.contains(number)) {
        userSelectedNumbers.add({
          'number': number,
          'timestamp': ServerValue.timestamp,
        });
        userNumbers[userId] = userSelectedNumbers;
      }

      // Update the database
      await gameRef.update({
        'selectedNumbers': selectedNumbers,
        'numberSelectors': numberSelectors,
        'userNumbers': userNumbers,
        'lastUpdated': ServerValue.timestamp,
      });

      // Move to next turn
      final turnOrder = List<String>.from(turnData['turnOrder'] ?? []);
      int currentIndex = turnData['currentTurnIndex'] as int? ?? 0;

      // Move to next user
      currentIndex = (currentIndex + 1) % turnOrder.length;
      final nextUserId = turnOrder[currentIndex];

      // Update turn
      await updateGroupChatTurn(
        groupChatId: chatId,
        currentTurnUserId: nextUserId,
        currentTurnIndex: currentIndex,
        turnOrder: turnOrder,
      );

      // Start timer for next user
      await startTurnTimer(chatId, nextUserId);
    } catch (e) {
      rethrow;
    }
  }

  // Get number selectors as array
  Stream<List<Map<String, dynamic>>> getNumberSelectors(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('game')
        .child('numberSelectors')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value;
      if (data is! List) return [];

      return data.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    });
  }

  // Get user's selected numbers with timestamps
  Stream<List<Map<String, dynamic>>> getUserSelectedNumbers(
      String groupChatId, String userId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('game')
        .child('userNumbers')
        .child(userId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value;
      if (data is! List) return [];

      return data.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    });
  }

  // Reset game state with array structure
  Future<void> resetGameState(String chatId) async {
    try {
      await _databaseService.database
          .ref()
          .child('group_chats')
          .child(chatId)
          .child('game')
          .set({
        'selectedNumbers': [],
        'numberSelectors': [],
        'userNumbers': {},
        'lastUpdated': ServerValue.timestamp,
      });

      // Reset game start state and turn timer
      await resetGameStartState(chatId);
      await resetTurnTimer(chatId);

      // Clean up keys if game is being reset
      disposeKeys(chatId);
    } catch (e) {
      rethrow;
    }
  }

  // Get game start state
  Stream<Map<String, dynamic>> getGameStartState(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('gameStart')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return {
          'isStarted': false,
          'readyUsers': {},
          'startTime': null,
        };
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // Mark user as ready to start game
  Future<void> markUserReady(String groupChatId) async {
    final gameStartRef =
        _databaseService.getRef('group_chats/$groupChatId/gameStart');
    await gameStartRef.update({
      'readyUsers/${_databaseService.database.ref().push().key}':
          ServerValue.timestamp,
    });
  }

  // Start the game when all users are ready
  Future<void> startGame(String groupChatId) async {
    final gameStartRef =
        _databaseService.getRef('group_chats/$groupChatId/gameStart');
    final participantsRef =
        _databaseService.getRef('group_chats/$groupChatId/participants');

    // Get participants and ready users
    final participantsSnapshot = await participantsRef.get();
    final gameStartSnapshot = await gameStartRef.get();

    if (!participantsSnapshot.exists || !gameStartSnapshot.exists) return;

    final participants =
        Map<String, dynamic>.from(participantsSnapshot.value as Map);
    final gameStartData =
        Map<String, dynamic>.from(gameStartSnapshot.value as Map);
    final readyUsers =
        gameStartData['readyUsers'] as Map<String, dynamic>? ?? {};

    // Check if all participants are ready
    bool allReady = true;
    for (var participantId in participants.keys) {
      if (!readyUsers.containsKey(participantId)) {
        allReady = false;
        break;
      }
    }

    if (allReady) {
      // Initialize game key if not exists
      getGameKey(groupChatId);

      // Start the game
      await gameStartRef.update({
        'isStarted': true,
        'startTime': ServerValue.timestamp,
      });

      // Reset game state
      await resetGameState(groupChatId);

      // Initialize turn with first user
      final turnOrder = participants.keys.toList();
      await updateGroupChatTurn(
        groupChatId: groupChatId,
        currentTurnUserId: turnOrder[0],
        currentTurnIndex: 0,
        turnOrder: turnOrder,
      );
    }
  }

  // Get turn timer state
  Stream<Map<String, dynamic>> getTurnTimer(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('turnTimer')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return {
          'startTime': null,
          'currentTurnUserId': null,
        };
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // Start turn timer
  Future<void> startTurnTimer(String groupChatId, String userId) async {
    await _databaseService.getRef('group_chats/$groupChatId/turnTimer').set({
      'startTime': ServerValue.timestamp,
      'currentTurnUserId': userId,
    });
  }

  // Check and handle turn timeout
  Future<void> checkTurnTimeout(String groupChatId) async {
    final turnTimerRef =
        _databaseService.getRef('group_chats/$groupChatId/turnTimer');
    final turnRef = _databaseService.getRef('group_chats/$groupChatId/turn');

    final turnTimerSnapshot = await turnTimerRef.get();
    final turnSnapshot = await turnRef.get();

    if (!turnTimerSnapshot.exists || !turnSnapshot.exists) return;

    final turnTimerData =
        Map<String, dynamic>.from(turnTimerSnapshot.value as Map);
    final turnData = Map<String, dynamic>.from(turnSnapshot.value as Map);

    final startTime = turnTimerData['startTime'] as int?;
    if (startTime == null) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - startTime >= 30000) {
      // 30 seconds timeout
      // Move to next turn
      final turnOrder = List<String>.from(turnData['turnOrder'] ?? []);
      int currentIndex = turnData['currentTurnIndex'] as int? ?? 0;

      // Move to next user
      currentIndex = (currentIndex + 1) % turnOrder.length;
      final nextUserId = turnOrder[currentIndex];

      // Update turn
      await updateGroupChatTurn(
        groupChatId: groupChatId,
        currentTurnUserId: nextUserId,
        currentTurnIndex: currentIndex,
        turnOrder: turnOrder,
      );

      // Start timer for next user
      await startTurnTimer(groupChatId, nextUserId);
    }
  }

  // Reset game start state
  Future<void> resetGameStartState(String groupChatId) async {
    await _databaseService.getRef('group_chats/$groupChatId/gameStart').set({
      'isStarted': false,
      'readyUsers': {},
      'startTime': null,
    });
  }

  // Reset turn timer
  Future<void> resetTurnTimer(String groupChatId) async {
    await _databaseService.getRef('group_chats/$groupChatId/turnTimer').set({
      'startTime': null,
      'currentTurnUserId': null,
    });
  }

  // Get or create a game key
  GlobalKey getGameKey(String groupChatId) {
    if (!_gameKeys.containsKey(groupChatId)) {
      _gameKeys[groupChatId] = GlobalKey();
    }
    return _gameKeys[groupChatId]!;
  }

  // Dispose keys when chat/game is closed
  void disposeKeys(String groupChatId) {
    _gameKeys.remove(groupChatId);
  }

  // Reset all keys
  void resetAllKeys() {
    _gameKeys.clear();
  }

  // Add method to check if game is active
  bool isGameActive(String groupChatId) {
    return _gameKeys.containsKey(groupChatId);
  }

  // Get remaining time for current turn
  Stream<int> getRemainingTime(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('turnTimer')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 30;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final startTime = data['startTime'] as int?;
      if (startTime == null) return 30;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = (currentTime - startTime) ~/ 1000;
      final remainingSeconds = 30 - elapsedSeconds;
      return remainingSeconds > 0 ? remainingSeconds : 0;
    });
  }

  // Get current turn user info
  Stream<Map<String, dynamic>> getCurrentTurnInfo(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('turn')
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

  // Get all selected numbers in chat
  Stream<Map<String, List<int>>> getAllSelectedNumbers(String groupChatId) {
    return _databaseService.database
        .ref()
        .child('group_chats')
        .child(groupChatId)
        .child('game')
        .child('userNumbers')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return {};

      final data = event.snapshot.value;
      if (data is! Map) return {};

      final Map<String, List<int>> result = {};
      data.forEach((userId, numbers) {
        if (numbers is List) {
          result[userId.toString()] = List<int>.from(numbers);
        }
      });
      return result;
    });
  }

  // Update group chat turn
  Future<void> updateGroupChatTurn({
    required String groupChatId,
    required String currentTurnUserId,
    required int currentTurnIndex,
    required List<String> turnOrder,
  }) async {
    try {
      final turnRef = _databaseService.getRef('group_chats/$groupChatId/turn');
      await turnRef.set({
        'currentTurnUserId': currentTurnUserId,
        'currentTurnIndex': currentTurnIndex,
        'turnOrder': turnOrder,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      return;
    }
  }
}
