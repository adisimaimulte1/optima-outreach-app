import 'package:flutter/material.dart';

class TextButtonWithoutIcon extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final double borderWidth;
  final Color borderColor;
  final bool isEnabled; // 👈 NEW

  const TextButtonWithoutIcon({
    required this.label,
    required this.onPressed,
    required this.foregroundColor,
    this.backgroundColor = Colors.transparent,
    this.fontSize = 15,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
    this.isEnabled = true, // 👈 NEW
  });

  @override
  _TextButtonWithoutIconState createState() => _TextButtonWithoutIconState();
}

class _TextButtonWithoutIconState extends State<TextButtonWithoutIcon> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (widget.isEnabled) {
      setState(() => _scale = pressed ? 0.7 : 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => _setPressed(true),
      onPanEnd: (_) => _setPressed(false),
      onPanCancel: () => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: TextButton(
              onPressed: widget.isEnabled ? widget.onPressed : () {},
              style: TextButton.styleFrom(
                foregroundColor: widget.foregroundColor,
                backgroundColor: widget.backgroundColor,
                splashFactory: NoSplash.splashFactory,
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: widget.borderRadius!),
                side: BorderSide(color: widget.borderColor, width: widget.borderWidth),
                textStyle: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.bold),
              ),
              child: Text(widget.label),
            ),
          );
        },
      ),
    );
  }
}
