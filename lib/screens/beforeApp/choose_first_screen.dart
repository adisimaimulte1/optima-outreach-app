import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/dashboard.dart';



class ChooseFirstScreen extends StatelessWidget {
  const ChooseFirstScreen({super.key});

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
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _chooseHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
