enum GameEventType {
  cardPlayed,
  scoreChanged,
  playerJoined,
  playerLeft,
  gameStarted,
  gameEnded,
  turnStarted,
  turnEnded,
}

class GameEvent {
  final GameEventType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GameEvent({
    required this.type,
    required this.description,
    required this.timestamp,
    this.data = const {},
  });

  factory GameEvent.cardPlayed({
    required String playerName,
    required String cardName,
  }) {
    return GameEvent(
      type: GameEventType.cardPlayed,
      description: '$playerName played $cardName',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
        'cardName': cardName,
      },
    );
  }

  factory GameEvent.scoreChanged({
    required String playerName,
    required int score,
  }) {
    return GameEvent(
      type: GameEventType.scoreChanged,
      description: '$playerName\'s score changed to $score',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
        'score': score,
      },
    );
  }

  factory GameEvent.playerJoined({
    required String playerName,
  }) {
    return GameEvent(
      type: GameEventType.playerJoined,
      description: '$playerName joined the game',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
      },
    );
  }

  factory GameEvent.playerLeft({
    required String playerName,
  }) {
    return GameEvent(
      type: GameEventType.playerLeft,
      description: '$playerName left the game',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
      },
    );
  }

  factory GameEvent.gameStarted() {
    return GameEvent(
      type: GameEventType.gameStarted,
      description: 'Game started',
      timestamp: DateTime.now(),
    );
  }

  factory GameEvent.gameEnded({
    required String winnerName,
    required int finalScore,
  }) {
    return GameEvent(
      type: GameEventType.gameEnded,
      description: 'Game ended. $winnerName won with $finalScore points',
      timestamp: DateTime.now(),
      data: {
        'winnerName': winnerName,
        'finalScore': finalScore,
      },
    );
  }

  factory GameEvent.turnStarted({
    required String playerName,
  }) {
    return GameEvent(
      type: GameEventType.turnStarted,
      description: '$playerName\'s turn started',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
      },
    );
  }

  factory GameEvent.turnEnded({
    required String playerName,
  }) {
    return GameEvent(
      type: GameEventType.turnEnded,
      description: '$playerName\'s turn ended',
      timestamp: DateTime.now(),
      data: {
        'playerName': playerName,
      },
    );
  }
}
