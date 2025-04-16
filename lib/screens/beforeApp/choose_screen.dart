import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_overlay.dart';

enum UserState {
  authenticated,
  unverified,
  unauthenticated,
}

class ChooseScreen extends StatelessWidget {
  ChooseScreen({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    SettingsScreen(),
  ];

  final Map<ScreenType, int> _screenIndexMap = {
    ScreenType.dashboard: 0,
    ScreenType.settings: 1,
  };

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
        return IndexedStack(
          index: _screenIndexMap[selectedScreen] ?? 0,
          children: _screens,
        );
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
      default:
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
