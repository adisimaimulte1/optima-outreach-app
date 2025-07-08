import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class JoinEventConfirmationDialog {
  static void show(BuildContext context, String eventName, VoidCallback onConfirm) {
    popupStackCount.value++;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Column(
          children: [
            Icon(
              Icons.public_rounded,
              size: 48,
              color: textSecondaryHighlightedColor,
            ),
            const SizedBox(height: 12),
            Text(
              "Join Event?",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pressing join will send a request to the event managers.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            borderColor: Colors.white70,
            fontSize: 16,
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          TextButtonWithoutIcon(
            label: "Join",
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            backgroundColor: textSecondaryHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
        ],
      ),
    ).whenComplete(() => popupStackCount.value--);
  }
}
