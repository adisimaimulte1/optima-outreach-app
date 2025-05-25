import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportDialog {
  static void show(BuildContext context) {
    popupStackCount.value++;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        title: Column(
          children: [
            Icon(Icons.mail_outline, size: 48, color: textHighlightedColor),
            const SizedBox(height: 12),
            Text(
              "Contact Support",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Text(
            "This will open your email app to send a message to our support team.",
            style: TextStyle(
              color: textColor,
              fontSize: 15.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          TextButtonWithoutIcon(
            label: "Continue",
            onPressed: () async {
              Navigator.pop(context);
              final uriString = 'mailto:adrian.c.contras@gmail.com?subject=Optima%20Support&body=Hi%20Optima%20team,%0A%0A';
              await launchUrl(Uri.parse(uriString), mode: LaunchMode.externalApplication);
            },
            backgroundColor: textHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
        ],
      ),
    ).whenComplete(() => popupStackCount.value--);
  }
}