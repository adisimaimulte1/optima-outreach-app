import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/util/aichat.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_overlay.dart';

enum UserState {
  authenticated,
  unverified,
  unauthenticated,
}

class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  Future<UserState> _getUserState() async {
    if (user != null) {
      try {
        await user!.reload();
        if (user!.emailVerified) {
          return UserState.authenticated;
        }
      } catch (e) {
        debugPrint('Error reloading user: $e');
      }
      return UserState.unverified;
    }
    return UserState.unauthenticated;
  }

  Widget _buildAuthenticatedScreen() {
    return ValueListenableBuilder<ScreenType>(
      valueListenable: selectedScreenNotifier,
      builder: (context, selectedScreen, _) {
        switch (selectedScreen) {
          case ScreenType.dashboard:
            return const DashboardScreen();
          case ScreenType.settings:
            return const SettingsScreen();
          case ScreenType.chat:
            return const ChatScreen();
          case ScreenType.events:
            return const EventsScreen();
          case ScreenType.users:
            // TODO: Handle this case.
            return const DashboardScreen();
          case ScreenType.contact:
            // TODO: Handle this case.
            return const DashboardScreen();
            }
          },
        );
  }

  Widget _buildByUserState(UserState state) {
    switch (state) {
      case UserState.authenticated:
        return _buildAuthenticatedScreen();
      case UserState.unverified:
        return const AnimatedSplashScreen();
      case UserState.unauthenticated:
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserState>(
      future: _getUserState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AppMenuOverlay(
          child: _buildByUserState(snapshot.data!),
        );
      },
    );
  }
}
