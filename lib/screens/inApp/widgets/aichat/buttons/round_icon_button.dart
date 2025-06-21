import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class RoundIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double iconSize; // only icon size

  const RoundIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.iconSize = 40,
  });

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
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
        await Future.delayed(const Duration(milliseconds: 120));
        _setPressed(false);
        await Future.delayed(const Duration(milliseconds: 120));
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: textHighlightedColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: inAppBackgroundColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
