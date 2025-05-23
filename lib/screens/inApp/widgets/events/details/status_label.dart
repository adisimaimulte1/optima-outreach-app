import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class StatusLabel extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isUpcoming;
  final Color? color;

  const StatusLabel({
    super.key,
    required this.label,
    this.isCompleted = false,
    this.isUpcoming = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = color ?? textSecondaryHighlightedColor;
    final Color borderColor = baseColor;
    final Color backgroundColor = isCompleted
        ? baseColor
        : isUpcoming
        ? baseColor.withOpacity(0.2)
        : Colors.transparent;
    final Color textColor = isCompleted ? inAppForegroundColor : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(isCompleted ? 0 : 0.7), width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ).copyWith(color: textColor),
        ),
      ),
    );
  }
}
