import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/status_label.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/events/event_details.dart';

class UpcomingEventCard extends StatefulWidget {
  const UpcomingEventCard({super.key});

  @override
  State<UpcomingEventCard> createState() => UpcomingEventCardState();
}

class UpcomingEventCardState extends State<UpcomingEventCard> {
  String _title = "no upcoming events";
  String _date = "--.--";
  String _time = "--:--";
  bool hasPermission = false;
  EventData? _upcomingEvent;

  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadNextEvent();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.00 && _scale != 1.0) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _loadNextEvent() {
    final now = DateTime.now();

    final nextEvent = events
        .where((e) => e.selectedDate != null && e.selectedDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.selectedDate!.compareTo(b.selectedDate!));

    if (nextEvent.isNotEmpty) {
      final EventData event = nextEvent.first;
      final date = event.selectedDate!;
      final time = event.selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
      hasPermission = event.hasPermission(FirebaseAuth.instance.currentUser!.email!);

      final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      setState(() {
        _title = event.eventName;
        _date = DateFormat('d MMM').format(combined);
        _time = formatTime(time);
        _upcomingEvent = event;
      });
    }
  }

  void _handleTap() {
    if (_upcomingEvent == null) return;
    selectedScreenNotifier.value = ScreenType.events;
    showCardOnLaunch = MapEntry(true, _upcomingEvent);
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.85 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = hasPermission ? textSecondaryHighlightedColor : textHighlightedColor;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        if (screenScaleNotifier.value >= 0.99) {
          _handleTap();
        }
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: inAppForegroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(22),
              child: _buildCardContent(color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StatusLabel(
            label: "UPCOMING EVENT",
            isUpcoming: true,
            color: color,
          ),
          const SizedBox(height: 10),
          _buildDateTimeRow(color),
          const SizedBox(height: 10),
          _buildTitle(),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          _date,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.access_time, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          _time,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      _title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: _title == "no upcoming events" ? 16 : 22,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
    );
  }
}
