import 'package:flutter/material.dart';

class ReminderBellButton extends StatefulWidget {
  final int feedbackCount;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ReminderBellButton({
    super.key,
    required this.feedbackCount,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<ReminderBellButton> createState() => _ReminderBellButtonState();
}

class _ReminderBellButtonState extends State<ReminderBellButton> {
  double _scale = 1.0;


  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }


  bool get _hasReminder => widget.feedbackCount > 0;

  Color get _backgroundColor =>
      _hasReminder ? const Color(0xFFFFC62D) : const Color(0xFF24324A);
  Color get _iconColor =>
      _hasReminder ? const Color(0xFF1C2837) : Colors.white.withOpacity(0.6);
  Color get _badgeBackground =>
      _hasReminder ? const Color(0xFF1C2837) : Colors.transparent;
  Color get _badgeTextColor =>
      _hasReminder ? const Color(0xFFFFC62D) : Colors.transparent;



  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 100),
      builder: (context, scale, child) => Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) {
          _setPressed(false);
          widget.onTap?.call();
        },
        onPointerCancel: (_) => _setPressed(false),
        child: Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildBellButton(),
              if (_hasReminder) _buildBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBellButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.notifications_none,
            size: 120,
            weight: 800,
            color: _iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _badgeBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        child: Center(
          child: Text(
            widget.feedbackCount.toString(),
            style: TextStyle(
              color: _badgeTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
