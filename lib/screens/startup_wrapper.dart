import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:optima/main.dart';
import 'package:optima/screens/beforeApp/no_internet_screen.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/storage/local_storage_service.dart';

class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  final ValueNotifier<String> _statusText = ValueNotifier("Starting...");

  late Future<Widget> _future;
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  double _target = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _future = _initApp();
  }

  Future<void> _animateTo(double value, String label) async {
    _statusText.value = label;
    _target = value;
    _progressAnim = Tween<double>(begin: _progress.value, end: _target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    )..addListener(() {
      _progress.value = _progressAnim.value;
    });
    await _animController.forward(from: 0);
  }

  Future<Widget> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 50));

    await _animateTo(0.2, "Checking internet...");
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.first == ConnectivityResult.none) return const NoInternetScreen();

    await _animateTo(0.4, "Initializing Firebase...");
    await LocalStorageService().init();
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // .debug for dev
      appleProvider: AppleProvider.debug, // .debug for dev
    );
    await Firebase.initializeApp();

    await _animateTo(0.6, "Starting AdMob...");
    await MobileAds.instance.initialize();

    await _animateTo(0.7, "Getting public data...");
    await getPublicData();

    bool done = false;
    double progress = 0.7;

    final timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (done) return t.cancel();
      if (progress < 0.79) {
        progress += 0.02;
        _animateTo(progress, "Caching user data...");
      }
    });

    await LocalCache().initializeAndCacheUserData();
    done = true;

    await _animateTo(1.0, "Finalizing...");
    setupGlobalListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    return const Optima();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: inAppBackgroundColor,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (context, value, _) {
                      return LiquidFillText(value: value);
                    },
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<String>(
                    valueListenable: _statusText,
                    builder: (context, label, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          label,
                          key: ValueKey(label),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}



class LiquidFillText extends StatefulWidget {
  final double value;
  const LiquidFillText({super.key, required this.value});

  @override
  State<LiquidFillText> createState() => _LiquidFillTextState();
}

class _LiquidFillTextState extends State<LiquidFillText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return _createLiquidWaveShader(bounds, widget.value, _controller.value);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            'OPTIMA',
            style: const TextStyle(
              fontFamily: 'Tusker',
              fontSize: 68,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Shader _createLiquidWaveShader(Rect bounds, double progress, double wavePhase) {
    final waveHeight = bounds.height * 0.1;
    final baseY = bounds.height * (1 - progress);
    final path = Path();

    path.moveTo(0, bounds.bottom);
    for (double x = 0; x <= bounds.width; x++) {
      final y = baseY + waveHeight * sin((x / bounds.width * 2 * pi) + wavePhase * 2 * pi);
      path.lineTo(x, y);
    }
    path.lineTo(bounds.width, bounds.bottom);
    path.close();

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [textSecondaryHighlightedColor, textHighlightedColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds);

    canvas.drawPath(path, paint);

    final picture = pictureRecorder.endRecording();
    return ImageShader(picture.toImageSync(bounds.width.toInt(), bounds.height.toInt()),
        TileMode.clamp, TileMode.clamp, Matrix4.identity().storage);
  }
}
