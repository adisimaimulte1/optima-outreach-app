import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'authentication_screen.dart';
import 'inApp/dashboard.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final animationPath = _getAnimationPath(isDarkMode);
    final footerColor = isDarkMode ? Colors.black : const Color(0xFFFFCD32);

    final scalar = 0.5;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (screenHeight * scalar - screenWidth) * 0.5;

    return Scaffold(
      backgroundColor: footerColor,
      body: Stack(
        children: [
          _buildCenteredAnimation(animationPath, scalar, screenHeight, offset),
          _buildBottomFooter(scalar, screenHeight, footerColor),
          _buildFooterText(screenWidth, scalar, screenHeight),
        ],
      ),
    );
  }

  String _getAnimationPath(bool isDarkMode) {
    return isDarkMode
        ? 'assets/splash/OptimaSplashDark.json'
        : 'assets/splash/OptimaSplash.json';
  }

  Widget _buildCenteredAnimation(String animationPath, double scalar, double screenHeight, double offset) {
    return Center(
      child: Transform.translate(
        offset: Offset(-offset, -5 - screenHeight * (1 - scalar) * 0.5),
        child: SizedBox(
          width: screenHeight * scalar,
          height: screenHeight * scalar,
          child: Lottie.asset(
            animationPath,
            controller: _controller,
            fit: BoxFit.cover,
            onLoaded: _onAnimationLoaded,
          ),
        ),
      ),
    );
  }

  void _onAnimationLoaded(LottieComposition composition) async {
    _controller.duration = composition.duration;
    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () async {
      _controller.stop();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      if (!context.mounted) return;
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;


      if (user != null) {
        try {
          await user.reload();
          final refreshedUser = FirebaseAuth.instance.currentUser;

          if (!refreshedUser!.emailVerified) {
            await FirebaseAuth.instance.signOut();
            _navigateToAuth();
          } else { _navigateToHome(); }
        } catch (e) {
          await FirebaseAuth.instance.signOut();
        }
      } else {
        _navigateToAuth();
      }
    });
  }



  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 1200),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }



  Widget _buildBottomFooter(double scalar, double screenHeight, Color footerColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 7 + screenHeight * (1 - scalar),
      child: Container(color: footerColor),
    );
  }

  Widget _buildFooterText(double screenWidth, double scalar, double screenHeight) {
    return Positioned(
      bottom: (7 + screenHeight * (1 - scalar)) / 2 - 20,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: screenWidth * 0.35,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'powered by',
                style: TextStyle(
                  fontFamily: 'Tusker',
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1C2837),
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          SizedBox(
            width: screenWidth * 0.7,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'OPTIMA',
                style: TextStyle(
                  fontFamily: 'Tusker',
                  fontSize: 90,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C2837),
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
