import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:playing_cards/playing_cards.dart';
import '../services/realtime/realtime_chat_service.dart';
import '../services/game/card_game_rule.dart';
import '../theme/game_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _chatService = RealtimeChatService();
  final _database = FirebaseDatabase.instance;

  List<dynamic> currentUserNumbers = [];
  String? currentUserId;
  String? currentUserEmail;
  List<int> selectedNumbers = [];
  Map<String, dynamic> participants = {};
  List<String> turnOrder = [];
  String? currentTurnUid;
  int currentTurnIndex = 0;
  String? winnerUid;
  bool isProcessingMove = false;
  bool isMultiSelectMode = false;
  List<int> selectedCardsForMultiSelect = [];

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
    currentUserEmail = _auth.currentUser?.email?.toLowerCase();
    _loadUserNumbers();
    _setupGameListeners();
  }

  @override
  void dispose() {
    _chatService.disposeChatKey(widget.chatId);
    super.dispose();
  }

  void _setupGameListeners() {
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');

    // Listen for selected numbers changes
    gameRef.child('selectedNumbers').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          selectedNumbers = List<int>.from(event.snapshot.value as List);
        });
      }
    });

    // Listen for turn changes
    _database.ref('group_chats/${widget.chatId}/turn').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final turnData = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          turnOrder = List<String>.from(turnData['turnOrder'] ?? []);
          currentTurnIndex = turnData['currentTurnIndex'] ?? 0;
          currentTurnUid =
              turnOrder.isNotEmpty ? turnOrder[currentTurnIndex] : null;
          winnerUid = turnData['winnerUid']?.toString();
        });
      }
    });

    // Listen for participants
    _database
        .ref('group_chats/${widget.chatId}/participants')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          participants = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });

    // Listen for all players' numbers in real-time
    gameRef.child('userNumbers').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final userNumbers = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          // Update each participant's numbers
          for (var entry in userNumbers.entries) {
            final uid = entry.key.toString();
            final numbers = entry.value['numbers'] as List<dynamic>?;
            if (participants.containsKey(uid)) {
              participants[uid]['numbers'] = numbers ?? [];
            }
            // Update current user's numbers if it's their turn
            if (uid == currentUserId) {
              currentUserNumbers = List<dynamic>.from(numbers ?? []);
            }
          }
        });
      }
    });
  }

  bool get isMyTurn {
    return currentUserId == currentTurnUid;
  }

  Future<Suit?> _showSuitSelectionDialog(int number) async {
    final suits = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final suitNames = ['Spades ♠️', 'Hearts ♥️', 'Diamonds ♦️', 'Clubs ♣️'];
    final originalCard = CardGameRuleChecker.getCardFromNumber(number);
    final isJack = originalCard.value == CardValue.jack;

    return showDialog<Suit>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isJack
              ? 'Jack can change to any suit!'
              : '8 can change to any suit!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              final suit = suits[index];
              final previewCard = PlayingCard(suit, originalCard.value);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: SizedBox(
                    width: 40,
                    child: PlayingCardView(
                      card: previewCard,
                      showBack: false,
                    ),
                  ),
                  title: Text(suitNames[index]),
                  onTap: () {
                    Navigator.of(context).pop(suit);
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _getCardDisplayText(PlayingCard card) {
    final suitSymbol = {
      Suit.spades: '♠️',
      Suit.hearts: '♥️',
      Suit.diamonds: '♦️',
      Suit.clubs: '♣️',
    }[card.suit]!;

    String valueText;
    switch (card.value) {
      case CardValue.ace:
        valueText = 'A';
        break;
      case CardValue.two:
        valueText = '2';
        break;
      case CardValue.three:
        valueText = '3';
        break;
      case CardValue.four:
        valueText = '4';
        break;
      case CardValue.five:
        valueText = '5';
        break;
      case CardValue.six:
        valueText = '6';
        break;
      case CardValue.seven:
        valueText = '7';
        break;
      case CardValue.eight:
        valueText = '8';
        break;
      case CardValue.nine:
        valueText = '9';
        break;
      case CardValue.ten:
        valueText = '10';
        break;
      case CardValue.jack:
        valueText = 'J';
        break;
      case CardValue.queen:
        valueText = 'Q';
        break;
      case CardValue.king:
        valueText = 'K';
        break;
      case CardValue.joker_1:
        valueText = 'Joker';
        break;
      case CardValue.joker_2:
        valueText = 'Joker';
        break;
    }

    return '$valueText$suitSymbol';
  }

  Future<void> _sendNumberToChat(int number) async {
    if (!isMyTurn || isProcessingMove) return;

    // Check if we're in multi-select mode
    if (isMultiSelectMode) {
      if (selectedCardsForMultiSelect.isEmpty) {
        // First card selection in multi-select mode
        setState(() {
          selectedCardsForMultiSelect.add(number);
        });
        return;
      } else {
        // Check if the new card has the same suit as the first selected card
        if (CardGameRuleChecker.hasSameSuit(
            selectedCardsForMultiSelect[0], number)) {
          setState(() {
            selectedCardsForMultiSelect.add(number);
          });
          return;
        } else {
          // Different suit, cancel multi-select
          setState(() {
            isMultiSelectMode = false;
            selectedCardsForMultiSelect.clear();
          });
        }
      }
    }

    // Check if this is a 7 card
    if (CardGameRuleChecker.isSeven(number)) {
      setState(() {
        isMultiSelectMode = true;
        selectedCardsForMultiSelect = [number];
      });
      return;
    }

    setState(() {
      isProcessingMove = true;
    });

    try {
      // If we have multiple cards selected, play them all
      if (selectedCardsForMultiSelect.isNotEmpty) {
        final cardsToPlay = List<int>.from(selectedCardsForMultiSelect);
        selectedCardsForMultiSelect.clear();
        isMultiSelectMode = false;

        // Remove all selected cards from user's hand
        setState(() {
          for (var card in cardsToPlay) {
            currentUserNumbers.remove(card);
          }
        });

        final gameRef = _database.ref('group_chats/${widget.chatId}/game');
        final chatRef = _database.ref('group_chats/${widget.chatId}/messages');

        // Add only the 7 to selectedNumbers array
        await gameRef.child('selectedNumbers').set([cardsToPlay[0]]);

        // Add a message in the chat
        final card = CardGameRuleChecker.getCardFromNumber(cardsToPlay[0]);
        final cardText = _getCardDisplayText(card);

        final messageText = cardsToPlay.length > 1
            ? 'Played $cardText and ${cardsToPlay.length - 1} more cards of the same suit!'
            : 'Played $cardText';

        await chatRef.push().set({
          'uid': currentUserId,
          'email': currentUserEmail,
          'text': messageText,
          'timestamp': ServerValue.timestamp,
          'type': 'number',
          'number': cardsToPlay[0],
        });

        // Update the user's numbers in the database
        await gameRef.child('userNumbers/$currentUserId').update({
          'numbers': currentUserNumbers,
          'assignedAt': ServerValue.timestamp,
        });

        // Check if current user has won
        if (currentUserNumbers.isEmpty) {
          await chatRef.push().set({
            'uid': currentUserId,
            'email': currentUserEmail,
            'text': '${participants[currentUserId]?['name']} is the winner! 🎉',
            'timestamp': ServerValue.timestamp,
            'type': 'winner',
          });

          await _database.ref('group_chats/${widget.chatId}/turn').update({
            'winnerUid': currentUserId,
            'lastUpdated': ServerValue.timestamp,
          });

          // Increase winner's rank by 5
          if (currentUserId != null) {
            final userRef = _database.ref('users/$currentUserId');
            final userSnapshot = await userRef.get();
            if (userSnapshot.exists) {
              final currentRank = userSnapshot.child('rank').value as int? ?? 0;
              await userRef.update({
                'rank': currentRank + 5,
              });
            }
          }
          return;
        }

        // Pass to next turn
        if (turnOrder.isNotEmpty) {
          final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
          await _database.ref('group_chats/${widget.chatId}/turn').update({
            'currentTurnIndex': nextTurnIndex,
            'lastUpdated': ServerValue.timestamp,
          });
        }
        return;
      }

      // Regular single card play logic
      final lastSelectedNumber =
          selectedNumbers.isNotEmpty ? selectedNumbers.last : null;
      if (!CardGameRuleChecker.isMoveAllowed(lastSelectedNumber, number)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Invalid move! Card must match suit or value of the previous card.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Remove the number from user's numbers immediately after validation
      setState(() {
        currentUserNumbers.remove(number);
      });

      // If it's a wild card (8 or Jack), show suit selection dialog
      if (CardGameRuleChecker.isWildCard(number)) {
        final selectedSuit = await _showSuitSelectionDialog(number);
        if (selectedSuit == null) {
          // If user cancels suit selection, add the number back to their hand
          setState(() {
            currentUserNumbers.add(number);
          });
          return;
        }

        // Create a new card with the selected suit
        final originalCard = CardGameRuleChecker.getCardFromNumber(number);
        final newCard = PlayingCard(selectedSuit, originalCard.value);
        number = CardGameRuleChecker.getNumberFromCard(newCard);
      }

      final gameRef = _database.ref('group_chats/${widget.chatId}/game');
      final chatRef = _database.ref('group_chats/${widget.chatId}/messages');

      // Add the number to selectedNumbers array
      final newSelectedNumbers = List<int>.from(selectedNumbers)..add(number);
      await gameRef.child('selectedNumbers').set(newSelectedNumbers);

      // Add a message in the chat
      final card = CardGameRuleChecker.getCardFromNumber(number);
      final cardText = _getCardDisplayText(card);

      await chatRef.push().set({
        'uid': currentUserId,
        'email': currentUserEmail,
        'text': 'Selected $cardText',
        'timestamp': ServerValue.timestamp,
        'type': 'number',
        'number': number,
      });

      // Update the user's numbers in the database
      await gameRef.child('userNumbers/$currentUserId').update({
        'numbers': currentUserNumbers,
        'assignedAt': ServerValue.timestamp,
      });

      // Check if current user has won
      if (currentUserNumbers.isEmpty) {
        // Add winner message to chat
        await chatRef.push().set({
          'uid': currentUserId,
          'email': currentUserEmail,
          'text': '${participants[currentUserId]?['name']} is the winner! 🎉',
          'timestamp': ServerValue.timestamp,
          'type': 'winner',
        });

        // Update turn data with winner
        await _database.ref('group_chats/${widget.chatId}/turn').update({
          'winnerUid': currentUserId,
          'lastUpdated': ServerValue.timestamp,
        });

        // Increase winner's rank by 5
        if (currentUserId != null) {
          final userRef = _database.ref('users/$currentUserId');
          final userSnapshot = await userRef.get();
          if (userSnapshot.exists) {
            final currentRank = userSnapshot.child('rank').value as int? ?? 0;
            await userRef.update({
              'rank': currentRank + 5,
            });
          }
        }
        return;
      }

      // Check for special cards (Ace and 2)
      if (CardGameRuleChecker.isAce(number)) {
        // Check if it's Ace of Spades
        final card = CardGameRuleChecker.getCardFromNumber(number);
        if (card.suit == Suit.spades) {
          await _addRandomCardsToNextPlayer(5);
          await chatRef.push().set({
            'uid': currentUserId,
            'email': currentUserEmail,
            'text': 'Ace of Spades played! Next player draws 5 cards!',
            'timestamp': ServerValue.timestamp,
            'type': 'system',
          });
        } else {
          // Other Aces don't add any cards
          await chatRef.push().set({
            'uid': currentUserId,
            'email': currentUserEmail,
            'text': 'Ace played! No cards drawn.',
            'timestamp': ServerValue.timestamp,
            'type': 'system',
          });
        }
      } else if (CardGameRuleChecker.isTwo(number)) {
        await _addRandomCardsToNextPlayer(2);
        await chatRef.push().set({
          'uid': currentUserId,
          'email': currentUserEmail,
          'text': '2 played! Next player draws 2 cards!',
          'timestamp': ServerValue.timestamp,
          'type': 'system',
        });
      }

      // Always pass to next turn after a valid move
      if (turnOrder.isNotEmpty) {
        final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
        await _database.ref('group_chats/${widget.chatId}/turn').update({
          'currentTurnIndex': nextTurnIndex,
          'lastUpdated': ServerValue.timestamp,
        });
      }
    } finally {
      setState(() {
        isProcessingMove = false;
      });
    }
  }

  Future<void> _loadUserNumbers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userNumbersRef =
        _database.ref('group_chats/${widget.chatId}/game/userNumbers/$uid');

    // Fetch user numbers
    final numbersSnapshot = await userNumbersRef.get();
    if (numbersSnapshot.exists) {
      final numbersData = numbersSnapshot.value as Map<dynamic, dynamic>;
      if (numbersData['numbers'] != null) {
        setState(() {
          currentUserNumbers = List<dynamic>.from(numbersData['numbers']);
        });
      }
    }
  }

  Future<void> _addRandomCardsToNextPlayer(int count) async {
    if (turnOrder.isEmpty) return;

    final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
    final nextPlayerUid = turnOrder[nextTurnIndex];

    // Get current numbers of next player
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');
    final nextPlayerNumbersRef = gameRef.child('userNumbers/$nextPlayerUid');
    final nextPlayerNumbersSnapshot = await nextPlayerNumbersRef.get();

    List<dynamic> nextPlayerNumbers = [];
    if (nextPlayerNumbersSnapshot.exists) {
      final numbersData =
          nextPlayerNumbersSnapshot.value as Map<dynamic, dynamic>;
      if (numbersData['numbers'] != null) {
        nextPlayerNumbers = List<dynamic>.from(numbersData['numbers']);
      }
    }

    // Function to generate a random number between 1 and 52
    int generateRandomNumber() {
      return (DateTime.now().millisecondsSinceEpoch % 52) + 1;
    }

    // Add random numbers based on the card type
    if (count == 5) {
      // Ace card
      // Add 5 random numbers, each with a random delay
      for (int i = 0; i < 5; i++) {
        final random = generateRandomNumber();
        nextPlayerNumbers.add(random);

        // Update the numbers in real-time after each addition
        await nextPlayerNumbersRef.update({
          'numbers': nextPlayerNumbers,
          'lastUpdated': ServerValue.timestamp,
        });

        // Add a small delay between each card
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else if (count == 2) {
      // Two card
      // Add 2 random numbers, each with a random delay
      for (int i = 0; i < 2; i++) {
        final random = generateRandomNumber();
        nextPlayerNumbers.add(random);

        // Update the numbers in real-time after each addition
        await nextPlayerNumbersRef.update({
          'numbers': nextPlayerNumbers,
          'lastUpdated': ServerValue.timestamp,
        });

        // Add a small delay between each card
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<void> _skipTurn() async {
    if (!isMyTurn) return;

    // Generate a random number between 1 and 52
    final random = (DateTime.now().millisecondsSinceEpoch % 52) + 1;

    // Get current numbers
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');
    final userNumbersRef = gameRef.child('userNumbers/$currentUserId');
    final userNumbersSnapshot = await userNumbersRef.get();

    List<dynamic> currentNumbers = [];
    if (userNumbersSnapshot.exists) {
      final numbersData = userNumbersSnapshot.value as Map<dynamic, dynamic>;
      if (numbersData['numbers'] != null) {
        currentNumbers = List<dynamic>.from(numbersData['numbers']);
      }
    }

    // Add the new number
    currentNumbers.add(random);

    // Update numbers in real-time
    await userNumbersRef.update({
      'numbers': currentNumbers,
      'lastUpdated': ServerValue.timestamp,
    });

    // Calculate next turn
    if (turnOrder.isEmpty) return;
    final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;

    // Update turn in database
    await _database.ref('group_chats/${widget.chatId}/turn').update({
      'currentTurnIndex': nextTurnIndex,
      'lastUpdated': ServerValue.timestamp,
    });

    // Add a message in the chat
    final chatRef = _database.ref('group_chats/${widget.chatId}/messages');
    await chatRef.push().set({
      'uid': currentUserId,
      'email': currentUserEmail,
      'text':
          '${participants[currentUserId]?['name']} skipped their turn and drew card $random',
      'timestamp': ServerValue.timestamp,
      'type': 'system',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameTheme.surfaceColor,
        title: Text(
          widget.chatName,
          style: const TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: GameTheme.textColor),
        actions: [
          if (currentTurnUid != null)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMyTurn
                    ? GameTheme.accentColor.withOpacity(0.2)
                    : GameTheme.surfaceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GameTheme.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMyTurn ? Icons.play_arrow : Icons.hourglass_empty,
                    color:
                        isMyTurn ? GameTheme.accentColor : GameTheme.textColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${participants[currentTurnUid]?['name'] ?? 'Unknown'}\'s turn',
                    style: TextStyle(
                      color: isMyTurn
                          ? GameTheme.accentColor
                          : GameTheme.textColor,
                      fontSize: 12,
                      fontWeight:
                          isMyTurn ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.primaryGradient,
        ),
        child: Column(
          children: [
            _buildPlayerCounts(),
            Expanded(
              child: _buildSelectedNumbers(),
            ),
            if (winnerUid != null) _buildGameOver() else _buildNumberButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCounts() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: GameTheme.accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final uid = participants.keys.elementAt(index);
          final player = participants[uid];
          final isCurrentPlayer = uid == currentTurnUid;
          final cardCount = player['numbers']?.length ?? 0;
          final isCurrentUser = uid == currentUserId;

          return Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCurrentPlayer
                              ? [
                                  GameTheme.accentColor,
                                  GameTheme.accentColor.withOpacity(0.8)
                                ]
                              : isCurrentUser
                                  ? [
                                      GameTheme.accentColor.withOpacity(0.3),
                                      GameTheme.accentColor.withOpacity(0.1)
                                    ]
                                  : [
                                      GameTheme.surfaceColor.withOpacity(0.3),
                                      GameTheme.surfaceColor.withOpacity(0.1)
                                    ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isCurrentPlayer
                                    ? GameTheme.accentColor
                                    : GameTheme.surfaceColor)
                                .withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cardCount.toString(),
                          style: TextStyle(
                            color: isCurrentPlayer
                                ? Colors.white
                                : GameTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (isCurrentPlayer)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: GameTheme.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: GameTheme.accentColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? GameTheme.accentColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    player['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentUser
                          ? GameTheme.accentColor
                          : GameTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedNumbers() {
    if (selectedNumbers.isEmpty) {
      return Center(
        child: Text(
          'No numbers selected yet',
          style: TextStyle(
            fontSize: 16,
            color: GameTheme.textColor.withOpacity(0.7),
          ),
        ),
      );
    }

    // Get only the last 4 selected numbers
    final lastFourNumbers = selectedNumbers.length > 4
        ? selectedNumbers.sublist(selectedNumbers.length - 4)
        : selectedNumbers;

    // If the last card is a 7, make sure it's at the top
    final displayNumbers = List<int>.from(lastFourNumbers);
    if (displayNumbers.isNotEmpty &&
        CardGameRuleChecker.isSeven(displayNumbers.last)) {
      final seven = displayNumbers.removeLast();
      displayNumbers.insert(0, seven);
    }

    final selectedCards = displayNumbers
        .map((number) => CardGameRuleChecker.getCardFromNumber(number))
        .toList();

    return Center(
      child: SizedBox(
        height: 250,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(selectedCards.length, (index) {
            final card = selectedCards[index];
            final centerX = MediaQuery.of(context).size.width / 2;
            final offset = (index - (selectedCards.length - 1) / 2) * 35.0;
            final angle = (index - (selectedCards.length - 1) / 2) * 0.04;

            return Positioned(
              left: centerX + offset - 65,
              child: Transform.rotate(
                angle: angle,
                child: SizedBox(
                  width: 130,
                  child: PlayingCardView(
                    card: card,
                    showBack: false,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    if (winnerUid == null) return const SizedBox.shrink();

    final winnerName = participants[winnerUid]?['name'] ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.all(16),
      color: GameTheme.accentColor.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 48,
            color: GameTheme.accentColor,
          ),
          const SizedBox(height: 8),
          const Text(
            'Game Over!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: GameTheme.accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$winnerName is the winner! 🎉',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GameTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButtons() {
    if (currentUserNumbers.isEmpty || winnerUid != null) {
      return const SizedBox.shrink();
    }

    final isCurrentUserTurn = isMyTurn;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: GameTheme.surfaceColor.withOpacity(0.1),
        border: Border.all(
          color: GameTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(GameTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isCurrentUserTurn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Wait for your turn to select a number',
                style: TextStyle(
                  color: GameTheme.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          if (isCurrentUserTurn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMultiSelectMode)
                    Row(
                      children: [
                        const Text(
                          'Select cards of the same suit',
                          style: TextStyle(
                            color: GameTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedCardsForMultiSelect.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: isProcessingMove
                                  ? null
                                  : () async {
                                      final cardsToPlay = List<int>.from(
                                          selectedCardsForMultiSelect);
                                      setState(() {
                                        isProcessingMove = true;
                                        selectedCardsForMultiSelect.clear();
                                        isMultiSelectMode = false;
                                      });

                                      try {
                                        // Remove all selected cards from user's hand
                                        setState(() {
                                          for (var card in cardsToPlay) {
                                            currentUserNumbers.remove(card);
                                          }
                                        });

                                        final gameRef = _database.ref(
                                            'group_chats/${widget.chatId}/game');
                                        final chatRef = _database.ref(
                                            'group_chats/${widget.chatId}/messages');

                                        // Add only the 7 to selectedNumbers array
                                        await gameRef
                                            .child('selectedNumbers')
                                            .set([cardsToPlay[0]]);

                                        // Add a message in the chat
                                        final card = CardGameRuleChecker
                                            .getCardFromNumber(cardsToPlay[0]);
                                        final cardText =
                                            _getCardDisplayText(card);

                                        final messageText = cardsToPlay.length >
                                                1
                                            ? 'Played $cardText and ${cardsToPlay.length - 1} more cards of the same suit!'
                                            : 'Played $cardText';

                                        await chatRef.push().set({
                                          'uid': currentUserId,
                                          'email': currentUserEmail,
                                          'text': messageText,
                                          'timestamp': ServerValue.timestamp,
                                          'type': 'number',
                                          'number': cardsToPlay[0],
                                        });

                                        // Update the user's numbers in the database
                                        await gameRef
                                            .child('userNumbers/$currentUserId')
                                            .update({
                                          'numbers': currentUserNumbers,
                                          'assignedAt': ServerValue.timestamp,
                                        });

                                        // Check if current user has won
                                        if (currentUserNumbers.isEmpty) {
                                          await chatRef.push().set({
                                            'uid': currentUserId,
                                            'email': currentUserEmail,
                                            'text':
                                                '${participants[currentUserId]?['name']} is the winner! 🎉',
                                            'timestamp': ServerValue.timestamp,
                                            'type': 'winner',
                                          });

                                          await _database
                                              .ref(
                                                  'group_chats/${widget.chatId}/turn')
                                              .update({
                                            'winnerUid': currentUserId,
                                            'lastUpdated':
                                                ServerValue.timestamp,
                                          });
                                          return;
                                        }

                                        // Pass to next turn
                                        if (turnOrder.isNotEmpty) {
                                          final nextTurnIndex =
                                              (currentTurnIndex + 1) %
                                                  turnOrder.length;
                                          await _database
                                              .ref(
                                                  'group_chats/${widget.chatId}/turn')
                                              .update({
                                            'currentTurnIndex': nextTurnIndex,
                                            'lastUpdated':
                                                ServerValue.timestamp,
                                          });
                                        }
                                      } finally {
                                        setState(() {
                                          isProcessingMove = false;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: Text(
                                  'Play ${selectedCardsForMultiSelect.length} Card${selectedCardsForMultiSelect.length > 1 ? 's' : ''}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GameTheme.accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    TextButton.icon(
                      onPressed: isProcessingMove ? null : _skipTurn,
                      icon: const Icon(Icons.skip_next, size: 20),
                      label: const Text('Skip Turn'),
                      style: TextButton.styleFrom(
                        foregroundColor: GameTheme.textColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentUserNumbers.length,
              itemBuilder: (context, index) {
                final number = currentUserNumbers[index];
                final isSelected = selectedCardsForMultiSelect.contains(number);
                final canSelect = isMultiSelectMode &&
                    (selectedCardsForMultiSelect.isEmpty ||
                        CardGameRuleChecker.hasSameSuit(
                            selectedCardsForMultiSelect[0], number));

                return Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: (isCurrentUserTurn && !isProcessingMove)
                        ? () => _sendNumberToChat(number)
                        : null,
                    child: Opacity(
                      opacity: isProcessingMove ? 0.5 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? GameTheme.accentColor
                                : isMultiSelectMode && !canSelect
                                    ? GameTheme.surfaceColor
                                    : isCurrentUserTurn
                                        ? GameTheme.accentColor
                                        : GameTheme.surfaceColor,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              PlayingCardView(
                                card: CardGameRuleChecker.getCardFromNumber(
                                    number),
                                showBack: false,
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: GameTheme.accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
