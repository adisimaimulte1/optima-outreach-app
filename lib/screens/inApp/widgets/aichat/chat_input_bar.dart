import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:provider/provider.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    if (chat.currentEvent == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 38),
      child: Container(
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: onImage,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.photo, color: textColor),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onSend(),
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: "Ask Jamie something...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSend,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.send, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

