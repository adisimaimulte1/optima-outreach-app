import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/notifications/local_notification_service.dart';

class ReminderBellButton extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ReminderBellButton({
    super.key,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<ReminderBellButton> createState() => _ReminderBellButtonState();
}

class _ReminderBellButtonState extends State<ReminderBellButton> {
  double _scale = 1.0;
  int feedbackCount = LocalNotificationService().unreadCount.value;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
    LocalNotificationService().unreadCount.addListener(_updateUnreadCount);
  }


  void _updateUnreadCount() {
    if (mounted) {
      setState(() {
        feedbackCount = LocalNotificationService().unreadCount.value;
      });
    }
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 0.99 && _scale != 1.0) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    LocalNotificationService().unreadCount.removeListener(_updateUnreadCount);
    super.dispose();
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }

  bool get _hasReminder => feedbackCount > 0;

  Color get _backgroundColor =>
      _hasReminder ? textHighlightedColor : inAppForegroundColor;
  Color get _iconColor =>
      _hasReminder ? inAppBackgroundColor : textColor.withOpacity(0.6);
  Color get _badgeBackground =>
      _hasReminder ? inAppBackgroundColor : Colors.transparent;
  Color get _badgeTextColor =>
      _hasReminder ? textHighlightedColor : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 100),
      builder: (context, scale, child) => Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) {
          _setPressed(false);
          if (screenScaleNotifier.value >= 0.99) {
            widget.onTap?.call();
          }
        },
        onPointerCancel: (_) => _setPressed(false),
        child: Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildBellButton(),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _hasReminder
                      ? _buildBadge()
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
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
          color: textDimColor,
          width: 1.2,
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
    return Container(
      key: const ValueKey('badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _badgeBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          feedbackCount.toString(),
          style: TextStyle(
            color: _badgeTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
