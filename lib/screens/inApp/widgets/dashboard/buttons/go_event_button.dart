import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';

class GoEventButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const GoEventButton({
    super.key,
    required this.onTap,
    required this.size,
  });

  @override
  State<GoEventButton> createState() => _GoEventButtonState();
}

class _GoEventButtonState extends State<GoEventButton> implements Triggerable {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.00 && _scale != 1.0) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        _setPressed(false);
        await Future.delayed(const Duration(milliseconds: 80));
        if (screenScaleNotifier.value >= 0.99) {
          widget.onTap();
        }
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: textHighlightedColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 50,
                    weight: 800,
                    color: inAppBackgroundColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void triggerFromAI() {
    if (screenScaleNotifier.value >= 0.99) {
      widget.onTap();
    } else {
      debugPrint("🔒 Screen not ready, ignoring AI trigger");
    }
  }
}
