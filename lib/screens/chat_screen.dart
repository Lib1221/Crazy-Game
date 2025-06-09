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
  }

  bool get isMyTurn {
    return currentUserId == currentTurnUid;
  }

  Future<void> _sendNumberToChat(int number) async {
    if (!isMyTurn) return;

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

    // Remove the number from user's numbers immediately
    setState(() {
      currentUserNumbers.remove(number);
    });

    final gameRef = _database.ref('group_chats/${widget.chatId}/game');
    final chatRef = _database.ref('group_chats/${widget.chatId}/messages');

    // Add the number to selectedNumbers array
    final newSelectedNumbers = List<int>.from(selectedNumbers)..add(number);
    await gameRef.child('selectedNumbers').set(newSelectedNumbers);

    // Add a message in the chat
    await chatRef.push().set({
      'uid': currentUserId,
      'email': currentUserEmail,
      'text': 'Selected number $number',
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

    // Always pass to next turn after a valid move
    if (turnOrder.isNotEmpty) {
      final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
      await _database.ref('group_chats/${widget.chatId}/turn').update({
        'currentTurnIndex': nextTurnIndex,
        'lastUpdated': ServerValue.timestamp,
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
      'text': '${participants[currentUserId]?['name']} skipped their turn',
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
                    onPressed: _skipTurn,
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
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            childAspectRatio: 0.7,
            children: currentUserNumbers.map((number) {
              return GestureDetector(
                onTap:
                    isCurrentUserTurn ? () => _sendNumberToChat(number) : null,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentUserTurn ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: PlayingCardView(
                    card: CardGameRuleChecker.getCardFromNumber(number),
                    showBack: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: [
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
