import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class RealtimeChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://crazy-game-3c761-default-rtdb.firebaseio.com/',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

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

      await _database.ref('users/$userId').set(userData);
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

    await _database.ref('users/$userId').update({
      'isOnline': isOnline,
      'lastLogin': ServerValue.timestamp,
    });
  }

  // Get user information
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId').get();
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

    return _database.ref('chats/$chatId').onValue.map((event) {
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
      final snapshot =
          await _database.ref('chats/$chatId/metadata/participants').get();
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

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = ServerValue.timestamp;
    final messageRef = _database.ref('chats/$chatId/messages').push();
    final message = {
      'senderId': user.uid,
      'content': content,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };

    // Update both message and chat metadata
    await _database.ref('chats/$chatId').update({
      'messages/${messageRef.key}': message,
      'lastMessage': content,
      'lastMessageTime': timestamp,
      'lastMessageSender': user.uid,
    });
  }

  // Get user's chats
  Stream<List<Map<String, dynamic>>> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database.ref('chats').onValue.map((event) {
      try {
        if (event.snapshot.value == null) return [];

        final rawData = event.snapshot.value;
        if (rawData == null) return [];

        if (rawData is! Map) {
          print('Chats data is not a Map');
          return [];
        }

        final chatsMap = Map<String, dynamic>.from(rawData as Map);
        final chats = <Map<String, dynamic>>[];

        for (var entry in chatsMap.entries) {
          try {
            final chatId = entry.key;
            final rawChat = entry.value;
            if (rawChat == null) continue;

            if (rawChat is! Map) continue;

            final data = Map<String, dynamic>.from(rawChat as Map);
            final participants = data['participants'];

            if (participants == null || participants is! Map) continue;

            final participantsMap =
                Map<String, dynamic>.from(participants as Map);

            // Check if current user is a participant
            if (!participantsMap.containsKey(user.uid)) continue;

            // Get other participant's info
            final otherParticipant = participantsMap.entries.firstWhere(
                (p) => p.key != user.uid,
                orElse: () => participantsMap.entries.first);

            // Get participant info
            final otherUserId = otherParticipant.key;
            final otherUserData = otherParticipant.value;
            if (otherUserData is! Map) continue;

            final otherUserDataMap =
                Map<String, dynamic>.from(otherUserData as Map);
            final otherUserEmail =
                otherUserDataMap['email']?.toString()?.toLowerCase() ?? '';
            final otherUserName =
                otherUserDataMap['name']?.toString() ?? 'Unknown';

            // Get the latest message time
            final lastMessageTime = data['lastMessageTime'];
            final timestamp =
                lastMessageTime is num ? lastMessageTime.toInt() : 0;

            // Get the latest message content
            final lastMessage = data['lastMessage']?.toString() ?? '';
            final lastMessageSender = data['lastMessageSender']?.toString();

            // Check if the current user is the sender of the last message
            final isCurrentUserSender = lastMessageSender == user.uid;

            // Get chat creation info
            final createdAt = data['createdAt'] is num
                ? (data['createdAt'] as num).toInt()
                : 0;

            chats.add({
              'chatId': chatId,
              'name': otherUserName,
              'type': 'direct',
              'lastMessage': lastMessage,
              'lastMessageTime': timestamp,
              'lastMessageSender': lastMessageSender,
              'isCurrentUserSender': isCurrentUserSender,
              'otherUserId': otherUserId,
              'otherUserEmail': otherUserEmail,
              'createdAt': createdAt,
              'isNewChat': timestamp == 0,
              'isUnread': !isCurrentUserSender && timestamp > 0,
            });
          } catch (e) {
            print('Error processing chat: $e');
            continue;
          }
        }

        // Sort chats by:
        // 1. Unread messages first
        // 2. Then by last message time (newest first)
        // 3. Then by creation time (newest first)
        chats.sort((a, b) {
          // First sort by unread status
          final aUnread = a['isUnread'] as bool? ?? false;
          final bUnread = b['isUnread'] as bool? ?? false;
          if (aUnread != bUnread) {
            return aUnread ? -1 : 1;
          }

          // Then by last message time
          final timeA = a['lastMessageTime'] as int? ?? 0;
          final timeB = b['lastMessageTime'] as int? ?? 0;
          if (timeA != timeB) {
            return timeB.compareTo(timeA);
          }

          // Finally by creation time
          final createdA = a['createdAt'] as int? ?? 0;
          final createdB = b['createdAt'] as int? ?? 0;
          return createdB.compareTo(createdA);
        });

        return chats;
      } catch (e) {
        print('Error processing chats: $e');
        return [];
      }
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _database
        .ref('chats/$chatId/metadata/readBy/${user.uid}')
        .set(ServerValue.timestamp);
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String chatId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _database.ref('chats/$chatId/metadata').onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final rawData = event.snapshot.value;
      if (rawData == null) return 0;

      final data = Map<String, dynamic>.from(rawData as Map);
      final lastMessageTime = data['lastMessageTime'] as int? ?? 0;
      final readBy = data['readBy'] as Map<String, dynamic>?;
      final userLastRead = readBy?[user.uid] as int? ?? 0;

      return lastMessageTime > userLastRead ? 1 : 0;
    });
  }

  // Search user by email
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    if (email.isEmpty) {
      print('Email is empty');
      return null;
    }

    try {
      final usersRef = _database.ref('users');
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
    final chatRef = _database.ref().child('chats/${chatId.join('_')}');

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
        await _database.ref('users/$userId').update({
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
}
