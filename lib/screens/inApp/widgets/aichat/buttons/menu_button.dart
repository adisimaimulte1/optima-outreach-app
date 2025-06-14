import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class MenuButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const MenuButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.menu,
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 0.99 && _scale != 1.0) {
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
      onPointerUp: (_) {
        _setPressed(false);
        if (screenScaleNotifier.value >= 0.99) {
          widget.onPressed();
        }
      },
      onPointerCancel: (_) => _setPressed(false),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: selectedThemeNotifier,
        builder: (context, _, __) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _scale),
            duration: const Duration(milliseconds: 100),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: inAppBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: textDimColor,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 35,
                    color: textColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
