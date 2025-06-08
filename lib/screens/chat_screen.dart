import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/realtime/database_service.dart';
import '../services/realtime/realtime_chat_service.dart';

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
  final _databaseService = DatabaseService();
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

    // Listen for turn changes and print all turn data
    _database.ref('group_chats/${widget.chatId}/turn').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final turnData = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          turnOrder = List<String>.from(turnData['turnOrder'] ?? []);
          currentTurnIndex = turnData['currentTurnIndex'] ?? 0;
          currentTurnUid =
              turnOrder.isNotEmpty ? turnOrder[currentTurnIndex] : null;
        });

        print('\n=== Turn Data from Database ===');
        print('Turn Order: $turnOrder');
        print('Current Turn Index: $currentTurnIndex');
        print('Current Turn UID: $currentTurnUid');
        print('My UID: $currentUserId');
        print('Is My Turn: ${currentUserId == currentTurnUid}');
        print('===============================\n');
      } else {
        print('\n=== Turn Data from Database ===');
        print('No turn data available');
        print('===============================\n');
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
        print('=== Participants Information ===');
        print('Total Participants: ${participants.length}');
        participants.forEach((uid, data) {
          print('UID: $uid');
          print('Email: ${data['email']}');
          print('Name: ${data['name']}');
          print('---');
        });
        print('============================');
      }
    });
  }

  bool get isMyTurn {
    return currentUserId == currentTurnUid;
  }

  Future<void> _sendNumberToChat(int number) async {
    if (!isMyTurn) {
      print(
          'Not your turn! Current turn: $currentTurnUid, Your UID: $currentUserId');
      return;
    }

    print('=== Sending Number ===');
    print('Number: $number');
    print('Current Turn: $currentTurnUid');
    print('My UID: $currentUserId');
    print('====================');

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

    // Remove the number from user's numbers
    setState(() {
      currentUserNumbers.remove(number);
    });

    // Update the user's numbers in the database
    await gameRef.child('userNumbers/$currentUserId').update({
      'numbers': currentUserNumbers,
      'assignedAt': ServerValue.timestamp,
    });

    // Calculate next turn
    if (turnOrder.isEmpty) return;
    final nextTurnIndex = (currentTurnIndex + 1) % turnOrder.length;
    final nextUid = turnOrder[nextTurnIndex];

    print('\n=== Updating Turn ===');
    print('Current Turn Index: $currentTurnIndex');
    print('Next Turn Index: $nextTurnIndex');
    print('Current Player: $currentTurnUid');
    print('Next Player: $nextUid');
    print('Turn Order: $turnOrder');
    print('===================\n');

    // Update turn in database
    await _database.ref('group_chats/${widget.chatId}/turn').update({
      'currentTurnIndex': nextTurnIndex,
      'lastUpdated': ServerValue.timestamp,
    });
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

    return ListView.builder(
      itemCount: selectedNumbers.length,
      itemBuilder: (context, index) {
        final number = selectedNumbers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Number $number was selected',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
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

  Widget _buildNumberButtons() {
    if (currentUserNumbers.isEmpty) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentUserNumbers.map((number) {
              return ElevatedButton(
                onPressed:
                    isCurrentUserTurn ? () => _sendNumberToChat(number) : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: isCurrentUserTurn
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          _buildNumberButtons(),
        ],
      ),
    );
  }
}
