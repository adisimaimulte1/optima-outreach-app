import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class EventInviteDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const EventInviteDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: inAppForegroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.only(top: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      title: Column(
        children: [
          Icon(Icons.calendar_month_rounded, color: textHighlightedColor, size: 48),
          const SizedBox(height: 16),
          Text("Enter Event?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      content: Text(
        _getRandomInviteMessage(),
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 14.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButtonWithoutIcon(
          label: "Decline",
          onPressed: onDecline,
          foregroundColor: Colors.white70,
          borderColor: Colors.white70,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        ),
        TextButtonWithoutIcon(
          label: "Enter",
          onPressed: onAccept,
          foregroundColor: inAppBackgroundColor,
          backgroundColor: textHighlightedColor,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        ),
      ],
    );
  }

  String _getRandomInviteMessage() {
    final messages = [
      "You’ve got an invite. Ready to dive in in this event?",
      "This event looks important, I'd enter it if I were you. Want to check it out?",
      "Open sesame! Tap ‘Enter’ to collaborate with other in the event.",
      "Someone tagged you in. Let’s see what’s happening in this event.",
      "You've received an invitation. Would you like to be part of this event?",
    ];
    return (messages..shuffle()).first;
  }
}
