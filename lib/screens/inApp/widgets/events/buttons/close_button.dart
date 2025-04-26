import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class CloseButtonAnimated extends StatefulWidget {
  final VoidCallback onPressed;

  const CloseButtonAnimated({super.key, required this.onPressed});

  @override
  State<CloseButtonAnimated> createState() => _CloseButtonAnimatedState();
}

class _CloseButtonAnimatedState extends State<CloseButtonAnimated> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() {
      _scale = pressed ? 0.7 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        widget.onPressed();
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, _) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: textDimColor,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.close,
                  color: textColor,
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
