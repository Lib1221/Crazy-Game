import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class NumberAssigner {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String chatId;

  NumberAssigner({required this.chatId});

  /// Assigns 5 unique numbers (1-54) to each participant and saves it
  Future<void> assignNumbersToParticipants(List<String> participantIds) async {
    final random = Random();
    final List<int> allNumbers = List.generate(54, (index) => index + 1);
    allNumbers.shuffle(random);

    // Ensure there are enough numbers
    if (participantIds.length * 5 > 54) {
      throw Exception("Not enough numbers to assign uniquely.");
    }

    final gameDataRef = _database.ref('group_chats/$chatId/game/userNumbers');

    int currentIndex = 0;

    for (final userId in participantIds) {
      // Take next 5 numbers
      final assignedNumbers = allNumbers.sublist(currentIndex, currentIndex + 5);
      currentIndex += 5;

      await gameDataRef.child(userId).set({
        'numbers': assignedNumbers,
        'assignedAt': ServerValue.timestamp,
      });

      print('Assigned to $userId: $assignedNumbers');
    }
  }
}
