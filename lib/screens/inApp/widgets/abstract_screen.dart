import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;

class AbsScreen extends StatefulWidget {
  final Widget Function(BuildContext context, bool isMinimized, double scale) builder;
  final Type sourceType;

  const AbsScreen({
    super.key,
    required this.builder,
    required this.sourceType,
  });

  @override
  State<AbsScreen> createState() => _AbsScreenState();
}

class _AbsScreenState extends State<AbsScreen> {
  bool _isPinching = false;
  double _currentScale = 1.0;

  static const double _minimizedScale = 0.4;
  static Duration _pinchDuration = const Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    _currentScale = screenScaleNotifier.value;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (screenScaleNotifier.value != _currentScale) {
        screenScaleNotifier.value = _currentScale;
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: screenScaleNotifier,
            builder: (context, scale, _) => Stack(
              children: [
                _buildScaledScreen(scale),
                if (isMenuOpenNotifier.value) _buildOverlayTapRegion(scale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaledScreen(double scale) {
    final double cornerRadius = 120.0 * (1 - scale);
    final double borderWidth = 30.0 * (1 - scale);
    final borderColor = isDarkModeNotifier.value
        ? Colors.white
        : const Color(0xFF1C2837);

    return Center(
      child: AnimatedScale(
        duration: _pinchDuration,
        curve: Curves.easeOut,
        scale: scale,
        child: IgnorePointer(
          ignoring: scale < 0.99,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _handleTap,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2837),
                  borderRadius: BorderRadius.circular(cornerRadius),
                  border: borderWidth > 0
                      ? Border.all(width: borderWidth, color: borderColor)
                      : null,
                ),
                child: widget.builder(context, scale < 1.0, scale),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayTapRegion(double scale) {
    return Center(
      child: AnimatedScale(
        scale: scale,
        duration: Duration.zero,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => setState(() => _currentScale = 1.0),
          child: const SizedBox.expand(),
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

    final shouldMinimize = _currentScale < 0.75;
    final targetScale = shouldMinimize ? _minimizedScale : 1.0;
    final scaleDiff = (targetScale - _currentScale).abs();
    final dynamicMs = shouldMinimize ? (scaleDiff * 800).clamp(100, 600).toInt() : 100;

    _pinchDuration = Duration(milliseconds: dynamicMs);

    if (shouldMinimize) {
      custom_menu.MenuController.instance.selectSource(widget.sourceType);
    } else { custom_menu.MenuController.instance.clearSource(); }

    screenScaleNotifier.value = _currentScale;
    setState(() => _currentScale = targetScale);
  }
}
