import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class MiniMenuButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool isActive;
  final bool enableActiveStyle;

  const MiniMenuButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isActive = false,
    this.enableActiveStyle = false,
  });

  @override
  State<MiniMenuButton> createState() => _MiniMenuButtonState();
}

class _MiniMenuButtonState extends State<MiniMenuButton> {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  @override
  void didUpdateWidget(covariant MiniMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.enableActiveStyle != widget.enableActiveStyle ||
        oldWidget.icon != widget.icon) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }



  void _handleScaleChange() {
    if (screenScaleNotifier.value < 0.99 && _scale != 1.0) {
      setState(() => _scale = 1.0);
    }
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }



  @override
  Widget build(BuildContext context) {
    final bool active = widget.isActive && widget.enableActiveStyle;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        if (screenScaleNotifier.value >= 0.99) {
          widget.onPressed();
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active ? textHighlightedColor : inAppForegroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: textDimColor,
                  width: 1.2,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: active
                    ? inAppBackgroundColor
                    : textColor.withOpacity(0.7),
              ),
            ),
          );
        },
      ),
    );
  }
}
