import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/beforeApp/widgets/app_bootstrapper.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/storage/local_storage_service.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return const _NoInternetBody();
  }
}

class _NoInternetBody extends StatefulWidget {
  const _NoInternetBody();

  @override
  State<_NoInternetBody> createState() => _NoInternetBodyState();
}

class _NoInternetBodyState extends State<_NoInternetBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _subscription = Connectivity().onConnectivityChanged.listen((resultList) async {
      final isConnected = resultList.any((r) => r != ConnectivityResult.none);
      if (isConnected && mounted) {
        _subscription?.cancel();

        await Firebase.initializeApp();
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;

        if (!isLoggedIn) {
          await LocalStorageService().init();
          await LocalCache().initializeAndCacheUserData();
          setupGlobalListeners();
        }

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppBootstrapper()),
        );
      }

    });

  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: inAppBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Icon(
                Icons.wifi_off_rounded,
                color: textHighlightedColor,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "You're Offline",
              style: TextStyle(
                fontSize: 28,
                color: textHighlightedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Check your internet connection\nto continue using Optima.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
