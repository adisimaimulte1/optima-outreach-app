import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/services/cache/local_profile_cache.dart';
import 'package:optima/services/local_storage_service.dart';
import 'package:optima/globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await LocalStorageService().init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    setIsDarkModeNotifier(SchedulerBinding.instance.window.platformBrightness == Brightness.dark);

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) { _setSystemUIOverlay(); });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalProfileCache.clearProfile();
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
    setIsDarkModeNotifier(isDark);

    final usedBrightness = isDark ? Brightness.light : Brightness.dark;
    final overlayColor = Colors.transparent.withOpacity(0.002);

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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Optima',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkModeNotifier.value ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: inAppBackgroundColor,
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: textHighlightedColor,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: textHighlightedColor,
              selectionColor: textHighlightedColor.withOpacity(0.4),
              selectionHandleColor: textHighlightedColor,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: inAppBackgroundColor,
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: textHighlightedColor,
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: textHighlightedColor,
              selectionColor: textHighlightedColor.withOpacity(0.4),
              selectionHandleColor: textHighlightedColor,
            ),
          ),
          home: ChooseScreen(),
        );
      },
    );
  }

}
