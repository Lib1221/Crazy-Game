class Card {
  final String suit;
  final String value;
  final bool isSpecial;
  final String imageUrl;

  Card({
    required this.suit,
    required this.value,
    this.isSpecial = false,
    required this.imageUrl,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      suit: json['suit'] as String,
      value: json['value'] as String,
      isSpecial: json['isSpecial'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'value': value,
      'isSpecial': isSpecial,
      'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Card &&
        other.suit == suit &&
        other.value == value &&
        other.isSpecial == isSpecial &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(suit, value, isSpecial, imageUrl);
  }

  @override
  String toString() {
    return '$value of $suit${isSpecial ? ' (Special)' : ''}';
  }

  // Helper methods for card comparison
  bool canPlayOn(Card other) {
    return suit == other.suit || value == other.value || isSpecial;
  }

  int get numericValue {
    switch (value) {
      case 'A':
        return 1;
      case 'J':
        return 11;
      case 'Q':
        return 12;
      case 'K':
        return 13;
      default:
        return int.tryParse(value) ?? 0;
    }
  }

  bool get isFaceCard => value == 'J' || value == 'Q' || value == 'K';
  bool get isAce => value == 'A';
  bool get isNumberCard => !isFaceCard && !isAce;
}
