import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: UsersScreen,
      builder: (context, isMinimized, scale) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Text(
                'Users Screen',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
