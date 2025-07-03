import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'dart:async';

class TouchBlocker extends StatefulWidget {
  const TouchBlocker({super.key});

  @override
  State<TouchBlocker> createState() => _TouchBlockerState();
}

class _TouchBlockerState extends State<TouchBlocker> with TickerProviderStateMixin {
  Offset? fingerPosition;
  bool showCancel = false;
  Timer? _holdTimer;



  late AnimationController _controller;
  late Animation<double> _animation;

  late AnimationController _popController;
  late Animation<double> _popScale;



  static const holdDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: holdDuration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _popScale = Tween<double>(begin: 1.0, end: 1.7)
        .chain(CurveTween(curve: Curves.easeOutSine))
        .animate(_popController);

  }

  void _startHold(LongPressStartDetails details) {
    setState(() {
      fingerPosition = details.globalPosition;
      showCancel = true;
    });

    _controller.forward(from: 0);

    _holdTimer = Timer(holdDuration, () {
      _controller.forward(from: 1.0);
      _triggerPop();
    });
  }

  void _endHold(_) {
    _holdTimer?.cancel();

    final double current = _controller.value;

    if (_controller.isAnimating || current > 0.0) {
      _controller
          .animateBack(0.0, duration: Duration(
        milliseconds: (holdDuration.inMilliseconds * current).round(),
      ))
          .whenComplete(() {
        setState(() {
          showCancel = false;
          fingerPosition = null;
        });
      });
    } else {
      setState(() {
        showCancel = false;
        fingerPosition = null;
      });
    }

    _popController.reset();
  }

  void _triggerPop() async {
    await _popController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    await _popController.reverse();

    _cancelTutorial();
  }

  void _cancelTutorial() {
    isTouchActive.value = true;
    tutorialCancelled.value = true;
    debugPrint("🛑 Tutorial canceled");

    _controller.reverse();
    setState(() {
      fingerPosition = null;
      showCancel = false;
    });
  }


  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isTouchActive,
      builder: (context, active, _) {
        if (active) return const SizedBox.shrink();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: _startHold,
                onLongPressMoveUpdate: (details) {
                  setState(() {
                    fingerPosition = details.globalPosition;
                  });
                },
                onLongPressEnd: _endHold,
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            if (showCancel && fingerPosition != null)
              AnimatedBuilder(
                animation: _animation,
                builder: (_, __) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final dx = fingerPosition!.dx;
                  final dy = fingerPosition!.dy;
                  final translateY = dy + (screenHeight - dy) * (1 - _animation.value);

                  return Positioned(
                    left: dx - 48,
                    top: translateY - 48,
                    child: Opacity(
                      opacity: _animation.value.clamp(0.0, 1.0),
                      child: ScaleTransition(
                        scale: _popScale,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textHighlightedColor,
                              width: 8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close_rounded,
                              size: 40,
                              color: textHighlightedColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}



class TutorialCancelledException implements Exception {
  final String message;
  TutorialCancelledException([this.message = "Tutorial Cancelled"]);
  @override
  String toString() => message;
}
