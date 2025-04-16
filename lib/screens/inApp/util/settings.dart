import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: SettingsScreen,
      builder: (context, isMinimized, scale) {
        return const SafeArea(
          child: Center(
            child: Text(
              "Settings Screen",
              style: TextStyle(
                color: Colors.white,
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
