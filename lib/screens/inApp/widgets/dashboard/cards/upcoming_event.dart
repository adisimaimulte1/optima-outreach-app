import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class UpcomingEventCard extends StatefulWidget {
  final String initialTitle;
  final String initialDay;
  final String initialDate;
  final String initialTime;

  const UpcomingEventCard({
    super.key,
    required this.initialTitle,
    required this.initialDay,
    required this.initialDate,
    required this.initialTime,
  });

  @override
  State<UpcomingEventCard> createState() => UpcomingEventCardState();
}

class UpcomingEventCardState extends State<UpcomingEventCard> {
  late String _title;
  late String _day;
  late String _date;
  late String _time;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _day = widget.initialDay;
    _date = widget.initialDate;
    _time = widget.initialTime;
  }

  void update({
    required String title,
    required String day,
    required String date,
    required String time,
  }) {
    setState(() {
      _title = title;
      _day = day;
      _date = date;
      _time = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textDimColor,
          width: 1.2,
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UPCOMING EVENT",
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    _day,
                    style: TextStyle(
                      color: textHighlightedColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _date,
                    style: TextStyle(
                      color: textHighlightedColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: textColor.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _time,
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
