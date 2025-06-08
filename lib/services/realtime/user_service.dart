import 'database_service.dart';

class UserService {
  final DatabaseService _databaseService;

  UserService(this._databaseService);

  // Get user information
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final snapshot = await _databaseService.getRef('users/$userId').get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final rawData = snapshot.value;
      if (rawData == null) return null;

      return Map<String, dynamic>.from(rawData as Map);
    } catch (e) {
      return null;
    }
  }

  // Search user by email
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    if (email.isEmpty) {
      return null;
    }

    try {
      final usersRef = _databaseService.getRef('users');
      final snapshot = await usersRef.get();

      if (!snapshot.exists) {
        return null;
      }

      final rawData = snapshot.value;
      if (rawData == null) {
        return null;
      }

      // Ensure we have a Map
      if (rawData is! Map) {
        return null;
      }

      // Search for user with matching email
      for (var entry in (rawData).entries) {
        try {
          final userId = entry.key?.toString();
          if (userId == null) continue;

          final rawUserData = entry.value;
          if (rawUserData == null) continue;

          // Ensure userData is a Map
          if (rawUserData is! Map) continue;

          final userMap = Map<String, dynamic>.from(rawUserData);
          final userEmail = userMap['email']?.toString();

          if (userEmail == null) {
            continue;
          }

          if (userEmail.toLowerCase() == email.toLowerCase()) {
            return {
              'uid': userId,
              'email': userEmail,
              'name': userMap['name']?.toString() ?? email.split('@')[0],
              'isOnline': userMap['isOnline'] == true,
              'lastLogin': userMap['lastLogin'],
            };
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String email) async {
    try {
      if (email.isEmpty) {
        return [];
      }

      // Convert email to lowercase for case-insensitive search
      final searchEmail = email.toLowerCase();

      // Use proper indexing with orderByChild
      final querySnapshot = await _databaseService
          .getRef()
          .child('users')
          .orderByChild('email')
          .startAt(searchEmail)
          .endAt('$searchEmail\uf8ff')
          .limitToFirst(10)
          .get();

      if (!querySnapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> users = [];
      for (var child in querySnapshot.children) {
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
          rethrow;
        }
      }

      return users;
    } catch (e) {
      if (e.toString().contains('index-not-defined')) {
        // Fallback to in-memory filtering if index is not defined
        return _searchUsersInMemory(email);
      }
      rethrow;
    }
  }

  // Fallback method for when index is not defined
  Future<List<Map<String, dynamic>>> _searchUsersInMemory(String email) async {
    try {
      final searchEmail = email.toLowerCase();
      final snapshot = await _databaseService.getRef().child('users').get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> users = [];
      for (var child in snapshot.children) {
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
          rethrow;
        }
      }

      users.sort((a, b) => a['email'].compareTo(b['email']));
      return users.take(10).toList();
    } catch (e) {
      rethrow;
    }
  }
}
