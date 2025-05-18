import 'package:flutter/material.dart';
import 'package:get/get.dart';



class CrazyCardGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Crazy Card Game',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/room', page: () => RoomScreen()),
        GetPage(name: '/game', page: () => GameTableScreen()),
        GetPage(name: '/gameover', page: () => GameOverScreen()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(name: '/settings', page: () => SettingsScreen()),
        GetPage(name: '/tutorial', page: () => TutorialScreen()),
        GetPage(name: '/leaderboard', page: () => LeaderboardScreen()),
        GetPage(name: '/invite', page: () => InviteFriendsScreen()),
        GetPage(name: '/matchmaking', page: () => MatchmakingScreen()),
        GetPage(name: '/notifications', page: () => NotificationsScreen()),
        GetPage(name: '/pause', page: () => PauseScreen()),
        GetPage(name: '/error', page: () => ErrorScreen()),
        GetPage(name: '/loading', page: () => LoadingScreen()),
      ],
    );
  }
}

// 1. Splash Screen
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () => Get.offNamed('/login'));

    return Scaffold(
      body: Center(
        child: Text(
          'Crazy Card Game',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// 2. Login Screen
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
              onPressed: () => Get.offNamed('/home'),
              child: Text('Login with Google')),
          SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => Get.offNamed('/home'),
              child: Text('Login with Email')),
          SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => Get.offNamed('/home'), child: Text('Guest Play')),
        ]),
      ),
    );
  }
}

// 3. Home / Lobby Screen
class HomeScreen extends StatelessWidget {
  final List<String> rooms = ['Room 1', 'Room 2', 'Room 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lobby'), actions: [
        IconButton(
            icon: Icon(Icons.person), onPressed: () => Get.toNamed('/profile')),
        IconButton(
            icon: Icon(Icons.settings), onPressed: () => Get.toNamed('/settings')),
        IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: () => Get.toNamed('/leaderboard')),
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(rooms[i]),
                trailing: ElevatedButton(
                    child: Text('Join'), onPressed: () => Get.toNamed('/room')),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: ElevatedButton(
              child: Text('Create New Room'),
              onPressed: () => Get.toNamed('/room'),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Enter Room Code'),
              onSubmitted: (code) {
                // Implement join by code logic here
                Get.toNamed('/room');
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

// 4. Room / Waiting Area Screen
class RoomScreen extends StatelessWidget {
  final List<String> players = ['Alice', 'Bob', 'Charlie'];

  @override
  Widget build(BuildContext context) {
    bool isHost = true; // example flag
    return Scaffold(
      appBar: AppBar(title: Text('Room Waiting Area')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text(players[i][0])),
                title: Text(players[i]),
                trailing: Text('Ready'), // example ready status
              ),
            ),
          ),
          Expanded(
            child: ChatPanel(),
          ),
          if (isHost)
            Padding(
              padding: EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/game'),
                child: Text('Start Game'),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(children: [
        Expanded(
          child: ListView(
            children: [
              ListTile(title: Text('Alice: Hi!')),
              ListTile(title: Text('Bob: Ready to play?')),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: 'Type message...'),
              ),
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.send)),
            IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
          ],
        )
      ]),
    );
  }
}

// 5. Game Table Screen
class GameTableScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simplified example UI for game table
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Table'),
        actions: [
          IconButton(
              icon: Icon(Icons.pause),
              onPressed: () => Get.toNamed('/pause')),
        ],
      ),
      body: Column(
        children: [
          // Last played card in center
          Expanded(
            child: Center(
              child: Card(
                color: Colors.red[100],
                child: Container(
                  width: 120,
                  height: 180,
                  alignment: Alignment.center,
                  child: Text('♥️ 7',
                      style:
                          TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          // Player cards at bottom (only visible to player)
          Container(
            height: 200,
            color: Colors.grey[300],
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(6, (index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Container(
                    width: 80,
                    alignment: Alignment.center,
                    child: Text('♠️ ${index + 2}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
          ),
          // Timer, Drop it, Voice chat buttons
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Icon(Icons.timer, size: 36),
                  SizedBox(height: 4),
                  Text('00:30'),
                ]),
                ElevatedButton(onPressed: () {}, child: Text('Drop It')),
                GestureDetector(
                  onLongPressStart: (_) {
                    // Start voice chat speak
                  },
                  onLongPressEnd: (_) {
                    // Stop voice chat speak
                  },
                  child: CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.mic, size: 32),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 6. Game Over Screen
class GameOverScreen extends StatelessWidget {
  final List<String> rankings = ['Alice', 'Bob', 'Charlie'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Over')),
      body: Column(
        children: [
          SizedBox(height: 24),
          Text('Winner: ${rankings[0]}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: rankings.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text(rankings[i][0])),
                title: Text(rankings[i]),
                trailing: Text(i == 0 ? 'Winner' : 'Position ${i + 1}'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () => Get.offNamed('/home'),
                    child: Text('Leave Room')),
                ElevatedButton(
                    onPressed: () => Get.offNamed('/room'),
                    child: Text('Rematch')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 7. Profile Screen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          CircleAvatar(radius: 50, child: Icon(Icons.person, size: 64)),
          SizedBox(height: 16),
          Text('PlayerName', style: TextStyle(fontSize: 24)),
          SizedBox(height: 16),
          Text('Games Played: 10'),
          Text('Wins: 5'),
          Text('Losses: 5'),
          SizedBox(height: 32),
          ElevatedButton(
              onPressed: () => Get.toNamed('/settings'),
              child: Text('Settings')),
        ]),
      ),
    );
  }
}

// 8. Settings Screen
class SettingsScreen extends StatelessWidget {
  bool soundOn = true;
  bool voiceChatOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
              title: Text('Sound Effects'),
              value: soundOn,
              onChanged: (val) {
                // Implement setState or GetX state update
              }),
          SwitchListTile(
              title: Text('Voice Chat'),
              value: voiceChatOn,
              onChanged: (val) {
                // Implement setState or GetX state update
              }),
          ListTile(
            title: Text('Tutorial'),
            onTap: () => Get.toNamed('/tutorial'),
          ),
          ListTile(
            title: Text('Invite Friends'),
            onTap: () => Get.toNamed('/invite'),
          ),
        ],
      ),
    );
  }
}

// 9. Tutorial Screen
class TutorialScreen extends StatelessWidget {
  final List<String> steps = [
    '1. Join or create a room.',
    '2. Wait for players to join.',
    '3. Start the game when ready.',
    '4. Match cards by number or suit.',
    '5. Use special cards (8, J) to change suit.',
    '6. Avoid picking up penalty cards (1 of Spades).',
    '7. First to discard all cards wins!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tutorial')),
      body: ListView.builder(
        itemCount: steps.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(Icons.check_circle_outline),
          title: Text(steps[i]),
        ),
      ),
    );
  }
}

// 10. Leaderboard Screen
class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaders = [
    {'name': 'Alice', 'wins': 20},
    {'name': 'Bob', 'wins': 15},
    {'name': 'Charlie', 'wins': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard')),
      body: ListView.builder(
        itemCount: leaders.length,
        itemBuilder: (_, i) => ListTile(
          leading: CircleAvatar(child: Text(leaders[i]['name'][0])),
          title: Text(leaders[i]['name']),
          trailing: Text('${leaders[i]['wins']} wins'),
        ),
      ),
    );
  }
}

// 11. Invite Friends Screen
class InviteFriendsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder invite screen
    return Scaffold(
      appBar: AppBar(title: Text('Invite Friends')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement share invite logic
          },
          child: Text('Share Invite Link'),
        ),
      ),
    );
  }
}

// 12. Matchmaking Screen
class MatchmakingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () => Get.offNamed('/game'));
    return Scaffold(
      appBar: AppBar(title: Text('Matchmaking')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// 13. Notifications Screen
class NotificationsScreen extends StatelessWidget {
  final List<String> notifications = [
    'Alice joined the room.',
    'Game starting in 10 seconds.',
    'New leaderboard update!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(Icons.notifications),
          title: Text(notifications[i]),
        ),
      ),
    );
  }
}

// 14. Pause / In-game Settings Screen
class PauseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paused')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () => Get.back(), child: Text('Resume Game')),
          ElevatedButton(
              onPressed: () => Get.offNamed('/home'), child: Text('Quit Game')),
          ElevatedButton(
              onPressed: () => Get.toNamed('/settings'), child: Text('Settings')),
        ],
      ),
    );
  }
}

// 15. Error Screen
class ErrorScreen extends StatelessWidget {
  final String message;

  ErrorScreen({this.message = 'Something went wrong!'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Error')),
      body: Center(
        child: Text(message, style: TextStyle(color: Colors.red, fontSize: 20)),
      ),
    );
  }
}

// 16. Loading Screen
class LoadingScreen extends StatelessWidget {
  final String message;

  LoadingScreen({this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loading')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}
