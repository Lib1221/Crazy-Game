import 'package:get/get.dart';
import 'package:crazygame/models/card.dart';
import 'package:crazygame/models/player.dart';

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
      players: (json['players'] as List)
          .map((player) => Player.fromJson(player))
          .toList(),
      deck: (json['deck'] as List).map((card) => Card.fromJson(card)).toList(),
      discardPile: (json['discardPile'] as List)
          .map((card) => Card.fromJson(card))
          .toList(),
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
