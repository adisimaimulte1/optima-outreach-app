import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  //await aiVoice.warmUpAssistant("optima-warmup");

  setupGlobalListeners();

  runApp(const Optima());
}

class Optima extends StatefulWidget {
  const Optima({super.key});

  @override
  State<Optima> createState() => _OptimaState();
}

class _OptimaState extends State<Optima> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedScreenNotifier.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setSystemUIOverlay();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appPaused = state == AppLifecycleState.paused;
    if (appPaused && aiVoice.aiSpeaking) {
      aiVoice.pauseImmediately();
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _setSystemUIOverlay();
  }

  void _setSystemUIOverlay() {
    final brightness = SchedulerBinding.instance.window.platformBrightness;
    final isDark = brightness == Brightness.dark;
    isDarkModeNotifier.value = isDark;

    final usedBrightness = isDark ? Brightness.light : Brightness.dark;
    final overlayColor = Colors.transparent.withOpacity(0.002);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarContrastEnforced: true,
        systemStatusBarContrastEnforced: true,
        statusBarColor: overlayColor,
        statusBarIconBrightness: usedBrightness,
        systemNavigationBarColor: overlayColor,
        systemNavigationBarIconBrightness: usedBrightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optima',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(),
      home: ChooseScreen(),
    );
  }
}
