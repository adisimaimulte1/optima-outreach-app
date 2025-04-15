import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/dashboard.dart';
import 'package:optima/screens/inApp/settings.dart';



class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  Future<Widget> _chooseHome() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          return const DashboardScreen();
        } else {
          return const AnimatedSplashScreen();
        }
      } catch (_) {
        return const AnimatedSplashScreen();
      }
    }
    return const AnimatedSplashScreen();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _chooseHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return ValueListenableBuilder<ScreenType>(
            valueListenable: selectedScreenNotifier,
            builder: (context, screen, _) {
              switch (screen) {
                case ScreenType.dashboard:
                  return const DashboardScreen();
                case ScreenType.settings:
                  return const SettingsScreen(); // <-- make sure you import this
              // Add other screens here as needed...
                default:
                  return const DashboardScreen(); // fallback
              }
            },
          );
        } else {
          return const AuthScreen();
        }
      },
    );
  }

}
