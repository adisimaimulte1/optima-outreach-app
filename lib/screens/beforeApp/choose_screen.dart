import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/util/aichat.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_overlay.dart';



class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  Future<UserState> _getUserState() async {
    if (user != null) {
      try {
        await user!.reload();
        if (user!.emailVerified) {
          return UserState.authenticated;

        } else { debugPrint("⚠️ User is not verified."); }
      } catch (e) { debugPrint('❌ Error reloading user: $e'); }
      return UserState.unverified;
    }

    return UserState.unauthenticated;
  }

  Widget _buildAuthenticatedScreen() {
    return ValueListenableBuilder<ScreenType>(
      valueListenable: selectedScreenNotifier,
      builder: (context, selectedScreen, _) {
        debugPrint("📱 Building screen for: $selectedScreen");
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
            debugPrint("👥 Users screen not implemented, defaulting to dashboard.");
            return const DashboardScreen();
          case ScreenType.contact:
            debugPrint("📞 Contact screen not implemented, defaulting to dashboard.");
            return const DashboardScreen();
        }
      },
    );
  }

  Widget _buildByUserState(UserState state) {
    switch (state) {
      case UserState.authenticated: {
        isInitialLaunch = false;
        return _buildAuthenticatedScreen();

      } case UserState.unauthenticated: {
          if (isInitialLaunch) {
            isInitialLaunch = false;
            return const AnimatedSplashScreen();
          } return const AuthScreen();

      } case UserState.unverified: {
        return const AuthScreen();
      }
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

        final state = snapshot.data!;
        debugPrint("📌 UserState resolved to: $state");

        return AppMenuOverlay(
          child: _buildByUserState(state),
        );
      },
    );
  }
}
