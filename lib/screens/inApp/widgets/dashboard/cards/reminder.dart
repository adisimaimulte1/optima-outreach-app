import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class ReminderStatusCard extends StatefulWidget {
  final bool hasReminder;
  final String initialText;

  const ReminderStatusCard({
    super.key,
    required this.hasReminder,
    required this.initialText,
  });

  @override
  State<ReminderStatusCard> createState() => ReminderStatusCardState();
}

class ReminderStatusCardState extends State<ReminderStatusCard> {
  late String _text;
  late bool _hasReminder;

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;
    _hasReminder = widget.hasReminder;
  }

  void update({required String text, required bool hasReminder}) {
    setState(() {
      _text = text;
      _hasReminder = hasReminder;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: textDimColor,
            width: 1.2,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        _text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

