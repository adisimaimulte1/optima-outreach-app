import 'package:flutter/foundation.dart';
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

  @override
  void initState() {
    super.initState();
    _currentScale = screenScaleNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: screenScaleNotifier,
            builder: (context, scale, _) {
              final isMinimized = scale < 1.0;

              return RawGestureDetector(
                gestures: {
                  _AlwaysWinScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<_AlwaysWinScaleGestureRecognizer>(
                        () => _AlwaysWinScaleGestureRecognizer(debugOwner: this),
                        (_AlwaysWinScaleGestureRecognizer instance) {
                      instance.onStart = _handleScaleStart;
                      instance.onUpdate = _handleScaleUpdate;
                      instance.onEnd = _handleScaleEnd;
                    },
                  ),
                },
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: AnimatedScale(
                    scale: scale,
                    alignment: Alignment.center,
                    duration: Duration(milliseconds: pinchAnimationTime),
                    curve: Curves.easeOutCubic,
                    child: _buildScreenContent(scale, isMinimized),
                  )
                ),
              );
            },
          ),
          if (isMenuOpenNotifier.value && _currentScale == _minimizedScale) _buildOverlayTapRegion(),
        ],
      ),
    );
  }

  Widget _buildScreenContent(double scale, bool isMinimized) {
    final cornerRadius = 120.0 * (1 - scale);
    final borderWidth = 30.0 * (1 - scale);

    return Stack(
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
              child: widget.builder(context, isMinimized, scale),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(child: aiAssistant),
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

        ValueListenableBuilder2<double, bool>(
          first: screenScaleNotifier,
          second: isTouchActive,
          builder: (context, scale, isActive, _) {
            if (isActive) return const SizedBox.shrink();

            final cornerRadius = 120.0 * (1 - scale); // reuse same logic

            return IgnorePointer(
              child: Center(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: _frozenOverlay(),
                    ),
                  ),
              ),
            );
          },
        ),

      ],
    );
  }

  Widget _buildOverlayTapRegion() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) {
          _setScale(1.0, false);
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  void _setScale(double value, bool animate) {
    setState(() {
      _currentScale = value;
      screenScaleNotifier.value = _currentScale;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _isPinching = details.pointerCount >= 2;
    custom_menu.MenuController.instance.selectSource(widget.sourceType);
    widget.onScaleStart?.call(details);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isPinching && details.pointerCount >= 2) {
      final newScale = details.scale.clamp(_minimizedScale, 1.0);
      _setScale(newScale, true);
      widget.onScaleUpdate?.call(details);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isPinching) return;
    _isPinching = false;

    final shouldMinimize = _currentScale < 0.75;
    if (shouldMinimize) {
      _setScale(_minimizedScale, true);
    } else {
      _setScale(1.0, false);
    }

    widget.onScaleEnd?.call(details);
  }


  Widget _frozenOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFFdcf3ff).withOpacity(0.02),
              Color(0xFFdcf3ff).withOpacity(0.2),
            ],
            stops: [0.8, 1.0],
          ),
        ),
      ),
    );
  }
}



class _AlwaysWinScaleGestureRecognizer extends ScaleGestureRecognizer {
  _AlwaysWinScaleGestureRecognizer({super.debugOwner});
  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, null);
          },
        );
      },
    );
  }
}

