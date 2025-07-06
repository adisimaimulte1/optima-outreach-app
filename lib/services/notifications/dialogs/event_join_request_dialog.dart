import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class EventJoinRequestDialog extends StatelessWidget {
  final String requesterEmail;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const EventJoinRequestDialog({
    super.key,
    required this.requesterEmail,
    required this.onApprove,
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
          Icon(Icons.person_add_alt_1, color: textHighlightedColor, size: 48),
          const SizedBox(height: 16),
          Text("Approve Join Request?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      content: Text(
        "$requesterEmail wants to join your event. Approve the request?",
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
          label: "Approve",
          onPressed: onApprove,
          foregroundColor: inAppBackgroundColor,
          backgroundColor: textHighlightedColor,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        ),
      ],
    );
  }
}
