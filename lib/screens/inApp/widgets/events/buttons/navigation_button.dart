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
  final bool isEnabled;

  const AnimatedScaleButton({
    super.key,
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
    this.isEnabled = true,
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
        onPointerDown: (_) {
          if (widget.isEnabled) _setPressed(true);
        },
        onPointerUp: (_) {
          if (widget.isEnabled) {
            _setPressed(false);
            widget.onPressed();
          }
        },
        onPointerCancel: (_) {
          if (widget.isEnabled) _setPressed(false);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _scale),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isEnabled ? widget.backgroundColor : Colors.transparent,
                  gradient: widget.isEnabled ? widget.backgroundGradient : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isEnabled
                        ? (widget.borderColor ?? Colors.transparent)
                        : Colors.white24,
                    width: widget.borderWidth ?? 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextButton.icon(
                    onPressed: null,
                    icon: Icon(
                      widget.icon,
                      color: widget.isEnabled ? widget.foregroundColor : Colors.white38,
                      size: widget.iconSize,
                    ),
                    label: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isEnabled ? widget.foregroundColor : Colors.white38,
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
