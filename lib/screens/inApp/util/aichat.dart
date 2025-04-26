import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: ChatScreen,
      builder: (context, isMinimized, scale) {
        return SafeArea(
          child: Center(
            child: Text(
              "AI Chat Screen",
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
