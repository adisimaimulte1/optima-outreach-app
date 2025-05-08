import 'package:flutter/cupertino.dart';
import 'package:optima/globals.dart';

class RevealIconSwitcher extends StatefulWidget {
  final IconData currentIcon;
  final Duration duration;

  const RevealIconSwitcher({
    super.key,
    required this.currentIcon,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<RevealIconSwitcher> createState() => _RevealIconSwitcherState();
}

class _RevealIconSwitcherState extends State<RevealIconSwitcher> with SingleTickerProviderStateMixin {
  late IconData _previousIcon;
  late IconData _currentIcon;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentIcon = widget.currentIcon;
    _previousIcon = widget.currentIcon;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(covariant RevealIconSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIcon != _currentIcon) {
      _previousIcon = _currentIcon;
      _currentIcon = widget.currentIcon;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(0, -20 * _animation.value),
                  child: Opacity(
                    opacity: 1.0 - _animation.value,
                    child: Icon(_previousIcon, color: textHighlightedColor, size: 20),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, 20 * (1 - _animation.value)),
                  child: Opacity(
                    opacity: _animation.value,
                    child: Icon(_currentIcon, color: textHighlightedColor, size: 20),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
