import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/menu.dart';

import '../choose_first_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isPinching = false;
  double _currentScale = 1.0;


  static const double _minimizedScale = 0.4;
  static Duration _pinchDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Menu(),
          _buildAnimatedDashboard(),
        ],
      ),
    );
  }

  Widget _buildAnimatedDashboard() {
    return Center(
      child: AnimatedScale(
        duration: _pinchDuration,
        curve: Curves.easeOut,
        scale: _currentScale,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: _buildDashboardContent(context),
        ),
      ),
    );
  }




  void _handleTap() {
    if (_currentScale < 1.0 && !_isPinching) {
      setState(() => _currentScale = 1.0);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 2) {
      _isPinching = true;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isPinching && details.pointerCount == 2) {
      final scale = details.scale.clamp(_minimizedScale, 1.0);
      setState(() => _currentScale = scale);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isPinching = false;
    if (!mounted) return;

    final bool shouldMinimize = _currentScale < 0.75;
    final double targetScale = shouldMinimize ? _minimizedScale : 1.0;
    final double scaleDiff = (targetScale - _currentScale).abs();
    final int dynamicMs =
    shouldMinimize ? (scaleDiff * 800).clamp(100, 600).toInt() : 100;

    _pinchDuration = Duration(milliseconds: dynamicMs);
    debugPrint("Pinch duration: $dynamicMs");

    setState(() {
      _currentScale = targetScale;
    });
  }




  Widget _buildDashboardContent(context) {
    final bool isMinimized = _currentScale < 1.0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMinimized ? BorderRadius.circular(10) : BorderRadius.circular(0),
        border: isMinimized
            ? Border.all(
          color: isDark ? Colors.white : Colors.black,
          width: 14,
        )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text("Main Content Area", style: TextStyle(fontSize: 22)),
              ),
            ),

            // 🔓 TEMP LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ChooseFirstScreen()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }


}
