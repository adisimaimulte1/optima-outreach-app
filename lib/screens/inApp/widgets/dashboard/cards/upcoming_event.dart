import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/status_label.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class UpcomingEventCard extends StatefulWidget {
  const UpcomingEventCard({super.key});

  @override
  State<UpcomingEventCard> createState() => UpcomingEventCardState();
}

class UpcomingEventCardState extends State<UpcomingEventCard> implements Triggerable {
  double _scale = 1.0;

  EventData? get nextEvent {
    final now = DateTime.now();
    final upcoming = events
        .where((e) =>
    e.selectedDate != null &&
        e.selectedDate!.isAfter(now) &&
        e.status == "UPCOMING")
        .toList()
      ..sort((a, b) => a.selectedDate!.compareTo(b.selectedDate!));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.00 && _scale != 1.0) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  void _handleTap(EventData event) {
    selectedScreenNotifier.value = ScreenType.events;
    showCardOnLaunch = MapEntry(true, MapEntry(event, 'UPCOMING'));
  }

  void _setPressed(bool isPressed) {
    setState(() => _scale = isPressed ? 0.85 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (nextEvent == null) return _buildNoEventCard();

    final notifier = EventLiveSyncService().getNotifier(nextEvent!.id!);

    return ValueListenableBuilder<EventData>(
      valueListenable: notifier!,
      builder: (context, event, _) {
        final color = event.hasPermission(FirebaseAuth.instance.currentUser!.email!)
            ? textHighlightedColor
            : textSecondaryHighlightedColor;

        final date = event.selectedDate!;
        final time = event.selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
        final formattedDate = DateFormat('d MMM').format(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
        final formattedTime = formatTime(time);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _scale),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, _) {
            return Transform.scale(
              scale: scale,
              child: Listener(
                onPointerDown: (_) => _setPressed(true),
                onPointerUp: (_) async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  _setPressed(false);
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (screenScaleNotifier.value >= 0.99) {
                    _handleTap(event);
                  }
                },
                onPointerCancel: (_) => _setPressed(false),
                child: Container(
                  decoration: BoxDecoration(
                    color: inAppForegroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: _buildCardContent(
                    color,
                    event.eventName,
                    formattedDate,
                    formattedTime,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardContent(Color color, String title, String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StatusLabel(label: "UPCOMING EVENT", isUpcoming: true, color: color),
        const SizedBox(height: 8),
        _buildDateTimeRow(color, date, time),
        const SizedBox(height: 6),
        _buildScaledTitle(title),
      ],
    );
  }

  Widget _buildScaledTitle(String title) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: TextStyle(
                color: textColor,
                fontSize: title == "no upcoming events" ? 16 : 22,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(22),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusLabel(label: "NO UPCOMING EVENTS", isUpcoming: true, color: textHighlightedColor),
            const SizedBox(height: 10),
            _buildDateTimeRow(textHighlightedColor, "--.--", "--:--"),
            const SizedBox(height: 10),
            _buildTitle("no upcoming events"),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(Color color, String date, String time) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            date,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Icon(Icons.access_time, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: title == "no upcoming events" ? 16 : 22,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }



  @override
  void triggerFromAI() {
    final event = nextEvent;
    if (event != null && screenScaleNotifier.value >= 0.99) {
      _handleTap(event);
    } else {
      debugPrint("🔒 No event to open or screen not ready");
    }
  }
}
