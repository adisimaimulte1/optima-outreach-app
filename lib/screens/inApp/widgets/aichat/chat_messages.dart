import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/typing_dots.dart';

class ChatMessageBubble extends StatelessWidget {
  final Map<String, String> msg;

  const ChatMessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg['role'] == 'user';
    final isThinking = msg['content'] == '...thinking';
    final time = msg['timestamp'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(msg['timestamp']!)).format(context)
        : '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? textHighlightedColor.withOpacity(0.9)
              : inAppForegroundColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: isThinking
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: ChatBubbleThinkingDots(),
              )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.containsKey('replyTo'))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "↪ ${msg['replyTo']}",
                  style: TextStyle(
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            Text(
              msg['content'] ?? '',
              style: TextStyle(
                color: isUser ? inAppForegroundColor : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
                height: 1.4,
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isUser ? inAppBackgroundColor : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
