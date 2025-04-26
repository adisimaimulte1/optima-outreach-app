import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;

class AbsScreen extends StatefulWidget {
  final Widget Function(BuildContext context, bool isMinimized, double scale) builder;
  final Type sourceType;

  final void Function(ScaleStartDetails)? onScaleStart;
  final void Function(ScaleUpdateDetails)? onScaleUpdate;
  final void Function(ScaleEndDetails)? onScaleEnd;

  const AbsScreen({
    super.key,
    required this.builder,
    required this.sourceType,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  @override
  State<AbsScreen> createState() => _AbsScreenState();
}

class _AbsScreenState extends State<AbsScreen> {
  double _currentScale = 1.0;
  bool _isPinching = false;
  static const double _minimizedScale = 0.4;
  static Duration _pinchDuration = const Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    _currentScale = screenScaleNotifier.value;
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
            builder: (context, scale, _) {

              return RawGestureDetector(
                gestures: {
                  _AlwaysWinScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<_AlwaysWinScaleGestureRecognizer>(
                        () => _AlwaysWinScaleGestureRecognizer(debugOwner: this),
                        (_AlwaysWinScaleGestureRecognizer instance) {
                      instance.onStart = _handleScaleStart;
                      instance.onUpdate = _handleScaleUpdate;
                      instance.onEnd = _handleScaleEnd;
                    },
                  ),
                },
                behavior: HitTestBehavior.translucent,
                child: Center(child: _buildScreenContent(scale)),
              );
            },
          ),
          if (isMenuOpenNotifier.value) _buildOverlayTapRegion(),
        ],
      ),
    );
  }

  Widget _buildScreenContent(double scale) {
    final double cornerRadius = 120.0 * (1 - scale);
    final double borderWidth = 30.0 * (1 - scale);

    return AnimatedScale(
      duration: _pinchDuration,
      curve: Curves.easeOut,
      scale: scale,
      alignment: Alignment.center,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: scale < 0.99,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: inAppBackgroundColor,
                  borderRadius: BorderRadius.circular(cornerRadius),
                  border: borderWidth > 0
                      ? Border.all(width: borderWidth, color: Colors.transparent)
                      : null,
                ),
                child: widget.builder(context, scale < 1.0, scale),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: IgnorePointer(child: Center(child: aiAssistant)),
          ),

          if (scale < 0.99)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: inAppBackgroundColor,
                      width: borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildOverlayTapRegion() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) {
          setState(() {
            _currentScale = 1.0;
          });
        },
        child: const SizedBox.expand(),
      ),
    );
  }



  void _handleScaleStart(ScaleStartDetails details) {
    _isPinching = details.pointerCount >= 2;
    custom_menu.MenuController.instance.selectSource(widget.sourceType);
    widget.onScaleStart?.call(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isPinching && details.pointerCount >= 2) {
      final scale = details.scale.clamp(_minimizedScale, 1.0);
      setState(() => _currentScale = scale);
      widget.onScaleUpdate?.call(details);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isPinching) return;

    _isPinching = false;
    final shouldMinimize = _currentScale < 0.75;
    final targetScale = shouldMinimize ? _minimizedScale : 1.0;
    final scaleDiff = (targetScale - _currentScale).abs();
    final dynamicMs = shouldMinimize ? (scaleDiff * 800).clamp(100, 600).toInt() : 100;
    _pinchDuration = Duration(milliseconds: dynamicMs);

    screenScaleNotifier.value = _currentScale;
    setState(() => _currentScale = targetScale);
    widget.onScaleEnd?.call(details);
  }
}

class _AlwaysWinScaleGestureRecognizer extends ScaleGestureRecognizer {
  _AlwaysWinScaleGestureRecognizer({super.debugOwner});

  @override
  void rejectGesture(int pointer) { acceptGesture(pointer); }
}

