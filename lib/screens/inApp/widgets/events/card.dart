import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String status;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.status,
  });

  static const TextStyle statusTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  static final Map<String, Color> statusColor = {
    "UPCOMING": Colors.greenAccent,
    "COMPLETED": Colors.grey,
    "CANCELLED": Colors.redAccent,
  };

  double _measureWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: statusTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  double _calculateOffset(String status) {
    if (status == "UPCOMING") return 0;
    final currentWidth = _measureWidth(status);
    final referenceWidth = _measureWidth("UPCOMING");
    return (currentWidth - referenceWidth) / 2;
  }



  Widget _buildStatusLabel() {
    return Transform.translate(
      offset: Offset(_calculateOffset(status), 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor[status]?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: statusTextStyle.copyWith(color: statusColor[status]),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusLabel(),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: textHighlightedColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(-15, 0), // shift both icon and text left together
              child: Row(
                children: [
                  Icon(Icons.access_time, color: textHighlightedColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 14),
          _buildDateTimeRow(),
        ],
      ),
    );
  }
}
