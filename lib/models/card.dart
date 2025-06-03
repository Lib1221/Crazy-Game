class Card {
  final String suit;
  final String value;
  final bool isSpecial;

  Card({
    required this.suit,
    required this.value,
    this.isSpecial = false,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      suit: json['suit'] as String,
      value: json['value'] as String,
      isSpecial: json['isSpecial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'value': value,
      'isSpecial': isSpecial,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Card &&
        other.suit == suit &&
        other.value == value &&
        other.isSpecial == isSpecial;
  }

  @override
  int get hashCode {
    return Object.hash(suit, value, isSpecial);
  }

  @override
  String toString() {
    return '$value of $suit${isSpecial ? ' (Special)' : ''}';
  }
}
