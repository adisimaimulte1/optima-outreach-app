import 'package:flutter/material.dart';

import 'package:optima/screens/inApp/widgets/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/menu.dart';
import 'package:optima/globals.dart';




class ScalableScreenWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isMinimized, double scale) builder;
  final Type sourceType;

  const ScalableScreenWrapper({
    super.key,
    required this.builder,
    required this.sourceType,
  });

  @override
  State<ScalableScreenWrapper> createState() => _ScalableScreenWrapperState();
}

class _ScalableScreenWrapperState extends State<ScalableScreenWrapper> {
  bool _isPinching = false;
  double _currentScale = 1.0;

  static const double _minimizedScale = 0.4;
  static Duration _pinchDuration = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    custom_menu.MenuController.instance.selectSource(widget.sourceType);
  }



  @override
  Widget build(BuildContext context) {
    screenScaleNotifier.value = _currentScale;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Menu(),
          ValueListenableBuilder<double>(
            valueListenable: screenScaleNotifier,
            builder: (context, scale, _) {
              return Stack(
                children: [
                  _buildAnimatedDashboard(),

                  if (isMenuOpenNotifier.value)
                    Center(
                      child: AnimatedScale(
                        scale: scale,
                        duration: Duration.zero,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() => _currentScale = 1.0);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          child: widget.builder(context, _currentScale < 1.0, _currentScale),
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
    final int dynamicMs = shouldMinimize ? (scaleDiff * 800).clamp(100, 600).toInt() : 100;

    _pinchDuration = Duration(milliseconds: dynamicMs);

    screenScaleNotifier.value = _currentScale;
    setState(() {
      _currentScale = targetScale;
    });
  }
}
