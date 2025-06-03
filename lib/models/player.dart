import 'package:crazygame/models/card.dart';

class Player {
  final String id;
  final String name;
  final String avatarUrl;
  final List<Card> hand;
  final int score;
  final bool isReady;
  final bool isCurrentPlayer;

  Player({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.hand,
    required this.score,
    required this.isReady,
    required this.isCurrentPlayer,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      hand: (json['hand'] as List<dynamic>)
          .map((card) => Card.fromJson(card as Map<String, dynamic>))
          .toList(),
      score: json['score'] as int,
      isReady: json['isReady'] as bool,
      isCurrentPlayer: json['isCurrentPlayer'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'hand': hand.map((card) => card.toJson()).toList(),
      'score': score,
      'isReady': isReady,
      'isCurrentPlayer': isCurrentPlayer,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    List<Card>? hand,
    int? score,
    bool? isReady,
    bool? isCurrentPlayer,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hand: hand ?? this.hand,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.score == score &&
        other.isReady == isReady &&
        other.isCurrentPlayer == isCurrentPlayer &&
        _listEquals(other.hand, hand);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      avatarUrl,
      score,
      isReady,
      isCurrentPlayer,
      _listHashCode(hand),
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _listHashCode<T>(List<T> list) {
    int hash = 0;
    for (var item in list) {
      hash = Object.hash(hash, item);
    }
    return hash;
  }
}
