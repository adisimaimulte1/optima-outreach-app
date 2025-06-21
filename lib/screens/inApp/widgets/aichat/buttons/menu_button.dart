import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/notifications/local_notification_service.dart';

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
  int _unreadCount = LocalNotificationService().unreadCount.value;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
    LocalNotificationService().unreadCount.addListener(_updateUnreadCount);
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 0.99 && _scale != 1.0) {
      setState(() => _scale = 1.0);
    }
  }

  void _updateUnreadCount() {
    if (mounted) {
      setState(() {
        _unreadCount = LocalNotificationService().unreadCount.value;
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
    setState(() => _scale = isPressed ? 0.7 : 1.0);
  }

  bool get _hasBadge => _unreadCount > 0;

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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, _) {
          return Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildButton(),
                if (_hasBadge)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _buildBadge(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _hasBadge ? textHighlightedColor : inAppBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: _hasBadge
            ? null
            : Border.all(
          color: textDimColor,
          width: 1.2,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 35,
        color: _hasBadge ? inAppBackgroundColor : textColor,
      ),
    );
  }


  Widget _buildBadge() {
    return Container(
      key: const ValueKey('badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: inAppBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textHighlightedColor,
          width: 1.5,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          _unreadCount.toString(),
          style: TextStyle(
            color: textHighlightedColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}
