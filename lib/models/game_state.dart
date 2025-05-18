import 'package:get/get.dart';

class Card {
  final String suit;
  final String value;
  final String imageUrl;

  Card({
    required this.suit,
    required this.value,
    required this.imageUrl,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      suit: json['suit'],
      value: json['value'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'value': value,
      'imageUrl': imageUrl,
    };
  }
}

class Player {
  final String id;
  final String name;
  final String avatarUrl;
  final List<Card> hand;
  final bool isCurrentTurn;
  final int score;

  Player({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.hand,
    this.isCurrentTurn = false,
    this.score = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      hand: (json['hand'] as List).map((card) => Card.fromJson(card)).toList(),
      isCurrentTurn: json['isCurrentTurn'] ?? false,
      score: json['score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'hand': hand.map((card) => card.toJson()).toList(),
      'isCurrentTurn': isCurrentTurn,
      'score': score,
    };
  }
}

class GameState {
  final String roomId;
  final List<Player> players;
  final List<Card> deck;
  final List<Card> discardPile;
  final String currentPlayerId;
  final int turnTimeRemaining;
  final String gameStatus; // 'waiting', 'playing', 'finished'
  final String winnerId;

  GameState({
    required this.roomId,
    required this.players,
    required this.deck,
    required this.discardPile,
    required this.currentPlayerId,
    required this.turnTimeRemaining,
    required this.gameStatus,
    this.winnerId = '',
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      roomId: json['roomId'],
      players: (json['players'] as List).map((player) => Player.fromJson(player)).toList(),
      deck: (json['deck'] as List).map((card) => Card.fromJson(card)).toList(),
      discardPile: (json['discardPile'] as List).map((card) => Card.fromJson(card)).toList(),
      currentPlayerId: json['currentPlayerId'],
      turnTimeRemaining: json['turnTimeRemaining'],
      gameStatus: json['gameStatus'],
      winnerId: json['winnerId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'players': players.map((player) => player.toJson()).toList(),
      'deck': deck.map((card) => card.toJson()).toList(),
      'discardPile': discardPile.map((card) => card.toJson()).toList(),
      'currentPlayerId': currentPlayerId,
      'turnTimeRemaining': turnTimeRemaining,
      'gameStatus': gameStatus,
      'winnerId': winnerId,
    };
  }
} 