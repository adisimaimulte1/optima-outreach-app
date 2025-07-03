import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/main.dart';
import 'package:optima/screens/beforeApp/no_internet_screen.dart';
import 'package:optima/screens/inApp/widgets/tutorial/touch_blocker.dart';
import 'package:optima/screens/startup_wrapper.dart';
import 'package:optima/services/cache/local_cache.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        final theme = ThemeData.light().copyWith(
          scaffoldBackgroundColor: inAppBackgroundColor,
          progressIndicatorTheme: ProgressIndicatorThemeData(color: textHighlightedColor),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: textHighlightedColor,
            selectionColor: textHighlightedColor.withOpacity(0.4),
            selectionHandleColor: textHighlightedColor,
          ),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          }),
        );

        final darkTheme = ThemeData.dark().copyWith(
          scaffoldBackgroundColor: inAppBackgroundColor,
          progressIndicatorTheme: ProgressIndicatorThemeData(color: textHighlightedColor),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: textHighlightedColor,
            selectionColor: textHighlightedColor.withOpacity(0.4),
            selectionHandleColor: textHighlightedColor,
          ),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          }),
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              MaterialApp(
                title: 'Optima',
                debugShowCheckedModeBanner: false,
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                theme: theme,
                darkTheme: darkTheme,
                home: const AppBootstrapper(),
                builder: (context, child) {
                  final mq = MediaQuery.of(context);
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaleFactor: 1.0,
                      boldText: false,
                    ),
                    child: child!,
                  );
                },
              ),
              TouchBlocker(),
            ],
          ),
        );
      },
    );
  }
}





class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool hasConnection = true;
  bool initialized = false;
  late Widget mainApp;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final connection = await Connectivity().checkConnectivity();

    if (connection.first == ConnectivityResult.none) {
      setState(() => hasConnection = false);
      return;
    }

    // Initialize Firebase if it's not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Wait for Firebase to restore the auth state
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final completer = Completer<User?>();
      StreamSubscription<User?>? sub;

      sub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (!completer.isCompleted) {
          completer.complete(u);
        }
        sub?.cancel();
      });

      user = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    }

    final isLoggedIn = user != null;

    if (!isLoggedIn) {
      await LocalCache().initializeAndCacheUserData();
      setupGlobalListeners();
    }

    mainApp = isLoggedIn ? const StartupWrapper() : const Optima();
    setState(() => initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasConnection) return const NoInternetScreen();
    if (!initialized) {
      return Scaffold(
        backgroundColor: inAppBackgroundColor,
      );
    }
    return mainApp;
  }

}
