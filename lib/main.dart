import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:optima/screens/choose_screen.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:optima/globals.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(),
  );

  await LocalStorageService().init();
  await LocalCache().initializeAndCacheUserData();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    super.dispose();
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appPaused = state == AppLifecycleState.paused;
    if (appPaused && aiVoice.aiSpeaking) {
      aiVoice.pauseImmediately();
    }
    if (state == AppLifecycleState.resumed && updateSettingsAfterAppResume) {
      _checkNotificationPermission();
      _checkLocationPermission();
      _checkMicrophonePermission();
      updateSettingsAfterAppResume = false;
    }
  }

  Future<void> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final allowed = settings.authorizationStatus == AuthorizationStatus.authorized;

    if (notifications != allowed) {
      notifications = allowed;
      notificationsPermissionNotifier.value = allowed;
      await LocalStorageService().setNotificationsEnabled(allowed);
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    final allowed = status.isGranted;

    if (locationAccess != allowed) {
      locationAccess = allowed;
      locationPermissionNotifier.value = allowed;
      await LocalStorageService().setLocationAccess(allowed);
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    final allowed = status.isGranted;

    if (jamieEnabled != allowed) {
      jamieEnabled = allowed;
      jamieEnabledNotifier.value = allowed;
      await CloudStorageService().saveUserSetting("jamieEnabled", allowed);
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
