import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';

class NewEventButton extends StatefulWidget {
  final VoidCallback onTap;
  final double width;
  final double height;

  const NewEventButton({
    super.key,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  State<NewEventButton> createState() => NewEventButtonState();
}

class NewEventButtonState extends State<NewEventButton> implements Triggerable {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.00 && _scale != 1.0) {
      setState(() {
        _scale = 1.0;
      });
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
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: textHighlightedColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    Icons.add,
                    size: 120,
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
  Future<void> triggerFromAI() async {
    if (screenScaleNotifier.value >= 0.99) {
      widget.onTap();
    } else {
      debugPrint("🔒 Screen not ready, ignoring AI trigger");
    }
  }
}
