import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class HelpDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Help & FAQ",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          height: 400,
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _HelpItem(
                      question: "How do I create an event?",
                      answer: "Tap the '+' button on the dashboard, then follow the guided form.",
                    ),
                    _HelpItem(
                      question: "What is Jamie?",
                      answer: "Jamie is your built-in outreach assistant that can help plan and optimize events using AI.",
                    ),
                    _HelpItem(
                      question: "Can I access Optima on multiple devices?",
                      answer: "Yes. Each session is tracked and manageable under Privacy & Security.",
                    ),
                    _HelpItem(
                      question: "Where is my data stored?",
                      answer: "All data is encrypted and stored securely in Firebase, managed by your account.",
                    ),
                    _HelpItem(
                      question: "What is an Optima credit?",
                      answer: "Credits let you use advanced AI features. You can earn them by watching ads or upgrading.",
                    ),
                    _HelpItem(
                      question: "How do I enable Jamie reminders?",
                      answer: "In Settings > Jamie Assistant, toggle the 'Jamie Reminders' switch.",
                    ),
                    _HelpItem(
                      question: "Is my data private?",
                      answer: "Yes. Only you can access your account data. Optima does not sell or share user data.",
                    ),
                    _HelpItem(
                      question: "How do I contact support?",
                      answer: "Use the 'Contact Support' button in Settings to email us directly.",
                    ),
                  ],
                ),
              ),
            ),
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
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;
  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14.5,
              color: textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
