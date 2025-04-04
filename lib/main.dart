import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:optima/screens/choose_first_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Optima());
}


class Optima extends StatefulWidget {
  const Optima({super.key});

  @override
  State<Optima> createState() => _OptimaState();
}

class _OptimaState extends State<Optima> with WidgetsBindingObserver {
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _setSystemUIOverlay();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setSystemUIOverlay();
  }

  void _setSystemUIOverlay() {
    final brightness = SchedulerBinding.instance.window.platformBrightness;
    final isDark = brightness == Brightness.dark;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarContrastEnforced: true,
      systemStatusBarContrastEnforced: true,
      statusBarColor:
      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.002),
      statusBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: isDark
          ? Colors.white.withOpacity(0.002)
          : Colors.black.withOpacity(0.002),
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,)
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
