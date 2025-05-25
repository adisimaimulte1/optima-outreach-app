import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/globals.dart';

class PrivacySettingsDialog {
  static void show(BuildContext context) {
    popupStackCount.value++;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Privacy Settings",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Here's how Optima protects your data:",
                style: TextStyle(color: textColor, fontSize: 15.5),
              ),
              const SizedBox(height: 14),
              _privacyItem(
                icon: Icons.lock_outline,
                text: "All your data is encrypted and stored securely in Firebase.",
              ),
              _privacyItem(
                icon: Icons.visibility_off_outlined,
                text: "Only you and other members can view your events and settings. No one else has access.",
              ),
              _privacyItem(
                icon: Icons.place_outlined,
                text: "Location access is optional and used only to optimize event planning.",
              ),
              _privacyItem(
                icon: Icons.mic_none_outlined,
                text: "Your voice is never stored. It's used only as input for your secure AI conversation.",
              ),
              _privacyItem(
                icon: Icons.shield_outlined,
                text: "Crash logs and analytics are only used to improve stability — never for profiling.",
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  "For more details, refer to our full Privacy Policy.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Close",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    ).whenComplete(() => popupStackCount.value--);
  }

  static Widget _privacyItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textHighlightedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}