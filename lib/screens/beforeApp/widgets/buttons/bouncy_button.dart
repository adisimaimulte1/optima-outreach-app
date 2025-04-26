import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const BouncyButton({super.key, required this.child, required this.onPressed});

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(_) {
    setState(() {
      _scale = 0.7;
    });
  }

  void _onTapUp(_) {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () {
        setState(() => _scale = 1.0);
      },
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
