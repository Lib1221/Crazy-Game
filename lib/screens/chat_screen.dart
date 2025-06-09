import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:playing_cards/playing_cards.dart';
import '../services/realtime/realtime_chat_service.dart';
import '../services/game/card_game_rule.dart';

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

  Future<void> _sendNumberToChat(int number) async {
    if (!isMyTurn || isProcessingMove) return;

    setState(() {
      isProcessingMove = true;
    });

    try {
      // Check if the move is allowed
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
      final suitSymbol = {
        Suit.spades: '♠️',
        Suit.hearts: '♥️',
        Suit.diamonds: '♦️',
        Suit.clubs: '♣️',
      }[card.suit]!;

      final cardType = card.value == CardValue.eight
          ? '8'
          : card.value == CardValue.jack
              ? 'Jack'
              : card.value.toString().split('.').last;

      await chatRef.push().set({
        'uid': currentUserId,
        'email': currentUserEmail,
        'text': 'Selected $cardType of $suitSymbol',
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
        return;
      }

      // Check for special cards (Ace and 2)
      if (CardGameRuleChecker.isAce(number)) {
        await _addRandomCardsToNextPlayer(5);
        await chatRef.push().set({
          'uid': currentUserId,
          'email': currentUserEmail,
          'text': 'Ace played! Next player draws 5 cards!',
          'timestamp': ServerValue.timestamp,
          'type': 'system',
        });
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

  Future<void> _skipTurn() async {
    if (!isMyTurn) return;

    // Add a random number between 1-52 to user's numbers
    final random = (DateTime.now().millisecondsSinceEpoch % 52) + 1;

    // Add to user's numbers
    setState(() {
      currentUserNumbers.add(random);
    });

    // Update user's numbers in database
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');
    await gameRef.child('userNumbers/$currentUserId').update({
      'numbers': currentUserNumbers,
      'assignedAt': ServerValue.timestamp,
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
          '${participants[currentUserId]?['name']} skipped their turn and drew card ${random}',
      'timestamp': ServerValue.timestamp,
      'type': 'system',
    });
  }

  Widget _buildSelectedNumbers() {
    if (selectedNumbers.isEmpty) {
      return const Center(
        child: Text(
          'No numbers selected yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Get only the last 4 selected numbers
    final lastFourNumbers = selectedNumbers.length > 4
        ? selectedNumbers.sublist(selectedNumbers.length - 4)
        : selectedNumbers;

    final selectedCards = lastFourNumbers
        .map((number) => CardGameRuleChecker.getCardFromNumber(number))
        .toList();

    return Center(
      child: SizedBox(
        height: 250, // Increased height
        width: MediaQuery.of(context)
            .size
            .width, // Full width for better centering
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(selectedCards.length, (index) {
            final card = selectedCards[index];
            // Calculate center position and offset
            final centerX = MediaQuery.of(context).size.width / 2;
            final offset = (index - (selectedCards.length - 1) / 2) *
                35.0; // Increased spacing
            final angle = (index - (selectedCards.length - 1) / 2) *
                0.04; // Slightly reduced angle

            return Positioned(
              left: centerX +
                  offset -
                  65, // Center position + offset - half card width
              child: Transform.rotate(
                angle: angle,
                child: SizedBox(
                  width: 130, // Slightly larger cards
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

  Widget _buildTurnIndicator() {
    if (currentTurnUid == null || participants.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPlayerName =
        participants[currentTurnUid]?['name'] ?? 'Unknown';
    final isCurrentUserTurn = isMyTurn;

    return Container(
      padding: const EdgeInsets.all(12),
      color: isCurrentUserTurn
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      child: Column(
        children: [
          Text(
            'Current Turn:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentPlayerName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCurrentUserTurn
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
          if (isCurrentUserTurn)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'It\'s your turn!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    if (winnerUid == null) return const SizedBox.shrink();

    final winnerName = participants[winnerUid]?['name'] ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          Text(
            'Game Over!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$winnerName is the winner! 🎉',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
        color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Colors.grey[600],
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
                  TextButton.icon(
                    onPressed: isProcessingMove ? null : _skipTurn,
                    icon: const Icon(Icons.skip_next, size: 20),
                    label: const Text('Skip Turn'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
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
                            color:
                                isCurrentUserTurn ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: PlayingCardView(
                          card: CardGameRuleChecker.getCardFromNumber(number),
                          showBack: false,
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

  Widget _buildPlayerCounts() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
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
                        color: isCurrentPlayer
                            ? Theme.of(context).primaryColor
                            : isCurrentUser
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.grey[200],
                        border: Border.all(
                          color: isCurrentPlayer
                              ? Theme.of(context).primaryColor
                              : isCurrentUser
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cardCount.toString(),
                          style: TextStyle(
                            color:
                                isCurrentPlayer ? Colors.white : Colors.black87,
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
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
                Text(
                  player['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentUser ? Colors.blue : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addRandomCardsToNextPlayer(int count) async {
    if (turnOrder.isEmpty) return;

    final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
    final nextPlayerUid = turnOrder[nextTurnIndex];

    // Get current numbers of next player
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');
    final nextPlayerNumbersRef =
        gameRef.child('userNumbers/$nextPlayerUid/numbers');
    final nextPlayerNumbersSnapshot = await nextPlayerNumbersRef.get();

    List<dynamic> nextPlayerNumbers = [];
    if (nextPlayerNumbersSnapshot.exists) {
      nextPlayerNumbers =
          List<dynamic>.from(nextPlayerNumbersSnapshot.value as List);
    }

    // Add random numbers
    for (int i = 0; i < count; i++) {
      final random = (DateTime.now().millisecondsSinceEpoch % 52) + 1;
      nextPlayerNumbers.add(random);
    }

    // Update next player's numbers
    await nextPlayerNumbersRef.set(nextPlayerNumbers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: [
          _buildPlayerCounts(),
          _buildTurnIndicator(),
          Expanded(
            child: _buildSelectedNumbers(),
          ),
          if (winnerUid != null) _buildGameOver() else _buildNumberButtons(),
        ],
      ),
    );
  }
}
