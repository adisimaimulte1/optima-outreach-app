import 'package:flutter/material.dart';

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color foregroundColor;
  final double fontSize;
  final double iconSize;
  final double? borderWidth;
  final Color? borderColor;

  const AnimatedScaleButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.fontSize = 17,
    this.iconSize = 30,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() {
      _scale = pressed ? 0.85 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) {
          _setPressed(false);
          widget.onPressed();
        },
        onPointerCancel: (_) => _setPressed(false),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _scale),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  gradient: widget.backgroundGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.borderWidth != null
                      ? Border.all(
                      color: widget.borderColor ?? Colors.transparent,
                      width: widget.borderWidth!)
                      : null
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextButton.icon(
                    onPressed: null,
                    icon: Icon(widget.icon,
                        color: widget.foregroundColor,
                        size: widget.iconSize),
                    label: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.foregroundColor,
                        fontWeight: FontWeight.w700,
                        fontSize: widget.fontSize,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: widget.foregroundColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
