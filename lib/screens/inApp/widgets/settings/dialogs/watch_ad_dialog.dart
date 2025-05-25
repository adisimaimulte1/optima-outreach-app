import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/credit_dialog.dart';

class WatchAdDialog {
  static Future<void> show(BuildContext context) async {
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
            Icon(Icons.play_circle_outline, size: 48, color: textHighlightedColor),
            const SizedBox(height: 12),
            Text(
              "Watch an Ad?",
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
            "Watch a short ad to earn a sub-credit. Its value depends on your country's ad rates.",
            style: TextStyle(
              color: textColor,
              fontSize: 15.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
          TextButtonWithoutIcon(
            label: "Watch Now",
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await showRewardedAdWithUid(context, user.uid);
              }
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

  static Future<void> showRewardedAdWithUid(BuildContext context, String uid) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: textHighlightedColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Finding a suitable ad...",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Please hold on just a second.",
                style: TextStyle(
                  fontSize: 14.5,
                  color: textColor.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await MethodChannel('optima.admob/reward').invokeMethod('loadAdWithUID', {'uid': uid});
      Navigator.pop(context);
      if (success == true) {
        CreditDialog.show(context);
      } else {
        _showAdNotAvailableDialog(context);
      }
    } catch (e) {
      Navigator.pop(context);
      _showAdNotAvailableDialog(context);
    }
  }

  static void _showAdNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Column(
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: textHighlightedColor),
            const SizedBox(height: 12),
            Text(
              "No Ad Available",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "Looks like no ads are ready right now.\nPlease try again in a few moments.",
          style: TextStyle(
            color: textColor,
            fontSize: 15.5,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButtonWithoutIcon(
            label: "Got it",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    );
  }
}