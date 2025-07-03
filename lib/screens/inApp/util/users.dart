import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenRegistry.register<UsersScreenState>(ScreenType.users, widget.key as GlobalKey<UsersScreenState>);
    });

    super.initState();
  }

  @override
  void dispose() {
    ScreenRegistry.unregister(ScreenType.users);
    super.dispose();
  }

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
