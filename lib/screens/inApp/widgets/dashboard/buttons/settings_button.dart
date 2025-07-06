import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class SettingsButton extends StatefulWidget {
  final double size;

  const SettingsButton({super.key, required this.size});

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {
  double _scale = 1.0;

  void _setPressed(bool isPressed) {
    setState(() => _scale = isPressed ? 0.7 : 1.0);
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
          selectedScreenNotifier.value = ScreenType.settings;
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
                border: Border.all(color: textDimColor, width: 1.2),
              ),
              child: Center(
                child: Icon(
                  Icons.settings,
                  size: 50,
                  color: inAppBackgroundColor,
                  weight: 800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
