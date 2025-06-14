import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: ContactScreen,
      builder: (context, isMinimized, scale) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Text(
                'Contact Screen',
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
