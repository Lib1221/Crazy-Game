import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crazygame/controllers/game_controller.dart';

class ChatArea extends StatelessWidget {
  const ChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: controller.chatMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(controller.chatMessages[index]),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (message) {
                    if (message.isNotEmpty) {
                      controller.sendChatMessage(message);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  // Handle send message
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
