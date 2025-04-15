import 'package:flutter/material.dart';

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
        color: const Color(0xFF24324A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        _text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

