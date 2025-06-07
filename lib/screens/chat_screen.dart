import 'package:crazygame/services/realtime/realtime_chat_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatType;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final ScrollController _scrollController = ScrollController();
  late final GlobalKey _chatKey;
  Map<String, dynamic>? _participantInfo;
  Map<String, dynamic>? _groupInfo;
  bool _isGroupChat = false;
  Set<int> _selectedNumbers = {};
  Map<int, String> _numberSelectors = {};
  String? _currentTurnUserId;
  List<String> _turnOrder = [];
  int _currentTurnIndex = 0;
  bool _isGameStarted = false;
  List<Map<String, dynamic>> _participantEmails = [];
  Timer? _gameTimer;
  int _remainingSeconds = 0;
  int? _selectedNumber;

  @override
  void initState() {
    super.initState();
    _chatKey = _chatService.getChatKey(widget.chatId);
    _loadChatInfo();
    _markMessagesAsRead();
    // Reset game state when starting
    if (_isGroupChat) {
      _chatService.resetGameState(widget.chatId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _gameTimer?.cancel();
    _chatService.disposeKeys(widget.chatId);
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    try {
      final chatData = await _chatService.getChatParticipantInfo(widget.chatId);
      _isGroupChat = chatData['type'] == 'group' || chatData['isGroup'] == true;
      _participantEmails = [];

      if (_isGroupChat) {
        final participants =
            await _chatService.getGroupParticipants(widget.chatId);

        // Initialize turn order based on email sequence
        if (_participantEmails.isNotEmpty && _turnOrder.isEmpty) {
          _turnOrder =
              _participantEmails.map((p) => p['id'] as String).toList();
          _currentTurnIndex = 0;
          _currentTurnUserId = _turnOrder[0];
          _isGameStarted = true;

          // Store initial turn information in realtime database for group chats
          if (_isGroupChat && _currentTurnUserId != null) {
            _chatService.updateGroupChatTurn(
              groupChatId: widget.chatId,
              currentTurnUserId: _currentTurnUserId!,
              currentTurnIndex: _currentTurnIndex,
              turnOrder: _turnOrder,
            );
          }

          // Send system message about turn order
          String turnOrderText = _participantEmails.map((p) {
            if (p['id'] == _chatService.currentUserId) {
              return 'You';
            }
            return p['email'];
          }).join(' → ');

          _chatService.sendMessage(
            chatId: widget.chatId,
            content: 'Game started! Turn order: $turnOrderText',
            chatType: _isGroupChat ? 'group' : null,
          );
        }

        // Extract and validate participant emails
        participants.forEach((userId, participantData) {
          if (participantData is Map<String, dynamic>) {
            final email = participantData['email'];
            final name = participantData['name'];
            final role = participantData['role'];

            if (email != null && email is String && email.contains('@')) {
              _participantEmails.add({
                'id': userId,
                'email': email.toLowerCase().trim(),
                'name': (name is String && name.trim().isNotEmpty)
                    ? name.trim()
                    : 'Unknown',
                'role': (role is String && role.trim().isNotEmpty)
                    ? role.trim()
                    : 'member',
              });
            }
          }
        });
      } else {
        // For direct chat, add both participants
        if (chatData['email'] != null &&
            chatData['email'].toString().contains('@')) {
          _participantEmails.add({
            'id': chatData['id'],
            'email': chatData['email'].toString().toLowerCase().trim(),
            'name': chatData['name'] ?? 'Unknown',
            'role': 'member',
          });
        }
      }

      if (mounted) {
        setState(() {
          if (_isGroupChat) {
            _groupInfo = {
              'name': chatData['name'] ?? 'Group Chat',
              'participants': chatData['participants'] ?? {},
            };
          } else {
            _participantInfo = chatData;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(
      widget.chatId,
      chatType: _isGroupChat ? 'group' : null,
    );
  }

  bool get _isMyTurn {
    if (!_isGameStarted) return false;

    // Get current user's email from participant emails
    final currentUserParticipant = _participantEmails.firstWhere(
      (p) => p['id'] == _chatService.currentUserId,
      orElse: () => {'email': '', 'role': 'member'},
    );
    final currentUserEmail =
        currentUserParticipant['email'].toString().toLowerCase();

    // Find current turn participant
    final currentTurnParticipant = _participantEmails.firstWhere(
      (p) => p['id'] == _currentTurnUserId,
      orElse: () => {'email': '', 'role': 'member'},
    );

    // Check if current user's email matches the current turn participant's email
    return currentTurnParticipant['email'].toString().toLowerCase() ==
        currentUserEmail;
  }

  void _nextTurn() {
    if (_turnOrder.isEmpty) return;

    // Move to next turn
    _currentTurnIndex = (_currentTurnIndex + 1) % _turnOrder.length;
    _currentTurnUserId = _turnOrder[_currentTurnIndex];

    // Find current player's info
    final currentPlayer = _participantEmails.firstWhere(
      (p) => p['id'] == _currentTurnUserId,
      orElse: () =>
          {'name': 'Unknown', 'role': 'member', 'email': 'unknown@email.com'},
    );

    // Update turn information in realtime database for group chats
    if (_isGroupChat && _currentTurnUserId != null) {
      _chatService.updateGroupChatTurn(
        groupChatId: widget.chatId,
        currentTurnUserId: _currentTurnUserId!,
        currentTurnIndex: _currentTurnIndex,
        turnOrder: _turnOrder,
      );
    }

    // Send a system message about whose turn it is
    String nextPlayerName = _currentTurnUserId == _chatService.currentUserId
        ? 'You'
        : currentPlayer['name'].toString();

    String roleText = currentPlayer['role'] == 'admin' ? ' (Admin)' : '';

    _chatService.sendMessage(
      chatId: widget.chatId,
      content: "It's $nextPlayerName$roleText's turn!",
      chatType: _isGroupChat ? 'group' : null,
    );
  }

  void _sendNumber(int number) {
    if (!_isGameStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game has not started yet')),
      );
      return;
    }

    if (!_isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for your turn')),
      );
      return;
    }

    if (_selectedNumbers.contains(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This number has already been selected')),
      );
      return;
    }

    // Get current player's info
    final currentPlayer = _participantEmails.firstWhere(
      (p) => p['id'] == _chatService.currentUserId,
      orElse: () => {'name': 'Unknown', 'role': 'member'},
    );

    // Update game state in realtime database
    _chatService.updateGameState(
      chatId: widget.chatId,
      number: number,
      userId: _chatService.currentUserId!,
    );

    // Send message about the number selection with player info
    _chatService.sendMessage(
      chatId: widget.chatId,
      content: '${currentPlayer['name']} selected number $number',
      chatType: _isGroupChat ? 'group' : null,
    );

    // Move to next turn
    _nextTurn();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showAddParticipantDialog() async {
    final TextEditingController emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter participant\'s email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await _chatService.addParticipantToGroup(
                    groupChatId: widget.chatId,
                    email: email,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Participant added successfully')),
                    );
                    _loadChatInfo(); // Refresh participants list
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding participant: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList() {
    if (!_isGroupChat || _groupInfo == null) return;

    final participants = _groupInfo!['participants'] as Map<String, dynamic>;
    final participantList = participants.entries.toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _showAddParticipantDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: participantList.length,
                itemBuilder: (context, index) {
                  final participant = participantList[index];
                  final isAdmin = participant.value['role'] == 'admin';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.value['name'][0].toUpperCase()),
                    ),
                    title: Text(participant.value['name']),
                    subtitle: Text(participant.value['email']),
                    trailing: isAdmin
                        ? const Chip(
                            label: Text('Admin'),
                            backgroundColor: Colors.blue,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGameTimer() {
    _remainingSeconds = 60; // 1 minute timer
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _gameTimer?.cancel();
          _isGameStarted = false;
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showGameStartConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Start Game'),
        content: const Text('Are you ready to start the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Ready'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ready'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Send ready status to other player
      await _chatService.sendMessage(
        chatId: widget.chatId,
        content: 'I am ready to start the game!',
      );
    }
  }

  Future<void> _selectNumber() async {
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select a Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            10,
            (index) => ListTile(
              title: Text('${index + 1}'),
              onTap: () => Navigator.pop(context, index + 1),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedNumber = result;
      });
      // Send selected number to other player
      await _chatService.sendMessage(
        chatId: widget.chatId,
        content: 'I have selected my number!',
      );
    }
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _selectedNumber = null;
    });
    _startGameTimer();
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    final content = message['content'] as String;

    if (content.contains('ready to start the game')) {
      // Show confirmation that other player is ready
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Other player is ready to start the game!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (content.contains('selected my number')) {
      // Show confirmation that other player has selected their number
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Other player has selected their number!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _isGroupChat
        ? (_groupInfo?['name'] as String? ?? widget.chatName)
        : (_participantInfo?['name'] as String? ?? widget.chatName);

    return Scaffold(
      key: _chatKey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName),
            if (!_isGroupChat && _participantInfo?['isOnline'] == true)
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            if (_isGameStarted) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (_selectedNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Selected Number: $_selectedNumber',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          if (_isGroupChat)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: _showParticipantsList,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<Map<String, dynamic>>(
              stream: _chatService.getGroupChatTurn(widget.chatId),
              builder: (context, turnSnapshot) {
                if (turnSnapshot.hasData) {
                  final turnData = turnSnapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _currentTurnUserId = turnData['currentTurnUserId'];
                        _currentTurnIndex = turnData['currentTurnIndex'] ?? 0;
                        _turnOrder =
                            List<String>.from(turnData['turnOrder'] ?? []);
                        _isGameStarted = true;
                      });
                    }
                  });
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: _isMyTurn ? Colors.green[100] : Colors.grey[200],
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _isMyTurn
                              ? 'Your turn!'
                              : 'Waiting for other player...',
                          style: TextStyle(
                            color: _isMyTurn
                                ? Colors.green[700]
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isGameStarted)
                          const Text(
                            'Game will start when all players join',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        if (_isGameStarted && _participantEmails.isNotEmpty)
                          Text(
                            'Current turn: ${_participantEmails.firstWhere(
                              (p) => p['id'] == _currentTurnUserId,
                              orElse: () =>
                                  {'name': 'Unknown', 'role': 'member'},
                            )['name']} (${_participantEmails.firstWhere(
                              (p) => p['id'] == _currentTurnUserId,
                              orElse: () =>
                                  {'name': 'Unknown', 'role': 'member'},
                            )['role']})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  for (var message in messages) {
                    if (!message['isCurrentUser']) {
                      _handleIncomingMessage(message);
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message['isCurrentUser'] ?? false;
                      final content = message['content']?.toString() ?? '';
                      final isSystemMessage = content.startsWith("It's") ||
                          content.contains('Game started');
                      final isNumberSelection =
                          content.contains('selected number');
                      final isReadyMessage =
                          content.contains('ready to start the game');

                      // Get the selected number if it's a number selection message
                      int? selectedNumber;
                      if (isNumberSelection) {
                        final numberMatch = RegExp(r'selected number (\d+)')
                            .firstMatch(content);
                        if (numberMatch != null) {
                          selectedNumber =
                              int.tryParse(numberMatch.group(1) ?? '');
                        }
                      }

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSystemMessage
                                ? Colors.amber[100]
                                : isNumberSelection
                                    ? Colors.green[100]
                                    : isReadyMessage
                                        ? Colors.blue[100]
                                        : isCurrentUser
                                            ? Colors.blue[100]
                                            : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser && !isSystemMessage)
                                Text(
                                  message['senderName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              if (isNumberSelection && selectedNumber != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      content,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: Text(
                                        selectedNumber.toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: isSystemMessage ? 14 : 16,
                                    fontWeight: isSystemMessage
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isSystemMessage
                                        ? Colors.amber[900]
                                        : Colors.black,
                                  ),
                                ),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isMyTurn
                        ? 'Select a number (1-10)'
                        : 'Waiting for your turn...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isMyTurn ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: _chatService.getGameState(widget.chatId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final gameState = snapshot.data!;
                          try {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  // Handle selectedNumbers as List
                                  final selectedNumbersList =
                                      gameState['selectedNumbers']
                                              as List<dynamic>? ??
                                          [];
                                  _selectedNumbers = Set<int>.from(
                                    selectedNumbersList
                                        .map((n) => int.parse(n.toString())),
                                  );

                                  // Handle numberSelectors as Map
                                  final numberSelectorsMap =
                                      gameState['numberSelectors']
                                              as Map<dynamic, dynamic>? ??
                                          {};
                                  _numberSelectors = Map<int, String>.from(
                                    numberSelectorsMap.map(
                                      (k, v) => MapEntry(
                                          int.parse(k.toString()),
                                          v.toString()),
                                    ),
                                  );
                                });
                              }
                            });
                          } catch (e) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedNumbers = {};
                                  _numberSelectors = {};
                                });
                              }
                            });
                          }
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 2; i++)
                              SizedBox(
                                height: 70,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var j = 0; j < 5; j++)
                                      Expanded(
                                        child:
                                            _buildNumberButton(i * 5 + j + 1),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildGameControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isSelected = _selectedNumbers.contains(number);
    final selectorId = _numberSelectors[number];
    final isSelectedByCurrentUser = selectorId == _chatService.currentUserId;
    final isCurrentUserTurn = _isMyTurn;

    return GestureDetector(
      onTap:
          (!isCurrentUserTurn || isSelected) ? null : () => _sendNumber(number),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isSelectedByCurrentUser ? Colors.green : Colors.grey)
              : (isCurrentUserTurn
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 20,
                  color: isSelected ? Colors.grey[400] : Colors.white,
                ),
              ),
              if (isSelected)
                Text(
                  isSelectedByCurrentUser ? 'You' : 'Selected',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelectedByCurrentUser
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _isGameStarted ? null : _showGameStartConfirmation,
          child: const Text('Ready'),
        ),
        ElevatedButton(
          onPressed: _isGameStarted ? null : _startGame,
          child: const Text('Start Game'),
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
