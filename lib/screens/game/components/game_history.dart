import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';
import 'package:crazygame/models/game_state.dart';

class GameHistory extends StatefulWidget {
  const GameHistory({Key? key}) : super(key: key);

  @override
  State<GameHistory> createState() => _GameHistoryState();
}

class _GameHistoryState extends State<GameHistory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Game History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Actions'),
                      ),
                      const PopupMenuItem(
                        value: 'plays',
                        child: Text('Card Plays'),
                      ),
                      const PopupMenuItem(
                        value: 'scores',
                        child: Text('Score Changes'),
                      ),
                    ],
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),

            // History list
            Expanded(
              child: Obx(() {
                final history = _controller.gameHistory;
                final filteredHistory = _filterHistory(history);

                if (filteredHistory.isEmpty) {
                  return const Center(
                    child: Text('No history to display'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final event = filteredHistory[index];
                    return _HistoryItem(event: event);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<GameEvent> _filterHistory(List<GameEvent> history) {
    switch (_filter) {
      case 'plays':
        return history
            .where((e) => e.type == GameEventType.cardPlayed)
            .toList();
      case 'scores':
        return history
            .where((e) => e.type == GameEventType.scoreChanged)
            .toList();
      default:
        return history;
    }
  }
}

class _HistoryItem extends StatelessWidget {
  final GameEvent event;

  const _HistoryItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _getEventIcon(),
        title: Text(event.description),
        subtitle: Text(
          _formatTime(event.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: _getEventTrailing(),
      ),
    );
  }

  Widget _getEventIcon() {
    IconData icon;
    Color color;

    switch (event.type) {
      case GameEventType.cardPlayed:
        icon = Icons.play_circle_outline;
        color = Colors.blue;
        break;
      case GameEventType.scoreChanged:
        icon = Icons.score;
        color = Colors.green;
        break;
      case GameEventType.playerJoined:
        icon = Icons.person_add;
        color = Colors.orange;
        break;
      case GameEventType.playerLeft:
        icon = Icons.person_remove;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget? _getEventTrailing() {
    if (event.type == GameEventType.scoreChanged) {
      return Text(
        '${event.data['score']}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }
    return null;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
