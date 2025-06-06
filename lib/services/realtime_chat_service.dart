import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RealtimeChatService {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RealtimeChatService()
      : _database = FirebaseDatabase.instanceFor(
          app: FirebaseDatabase.instance.app,
          databaseURL: 'https://crazy-game-3c761-default-rtdb.firebaseio.com/',
        ) {
    _initializeDatabase();
  }

  // Initialize database connection
  void _initializeDatabase() {
    try {
      // Only enable persistence on non-web platforms
      if (!kIsWeb) {
        _database.setPersistenceEnabled(true);
        _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
      }

      // Set connection state logging
      _database.ref('.info/connected').onValue.listen((event) {
        print('Database connection state: ${event.snapshot.value}');
      });
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add authStateChanges getter
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get database reference with error handling
  DatabaseReference _getRef([String path = '']) {
    try {
      return path.isEmpty ? _database.ref() : _database.ref(path);
    } catch (e) {
      print('Error getting database reference for path $path: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user's online status
      if (userCredential.user != null) {
        await updateUserStatus(true);
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Store user info in database
      if (userCredential.user != null) {
        await storeUserInfo(
          userId: userCredential.user!.uid,
          name: name,
          email: email,
        );
        await updateUserStatus(true);
      }
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  // Store user information
  Future<void> storeUserInfo({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email.toLowerCase(),
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'isOnline': true,
      };

      await _getRef('users/$userId').set(userData);
      print('User info stored successfully for: $email');
    } catch (e) {
      print('Error storing user info: $e');
      rethrow;
    }
  }

  // Update user's online status
  Future<void> updateUserStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _getRef('users/$userId').update({
      'isOnline': isOnline,
      'lastLogin': ServerValue.timestamp,
    });
  }

  // Get user information
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final snapshot = await _getRef('users/$userId').get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final rawData = snapshot.value;
      if (rawData == null) return null;

      return Map<String, dynamic>.from(rawData as Map);
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // Get chat messages stream with participant info
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _getRef('chats/$chatId').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final rawData = event.snapshot.value;
        if (rawData == null) return [];

        if (rawData is! Map) {
          print('Chat data is not a Map');
          return [];
        }

        final data = Map<String, dynamic>.from(rawData as Map);
        final participants = data['participants'];
        final messages = data['messages'];

        if (participants == null || participants is! Map) {
          print('No participants found in chat');
          return [];
        }

        // Get participant names
        final Map<String, String> participantNames = {};
        for (var entry in (participants as Map).entries) {
          final userId = entry.key.toString();
          final userData = entry.value;
          if (userData is Map) {
            participantNames[userId] =
                userData['name']?.toString() ?? 'Unknown';
          }
        }

        // Process messages
        final List<Map<String, dynamic>> messageList = [];
        if (messages != null && messages is Map) {
          for (var entry in (messages as Map).entries) {
            try {
              final messageId = entry.key.toString();
              final messageData = entry.value;
              if (messageData == null || messageData is! Map) continue;

              final data = Map<String, dynamic>.from(messageData as Map);
              final senderId = data['senderId']?.toString();
              if (senderId == null) continue;

              final timestamp = data['timestamp'];
              final timestampMillis = timestamp is num ? timestamp.toInt() : 0;

              messageList.add({
                'id': messageId,
                'senderId': senderId,
                'senderName': participantNames[senderId] ?? 'Unknown',
                'content': data['content']?.toString() ?? '',
                'timestamp': timestampMillis,
                'imageUrl': data['imageUrl']?.toString(),
                'isCurrentUser': senderId == user.uid,
              });
            } catch (e) {
              print('Error processing message: $e');
              continue;
            }
          }
        }

        // Sort messages by timestamp (oldest first)
        messageList.sort(
            (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
        return messageList;
      } catch (e) {
        print('Error processing chat: $e');
        return [];
      }
    });
  }

  // Get chat participant info
  Future<Map<String, dynamic>> getChatParticipantInfo(String chatId) async {
    try {
      final snapshot = await _getRef('group_chats/$chatId/participants').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Chat not found');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception('Invalid chat data');
      }

      final participants = Map<String, dynamic>.from(rawData as Map);
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Find other participant
      final otherParticipant = participants.entries.firstWhere(
        (entry) => entry.key != currentUserId,
        orElse: () => participants.entries.first,
      );

      return {
        'id': otherParticipant.key,
        'name': otherParticipant.value['name']?.toString() ?? 'Unknown',
        'isOnline': otherParticipant.value['isOnline'] == true,
        'lastLogin': otherParticipant.value['lastLogin'],
      };
    } catch (e) {
      print('Error getting chat participant info: $e');
      rethrow;
    }
  }

  // Send a message to either direct or group chat
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? chatType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Cannot send message: User not authenticated');
      return;
    }

    if (chatId.isEmpty) {
      print('Cannot send message: Invalid chat ID');
      return;
    }

    try {
      final timestamp = ServerValue.timestamp;
      final basePath = chatType == 'group' ? 'group_chats' : 'chats';
      final messageRef = _getRef('$basePath/$chatId/messages').push();

      // Get user info for the message
      final userInfo = await getUserInfo(user.uid);
      final userName = userInfo?['name']?.toString() ?? 'Unknown';
      final userEmail = user.email?.toLowerCase() ?? '';

      // Create message object
      final message = {
        'senderId': user.uid,
        'senderName': userName,
        'senderEmail': userEmail,
        'content': content,
        'timestamp': timestamp,
        'type': 'text'
      };

      // Update both message and chat metadata
      final updates = {
        'messages/${messageRef.key}': message,
        'lastMessage': content,
        'lastMessageTime': timestamp,
        'lastMessageSender': user.uid,
      };

      if (chatType == 'group') {
        // For group chats, update in group_chats node
        updates['metadata/lastActivity'] = timestamp;
        updates['metadata/totalMessages'] = ServerValue.increment(1);
        updates['metadata/readBy/${user.uid}'] = timestamp;
        updates['participants/${user.uid}/lastActivity'] = timestamp;
        await _getRef('group_chats/$chatId').update(updates);
      } else {
        // For direct chats, update in chats node with metadata structure
        updates['metadata/participants/${user.uid}/lastActivity'] = timestamp;
        await _getRef('chats/$chatId').update(updates);
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for either direct or group chat
  Stream<List<Map<String, dynamic>>> getMessages(String chatId,
      {String? chatType}) {
    final user = _auth.currentUser;
    if (user == null) {
      print('Cannot get messages: User not authenticated');
      return Stream.value([]);
    }

    if (chatId.isEmpty) {
      print('Cannot get messages: Invalid chat ID');
      return Stream.value([]);
    }

    try {
      final basePath = chatType == 'group' ? 'group_chats' : 'chats';
      return _getRef('$basePath/$chatId').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            print('Chat data is not a Map for $chatId');
            return [];
          }

          final data = Map<String, dynamic>.from(rawData as Map);
          final messages = data['messages'];

          // Get participants based on chat type
          // For group chats, participants are at the root level as per image
          // For direct chats, participants are in metadata
          final participants = chatType == 'group'
              ? data['participants']
              : data['metadata']?['participants'];

          // Get metadata for group chats (for readBy)
          final metadata = chatType == 'group'
              ? data['metadata']
              : data['metadata']?['participants']
                  ?['_metadata']; // Adjust metadata path for direct if needed

          if (participants == null || participants is! Map) {
            print('No participants found in chat $chatId');
            return [];
          }

          // Process messages
          final List<Map<String, dynamic>> messageList = [];
          if (messages != null && messages is Map) {
            for (var entry in (messages as Map).entries) {
              try {
                final messageId = entry.key.toString();
                final messageData = entry.value;
                if (messageData == null || messageData is! Map) continue;

                final data = Map<String, dynamic>.from(messageData as Map);
                final senderId = data['senderId']?.toString();
                if (senderId == null) continue;

                final timestamp = data['timestamp'];
                final timestampMillis =
                    timestamp is num ? timestamp.toInt() : 0;

                messageList.add({
                  'id': messageId,
                  'senderId': senderId,
                  'senderName': data['senderName']?.toString() ?? 'Unknown',
                  'senderEmail': data['senderEmail']?.toString() ?? '',
                  'text': data['content']?.toString() ?? '',
                  'type': data['type']?.toString() ?? 'text',
                  'timestamp': timestampMillis,
                  'isCurrentUser': senderId == user.uid,
                });
              } catch (e) {
                print('Error processing message in $chatId: $e');
              }
            }
          }

          // Sort messages by timestamp (oldest first)
          messageList.sort((a, b) =>
              (a['timestamp'] as int).compareTo(b['timestamp'] as int));
          return messageList;
        } catch (e) {
          print('Error processing chat data stream for $chatId: $e');
          return [];
        }
      });
    } catch (e) {
      print('Error setting up messages stream for $chatId: $e');
      return Stream.value([]);
    }
  }

  // Get user's chats
  Stream<List<Map<String, dynamic>>> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null) return Stream.value([]);

    try {
      return _getRef('group_chats').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            print('User data is not a Map');
            return [];
          }

          final data = Map<String, dynamic>.from(rawData as Map);
          final chats = <Map<String, dynamic>>[];

          // First process group chats
          final groupChats = data['group_chats'] as Map<String, dynamic>? ?? {};
          for (var entry in groupChats.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              // Get participants data
              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null) continue;

              // Check if user's email matches any participant's email
              bool isUserInGroup = false;
              List<String> participantEmails = [];

              for (var participant in participants.values) {
                if (participant is Map) {
                  final participantEmail =
                      participant['email']?.toString().toLowerCase();
                  if (participantEmail != null) {
                    participantEmails.add(participantEmail);
                    if (participantEmail == userEmail) {
                      isUserInGroup = true;
                    }
                  }
                }
              }

              // Only add to chat list if user is a participant
              if (isUserInGroup) {
                final metadata = chatData['metadata'] as Map<String, dynamic>?;
                chats.add({
                  'chatId': chatId,
                  'name': metadata?['name']?.toString() ?? 'Unknown Group',
                  'type': 'group',
                  'lastMessage': chatData['lastMessage']?.toString() ?? '',
                  'lastMessageTime': chatData['lastMessageTime'],
                  'participants': participants,
                  'participantEmails': participantEmails,
                });
              }
            } catch (e) {
              print('Error processing group chat: $e');
              continue;
            }
          }

          // Then process direct chats
          final directChats = data['chats'] as Map<String, dynamic>? ?? {};
          for (var entry in directChats.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null || !participants.containsKey(user.uid))
                continue;

              // Get other participant's info
              final otherParticipant = participants.entries.firstWhere(
                (p) => p.key != user.uid,
                orElse: () => participants.entries.first,
              );

              final otherUserData =
                  otherParticipant.value as Map<String, dynamic>?;
              if (otherUserData == null) continue;

              chats.add({
                'chatId': chatId,
                'name': otherUserData['name']?.toString() ?? 'Unknown',
                'type': 'direct',
                'lastMessage': chatData['lastMessage']?.toString() ?? '',
                'lastMessageTime': chatData['lastMessageTime'],
                'participants': participants,
                'participantEmails': [
                  otherUserData['email']?.toString().toLowerCase() ?? ''
                ],
              });
            } catch (e) {
              print('Error processing direct chat: $e');
            }
          }

          // Sort chats by last message time (newest first)
          chats.sort((a, b) {
            final timeA = a['lastMessageTime'] as int? ?? 0;
            final timeB = b['lastMessageTime'] as int? ?? 0;
            return timeB.compareTo(timeA);
          });

          return chats;
        } catch (e) {
          print('Error processing chats: $e');
          return [];
        }
      });
    } catch (e) {
      print('Error setting up chats stream: $e');
      return Stream.value([]);
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, {String? chatType}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final basePath = chatType == 'group' ? 'group_chats' : 'chats';
    final readPath = chatType == 'group'
        ? '$basePath/$chatId/metadata/readBy/${user.uid}'
        : '$basePath/$chatId/metadata/participants/${user.uid}/lastRead';

    await _getRef(readPath).set(ServerValue.timestamp);
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String chatId, {String? chatType}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    final basePath = chatType == 'group' ? 'group_chats' : 'chats';
    final metadataPath = chatType == 'group'
        ? '$basePath/$chatId/metadata'
        : '$basePath/$chatId/metadata/participants/${user.uid}';

    return _getRef(metadataPath).onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final rawData = event.snapshot.value;
      if (rawData == null) return 0;

      final data = Map<String, dynamic>.from(rawData as Map);
      final lastMessageTime = data['lastMessageTime'] as int? ?? 0;
      final lastRead = chatType == 'group'
          ? (data['readBy']?[user.uid] as int? ?? 0)
          : (data['lastRead'] as int? ?? 0);

      return lastMessageTime > lastRead ? 1 : 0;
    });
  }

  // Search user by email
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    if (email.isEmpty) {
      print('Email is empty');
      return null;
    }

    try {
      final usersRef = _getRef('users');
      final snapshot = await usersRef.get();

      if (!snapshot.exists) {
        print('No users found in database');
        return null;
      }

      final rawData = snapshot.value;
      if (rawData == null) {
        print('Users data is null');
        return null;
      }

      // Ensure we have a Map
      if (rawData is! Map) {
        print('Users data is not a Map');
        return null;
      }

      // Search for user with matching email
      for (var entry in (rawData as Map).entries) {
        try {
          final userId = entry.key?.toString();
          if (userId == null) continue;

          final rawUserData = entry.value;
          if (rawUserData == null) continue;

          // Ensure userData is a Map
          if (rawUserData is! Map) continue;

          final userMap = Map<String, dynamic>.from(rawUserData as Map);
          final userEmail = userMap['email']?.toString();

          if (userEmail == null) {
            print('User $userId has no email field');
            continue;
          }

          if (userEmail.toLowerCase() == email.toLowerCase()) {
            print('Found user: ${userMap['name']} ($userEmail)');
            return {
              'uid': userId,
              'email': userEmail,
              'name': userMap['name']?.toString() ?? email.split('@')[0],
              'isOnline': userMap['isOnline'] == true,
              'lastLogin': userMap['lastLogin'],
            };
          }
        } catch (e) {
          print('Error processing user entry: $e');
          continue;
        }
      }

      print('No user found with email: $email');
      return null;
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }

  // Create or get direct chat
  Future<String> getOrCreateDirectChat(
      String otherUserId, String otherUserName, String otherUserEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Create a unique chat ID for the two users
    final chatId = [currentUser.uid, otherUserId]..sort();
    final chatRef = _getRef().child('chats/${chatId.join('_')}');

    // Check if chat already exists
    final chatSnapshot = await chatRef.get();
    if (!chatSnapshot.exists) {
      // Get current user's email
      final currentUserEmail = currentUser.email ?? '';

      // Create new chat
      await chatRef.set({
        'participants': {
          currentUser.uid: {
            'name': currentUser.displayName ?? 'Unknown',
            'email': currentUserEmail,
          },
          otherUserId: {
            'name': otherUserName,
            'email': otherUserEmail,
          },
        },
        'createdAt': ServerValue.timestamp,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSender': null,
      });
    }

    return chatId.join('_');
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Update user's online status to false
      final userId = currentUserId;
      if (userId != null) {
        await _getRef('users/$userId').update({
          'isOnline': false,
          'lastLogin': ServerValue.timestamp,
        });
      }

      // Sign out from Firebase Auth
      await _auth.signOut();
      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Create a new group chat
  Future<String> createGroupChat({
    required String groupName,
    required List<String> participantEmails,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Get current user's email
    final currentUserEmail = currentUser.email?.toLowerCase();
    if (currentUserEmail == null) throw Exception('User email not found');

    // Create group chat document in group_chats node
    final groupChatRef = _getRef('group_chats').push();
    final groupChatId = groupChatRef.key!;

    // Add current user as admin
    final participants = {
      currentUser.uid: {
        'name': currentUser.displayName ?? 'Unknown',
        'email': currentUserEmail,
        'role': 'admin',
        'joinedAt': ServerValue.timestamp,
        'lastActivity': ServerValue.timestamp,
        'lastRead': ServerValue.timestamp,
      }
    };

    // Add other participants
    for (final email in participantEmails) {
      final userData = await searchUserByEmail(email);
      if (userData != null) {
        participants[userData['uid']] = {
          'name': userData['name'],
          'email': email.toLowerCase(), // Store email in lowercase
          'role': 'member',
          'joinedAt': ServerValue.timestamp,
          'lastActivity': ServerValue.timestamp,
          'lastRead': ServerValue.timestamp,
        };
      }
    }

    // Create the group chat with all necessary data
    await groupChatRef.set({
      // Root level fields based on image structure
      'createdAt': ServerValue.timestamp,
      'createdBy': currentUser.uid,
      'type': 'group',
      'participants': participants,

      // Metadata fields based on image structure
      'metadata': {
        'name': groupName, // Name is under metadata
        'isActive': true,
        'totalMessages': 0,
        'lastActivity': ServerValue.timestamp,
        'readBy': {
          currentUser.uid: ServerValue.timestamp,
        }
      },
      'messages': {} // Initialize empty messages node
    });

    // Also create a reference in the user's chats
    for (final participant in participants.entries) {
      final userId = participant.key;
      await _getRef('users/$userId/chats/$groupChatId').set({
        'type': 'group',
        'name': groupName, // Store name here for user's chat list display
        'joinedAt': ServerValue.timestamp,
        'role': participant.value['role'],
        'lastActivity': ServerValue.timestamp,
        'lastRead': ServerValue.timestamp,
      });
    }

    return groupChatId;
  }

  // Get group chat info
  Future<Map<String, dynamic>> getGroupChatInfo(String groupChatId) async {
    try {
      final snapshot = await _getRef('group_chats/$groupChatId').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Group chat not found');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception('Invalid group chat data');
      }

      final data = Map<String, dynamic>.from(rawData as Map);
      final metadata = data['metadata'] as Map<String, dynamic>?;
      final participants = data['participants'] as Map<String, dynamic>?;

      if (metadata == null || participants == null) {
        throw Exception('Invalid group chat structure');
      }

      return {
        'chatId': groupChatId,
        'name': metadata['name']?.toString() ??
            'Unknown Group', // Read name from metadata
        'type': data['type']?.toString() ?? 'group',
        'createdAt': data['createdAt'],
        'createdBy': data['createdBy']?.toString(),
        'participants': participants,
        'isActive': metadata['isActive'] ?? true,
        'totalMessages': metadata['totalMessages'] ?? 0,
        'lastActivity': metadata['lastActivity'],
        'lastMessage': data['lastMessage']?.toString(),
        'lastMessageTime': data['lastMessageTime'],
        'lastMessageSender': data['lastMessageSender']?.toString(),
        'readBy': metadata['readBy']
      };
    } catch (e) {
      print('Error getting group chat info: $e');
      rethrow;
    }
  }

  // Get user's group chats
  Stream<List<Map<String, dynamic>>> getUserGroupChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _getRef('users/${user.uid}/chats').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final rawData = event.snapshot.value;
        if (rawData == null) return [];

        if (rawData is! Map) {
          print('Chats data is not a Map');
          return [];
        }

        final chatsMap = Map<String, dynamic>.from(rawData as Map);
        final groupChats = <Map<String, dynamic>>[];

        for (var entry in chatsMap.entries) {
          try {
            final chatId = entry.key;
            final chatData = entry.value;
            if (chatData == null || chatData is! Map) continue;

            final data = Map<String, dynamic>.from(chatData as Map);
            if (data['type'] != 'group') continue;

            groupChats.add({
              'chatId': chatId,
              'name': data['name'] ?? 'Unknown Group',
              'type': 'group',
              'role': data['role'] ?? 'member',
              'joinedAt': data['joinedAt'],
            });
          } catch (e) {
            print('Error processing group chat: $e');
            continue;
          }
        }

        // Sort by joinedAt (newest first)
        groupChats.sort((a, b) {
          final timeA = a['joinedAt'] as int? ?? 0;
          final timeB = b['joinedAt'] as int? ?? 0;
          return timeB.compareTo(timeA);
        });

        return groupChats;
      } catch (e) {
        print('Error processing group chats: $e');
        return [];
      }
    });
  }

  // Add participant to group chat
  Future<void> addParticipantToGroup({
    required String groupChatId,
    required String email,
  }) async {
    final userData = await searchUserByEmail(email);
    if (userData == null) throw Exception('User not found');

    await _getRef('chats/$groupChatId/participants/${userData['id']}').set({
      'name': userData['name'],
      'email': email,
      'role': 'member',
      'joinedAt': ServerValue.timestamp,
    });
  }

  // Remove participant from group chat
  Future<void> removeParticipantFromGroup({
    required String groupChatId,
    required String userId,
  }) async {
    await _getRef('chats/$groupChatId/participants/$userId').remove();
  }

  // Get group chat participants
  Future<Map<String, dynamic>> getGroupParticipants(String groupChatId) async {
    try {
      // Read participants from the root level as shown in the image
      final snapshot =
          await _getRef('group_chats/$groupChatId/participants').get();
      if (!snapshot.exists || snapshot.value == null) {
        // Throw a more specific exception for group chats
        throw Exception(
            'Group chat participants not found or invalid data for chat ID: $groupChatId');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception(
            'Invalid group chat participants data for chat ID: $groupChatId');
      }

      return Map<String, dynamic>.from(rawData as Map);
    } catch (e) {
      print('Error getting group chat participants for $groupChatId: $e');
      rethrow;
    }
  }

  // Update group chat name
  Future<void> updateGroupName({
    required String groupChatId,
    required String newName,
  }) async {
    await _getRef('chats/$groupChatId').update({
      'name': newName,
    });
  }

  // Get chat info
  Future<Map<String, dynamic>> getChatInfo(String chatId) async {
    try {
      final snapshot = await _getRef('chats/$chatId').get();
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Chat not found');
      }

      final rawData = snapshot.value;
      if (rawData == null || rawData is! Map) {
        throw Exception('Invalid chat data');
      }

      return Map<String, dynamic>.from(rawData as Map);
    } catch (e) {
      print('Error getting chat info: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String email) async {
    try {
      if (email.isEmpty) {
        return [];
      }

      // Convert email to lowercase for case-insensitive search
      final searchEmail = email.toLowerCase();

      // Use proper indexing with orderByChild
      final querySnapshot = await _getRef()
          .child('users')
          .orderByChild('email')
          .startAt(searchEmail)
          .endAt(searchEmail + '\uf8ff')
          .limitToFirst(10)
          .get();

      if (!querySnapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> users = [];
      querySnapshot.children.forEach((child) {
        try {
          final data = child.value as Map<dynamic, dynamic>;
          final userEmail = data['email']?.toString().toLowerCase() ?? '';

          // Only add users that match the search email
          if (userEmail.contains(searchEmail)) {
            users.add({
              'uid': child.key,
              'name': data['name'] ?? 'Unknown',
              'email': userEmail,
              'isOnline': data['isOnline'] ?? false,
              'lastLogin': data['lastLogin'],
            });
          }
        } catch (e) {
          print('Error processing user data: $e');
        }
      });

      return users;
    } catch (e) {
      if (e.toString().contains('index-not-defined')) {
        print(
            'Firebase index not defined. Please update your database rules to include .indexOn for email field.');
        // Fallback to in-memory filtering if index is not defined
        return _searchUsersInMemory(email);
      }
      print('Error searching users: $e');
      rethrow;
    }
  }

  // Fallback method for when index is not defined
  Future<List<Map<String, dynamic>>> _searchUsersInMemory(String email) async {
    try {
      final searchEmail = email.toLowerCase();
      final snapshot = await _getRef().child('users').get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> users = [];
      snapshot.children.forEach((child) {
        try {
          final data = child.value as Map<dynamic, dynamic>;
          final userEmail = data['email']?.toString().toLowerCase() ?? '';

          if (userEmail.contains(searchEmail)) {
            users.add({
              'uid': child.key,
              'name': data['name'] ?? 'Unknown',
              'email': userEmail,
              'isOnline': data['isOnline'] ?? false,
              'lastLogin': data['lastLogin'],
            });
          }
        } catch (e) {
          print('Error processing user data: $e');
        }
      });

      users.sort((a, b) => a['email'].compareTo(b['email']));
      return users.take(10).toList();
    } catch (e) {
      print('Error in fallback search: $e');
      rethrow;
    }
  }

  // Get only group chats data
  Stream<List<Map<String, dynamic>>> getGroupChatsData() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null) return Stream.value([]);

    try {
      return _getRef('group_chats').onValue.map((event) {
        try {
          if (event.snapshot.value == null) return [];

          final rawData = event.snapshot.value;
          if (rawData == null) return [];

          if (rawData is! Map) {
            print('Group chat data is not a Map');
            return [];
          }

          final data = Map<String, dynamic>.from(rawData as Map);
          final groupChats = <Map<String, dynamic>>[];

          // Process each group chat
          for (var entry in data.entries) {
            try {
              final chatId = entry.key;
              final chatData = entry.value;
              if (chatData == null || chatData is! Map) continue;

              // Get participants data
              final participants =
                  chatData['participants'] as Map<String, dynamic>?;
              if (participants == null) continue;

              // Check if user's email matches any participant's email
              bool isUserInGroup = false;
              List<String> participantEmails = [];
              Map<String, dynamic> participantDetails = {};

              for (var participant in participants.entries) {
                final participantData = participant.value;
                if (participantData is Map) {
                  final participantEmail =
                      participantData['email']?.toString().toLowerCase();
                  if (participantEmail != null) {
                    participantEmails.add(participantEmail);
                    participantDetails[participant.key] = {
                      'name': participantData['name'],
                      'email': participantEmail,
                      'role': participantData['role'],
                      'joinedAt': participantData['joinedAt'],
                      'lastActivity': participantData['lastActivity'],
                      'lastRead': participantData['lastRead'],
                    };
                    if (participantEmail == userEmail) {
                      isUserInGroup = true;
                    }
                  }
                }
              }

              // Only add to chat list if user is a participant
              if (isUserInGroup) {
                final metadata = chatData['metadata'] as Map<String, dynamic>?;
                final messages = chatData['messages'] as Map<String, dynamic>?;

                groupChats.add({
                  'chatId': chatId,
                  'name': metadata?['name']?.toString() ?? 'Unknown Group',
                  'type': 'group',
                  'createdAt': chatData['createdAt'],
                  'createdBy': chatData['createdBy'],
                  'lastMessage': chatData['lastMessage']?.toString() ?? '',
                  'lastMessageTime': chatData['lastMessageTime'],
                  'lastMessageSender': chatData['lastMessageSender'],
                  'metadata': metadata,
                  'participants': participantDetails,
                  'participantEmails': participantEmails,
                  'messages': messages,
                });
              }
            } catch (e) {
              print('Error processing group chat: $e');
              continue;
            }
          }

          // Sort chats by last message time (newest first)
          groupChats.sort((a, b) {
            final timeA = a['lastMessageTime'] as int? ?? 0;
            final timeB = b['lastMessageTime'] as int? ?? 0;
            return timeB.compareTo(timeA);
          });

          return groupChats;
        } catch (e) {
          print('Error processing group chats: $e');
          return [];
        }
      });
    } catch (e) {
      print('Error setting up group chats stream: $e');
      return Stream.value([]);
    }
  }
}
