
import 'package:crazygame/screens/game/components/player_hand.dart';

class Player {
  final String email;
  final bool isHost;
  final List<GameCard> hand;
  final bool isActive;

  Player({
    required this.email,
    required this.isHost,
    required this.hand,
    this.isActive = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      email: json['email'] as String,
      isHost: json['isHost'] as bool,
      hand: (json['hand'] as List)
          .map((card) => GameCard.fromJson(card as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'isHost': isHost,
      'hand': hand.map((card) => card.toJson()).toList(),
      'isActive': isActive,
    };
  }
}
