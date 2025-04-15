import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:optima/screens/beforeApp/choose_first_screen.dart';
import 'package:optima/globals.dart';
import 'package:optima/update.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  // this is for when you actually want to use the AI voice. Not while testing lol
  //await aiVoice.warmUpAssistant("optima-warmup");

  setupGlobalListeners();
  runApp(Optima());
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
    selectedScreenNotifier.addListener(updateUI);
    _setSystemUIOverlay();
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

    isDarkModeNotifier.value = brightness == Brightness.dark;
    Brightness usedBrightness =
    isDarkModeNotifier.value ? Brightness.light : Brightness.dark;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarContrastEnforced: true,
      systemStatusBarContrastEnforced: true,
      statusBarColor:
      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.002),
      statusBarIconBrightness: usedBrightness,
      systemNavigationBarColor: isDarkModeNotifier.value
          ? Colors.white.withOpacity(0.002)
          : Colors.black.withOpacity(0.002),
      systemNavigationBarIconBrightness: usedBrightness,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optima',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const ChooseFirstScreen(),
    );
  }
}
