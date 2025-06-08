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
  List<int> selectedNumbers = [];
  String? currentTurnUid;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
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
    gameRef.child('turn/currentUid').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          currentTurnUid = event.snapshot.value.toString();
        });
      }
    });
  }

  Future<void> _sendNumberToChat(int number) async {
    if (currentUserId == null) return;

    final chatRef = _database.ref('chats/${widget.chatId}/messages');
    final gameRef = _database.ref('group_chats/${widget.chatId}/game');

    // Add a message in the chat
    await chatRef.push().set({
      'uid': currentUserId,
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
    await gameRef.child('userNumbers/$currentUserId').set({
      'numbers': currentUserNumbers,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  Future<void> _loadUserNumbers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userNumbersRef = _databaseService
        .getRef('group_chats/${widget.chatId}/game/userNumbers');

    // Fetch user numbers
    final numbersSnapshot = await userNumbersRef.get();
    if (numbersSnapshot.exists) {
      final numbersData = numbersSnapshot.value as Map<dynamic, dynamic>;
      if (numbersData[uid] != null && numbersData[uid]['numbers'] != null) {
        setState(() {
          currentUserNumbers = List<dynamic>.from(numbersData[uid]['numbers']);
        });
      }
    }
  }

  Widget _buildNumberButtons() {
    if (currentUserNumbers.isEmpty) {
      return const SizedBox.shrink();
    }

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: currentUserNumbers.map((number) {
          return ElevatedButton(
            onPressed: () => _sendNumberToChat(number),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Theme.of(context).primaryColor,
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
          Expanded(
            child: Container(), // Empty container for chat content
          ),
          _buildNumberButtons(),
        ],
      ),
    );
  }
}
