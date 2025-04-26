import 'package:flutter/material.dart';
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
  State<NewEventButton> createState() => _NewEventButtonState();
}

class _NewEventButtonState extends State<NewEventButton> {
  double _scale = 1.0;

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        widget.onTap();
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
}
