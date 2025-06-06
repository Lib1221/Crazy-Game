import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxString searchEmail = ''.obs;
  final RxString currentChatId = ''.obs;
  final Rx<Map<String, dynamic>?> currentChatUser = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    _listenToMessages();
  }

  void _listenToMessages() {
    if (currentChatId.value.isNotEmpty) {
      _firestore
          .collection('chats')
          .doc(currentChatId.value)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        messages.value = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'text': doc['text'],
                  'senderId': doc['senderId'],
                  'senderName': doc['senderName'],
                  'timestamp': doc['timestamp'],
                })
            .toList();
      });
    }
  }

  Future<void> searchUser(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        currentChatUser.value = userData;
        final otherUserId = querySnapshot.docs.first.id;
        final currentUserId = _auth.currentUser!.uid;
        
        // Create or get chat ID
        final chatId = [currentUserId, otherUserId]..sort();
        currentChatId.value = chatId.join('_');

        // Create chat document if it doesn't exist
        await _firestore.collection('chats').doc(currentChatId.value).set({
          'participants': [currentUserId, otherUserId],
          'lastMessage': null,
          'lastMessageTime': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _listenToMessages();
      } else {
        Get.snackbar(
          'Error',
          'User not found',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (currentChatId.value.isEmpty) return;

    try {
      final currentUser = _auth.currentUser!;
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['name'] ?? currentUser.displayName ?? 'Unknown User';

      final messageData = {
        'text': text,
        'senderId': currentUser.uid,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add message to messages collection
      await _firestore
          .collection('chats')
          .doc(currentChatId.value)
          .collection('messages')
          .add(messageData);

      // Update chat document with last message
      await _firestore.collection('chats').doc(currentChatId.value).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRecentChats() async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .limit(10)
          .get();

      final chats = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final otherUserId = (data['participants'] as List)
            .firstWhere((id) => id != currentUserId);
        
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        chats.add({
          'chatId': doc.id,
          'lastMessage': data['lastMessage'],
          'lastMessageTime': data['lastMessageTime'],
          'user': userDoc.data(),
        });
      }
      return chats;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }
}
