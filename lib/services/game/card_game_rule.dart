import 'package:playing_cards/playing_cards.dart';

class CardGameRuleChecker {
  /// Maps an integer 1–54 to a PlayingCard object
  static PlayingCard getCardFromNumber(int number) {
    if (number < 1 || number > 54) {
      throw ArgumentError('Card number must be between 1 and 54');
    }

    if (number == 53) {
      return PlayingCard(Suit.joker, CardValue.ace); // Red Joker
    }
    if (number == 54) {
      return PlayingCard(Suit.joker, CardValue.king); // Black Joker
    }

    final suits = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final values = [
      CardValue.ace,
      CardValue.two,
      CardValue.three,
      CardValue.four,
      CardValue.five,
      CardValue.six,
      CardValue.seven,
      CardValue.eight,
      CardValue.nine,
      CardValue.ten,
      CardValue.jack,
      CardValue.queen,
      CardValue.king
    ];

    int suitIndex = (number - 1) ~/ 13;
    int valueIndex = (number - 1) % 13;

    return PlayingCard(suits[suitIndex], values[valueIndex]);
  }

  /// Checks if param1 is allowed to be played on param2
  static bool isMoveAllowed(int? param1, int param2) {
    // Special rule: first move
    if (param1 == null) {
      return true;
    }

    final card1 = getCardFromNumber(param1);
    final card2 = getCardFromNumber(param2);

    // Jokers don't match anything
    if (card1.suit == Suit.joker || card2.suit == Suit.joker) {
      return false;
    }

    // If the card being played on (param2) is 8 or Jack, any card can be played
    if (card2.value == CardValue.eight || card2.value == CardValue.jack) {
      return true;
    }

    // Check for same suit or same value
    return card1.suit == card2.suit || card1.value == card2.value;
  }

  /// Checks if a card is a wild card (8 or Jack)
  static bool isWildCard(int number) {
    final card = getCardFromNumber(number);
    return card.value == CardValue.eight || card.value == CardValue.jack;
  }

  /// Gets the number from a card
  static int getNumberFromCard(PlayingCard card) {
    if (card.suit == Suit.joker) {
      return card.value == CardValue.ace ? 53 : 54;
    }

    final suits = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final values = [
      CardValue.ace,
      CardValue.two,
      CardValue.three,
      CardValue.four,
      CardValue.five,
      CardValue.six,
      CardValue.seven,
      CardValue.eight,
      CardValue.nine,
      CardValue.ten,
      CardValue.jack,
      CardValue.queen,
      CardValue.king
    ];

    int suitIndex = suits.indexOf(card.suit);
    int valueIndex = values.indexOf(card.value);
    return suitIndex * 13 + valueIndex + 1;
  }

  /// Checks if a card is an Ace
  static bool isAce(int number) {
    final card = getCardFromNumber(number);
    return card.value == CardValue.ace;
  }

  /// Checks if a card is a 2
  static bool isTwo(int number) {
    final card = getCardFromNumber(number);
    return card.value == CardValue.two;
  }
}
