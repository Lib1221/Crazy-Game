import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/game_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersRef = _database.ref('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        final users = <Map<String, dynamic>>[];
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map) {
            users.add({
              'uid': key,
              'name': value['name'] ?? 'Unknown',
              'email': value['email'] ?? '',
              'rank': value['rank'] ?? 0,
            });
          }
        });

        // Sort users by rank in descending order
        users.sort((a, b) => (b['rank'] as int).compareTo(a['rank'] as int));

        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateLevel(int rank) {
    return (rank ~/ 5) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameTheme.surfaceColor,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: GameTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: GameTheme.textColor),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameTheme.primaryGradient,
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: GameTheme.accentColor,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadUsers,
                color: GameTheme.accentColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final rank = user['rank'] as int;
                    final level = _calculateLevel(rank);
                    final isTopThree = index < 3;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: GameTheme.surfaceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTopThree
                              ? GameTheme.accentColor
                              : GameTheme.surfaceColor.withOpacity(0.2),
                          width: isTopThree ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isTopThree
                                ? GameTheme.accentColor.withOpacity(0.2)
                                : GameTheme.surfaceColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isTopThree
                                  ? GameTheme.accentColor
                                  : GameTheme.surfaceColor.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isTopThree
                                    ? GameTheme.accentColor
                                    : GameTheme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: GameTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Level $level',
                          style: TextStyle(
                            color: GameTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: GameTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${user['rank']} pts',
                            style: const TextStyle(
                              color: GameTheme.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
