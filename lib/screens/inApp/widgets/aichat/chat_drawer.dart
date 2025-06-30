import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_controller.dart';
import 'package:provider/provider.dart';

class ChatDrawer extends StatelessWidget {
  final Function(EventData) onSelect;

  const ChatDrawer({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: screenScaleNotifier,
      builder: (context, scale, _) {
        return Drawer(
          backgroundColor: Colors.transparent,
          child: AbsorbPointer(
            absorbing: scale < 0.99,
            child: _buildDrawerContent(context),
          ),
        );
      },
    );
  }



  Widget _buildDrawerContent(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
      child: Column(
        children: [
          _buildDrawerHeader(),
          Divider(color: textDimColor, thickness: 4, height: 0),
          Expanded(child: _buildEventList(context)),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 90,
      width: double.infinity,
      color: inAppBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Events',
              style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context) {
    return Container(
      color: inAppForegroundColor,
      child: Consumer<ChatController>(
        builder: (context, chat, _) {
          return ListView.separated(
            padding: const EdgeInsets.only(top: 0, bottom: 6),
            itemCount: events.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: textDimColor.withOpacity(0.3),
                thickness: 0.8,
                height: 6,
              ),
            ),
            itemBuilder: (context, index) {
              final e = events[index];
              final selected = e.id == chat.currentEvent?.id;
              final selectedColor = chat.hasPermission
                  ? textHighlightedColor
                  : textSecondaryHighlightedColor;

              return _buildEventTile(context, e, selected, selectedColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, EventData e, bool selected, Color selectedColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BouncyOption(
              onTap: () async {
                onSelect(e);
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                e.eventName,
                style: TextStyle(
                  color: selected ? selectedColor : textColor,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
          _BouncyIcon(
            onTap: () {
              Future.delayed(const Duration(milliseconds: 100), () {
                selectedScreenNotifier.value = ScreenType.events;
                showCardOnLaunch = MapEntry(true, MapEntry(e, 'ALL'));
              });
            },
            icon: Icon(
              Icons.open_in_new,
              size: 24,
              color: selected ? selectedColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

}




class _BouncyOption extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncyOption({required this.child, required this.onTap});

  @override
  State<_BouncyOption> createState() => _BouncyOptionState();
}

class _BouncyOptionState extends State<_BouncyOption> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.85);
  void _onTapCancel() => setState(() => _scale = 1.0);
  void _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _scale = 1.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTapUp: _onTapUp,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

}


class _BouncyIcon extends StatefulWidget {
  final VoidCallback onTap;
  final Icon icon;

  const _BouncyIcon({required this.onTap, required this.icon});

  @override
  State<_BouncyIcon> createState() => _BouncyIconState();
}

class _BouncyIconState extends State<_BouncyIcon> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.8);
  void _onTapCancel() => setState(() => _scale = 1.0);
  void _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _scale = 1.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: widget.icon,
        ),
      ),
    );
  }
}

