import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/events/event_details.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class EventCard extends StatefulWidget {
  final String eventId;
  final void Function(EventData oldEvent, EventData newEvent)? onReplace;
  final void Function(EventData event)? onStatusChange;
  final void Function(EventData event)? onEdit;
  final void Function(EventData event, bool isMember)? onDelete;

  final bool publicDisplay;
  final void Function(EventData event)? onJoin;


  const EventCard({
    super.key,
    required this.eventId,
    this.onReplace,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    this.onJoin,
    this.publicDisplay = false,
  });


  static const TextStyle statusTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _dragOffset = 0;
  final double _threshold = 0.86;

  bool hasPermission = true;
  Color color = textHighlightedColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (widget.publicDisplay) return ;

    setState(() {
      _dragOffset += details.primaryDelta!;
      final limit = constraints.maxWidth * _threshold;
      _dragOffset = _dragOffset.clamp(-limit, limit);
    });
  }


  Future<void> _handleDragEnd(BoxConstraints constraints, EventData eventData) async {
    if (widget.publicDisplay) return ;

    final width = constraints.maxWidth;
    final progress = _dragOffset.abs() / width;

    if ((progress - _threshold).abs() < 0.04) {
      if (_dragOffset > 0) {
        final isUpcoming = eventData.status == "UPCOMING";
        if (isUpcoming && hasPermission) {
          widget.onEdit?.call(eventData);
        }
      } else {
        final shouldDelete = await _showEventDeleteDialog(context);
        if (shouldDelete) {
            widget.onDelete?.call(eventData, hasPermission);
        }
      }
    }

    _animateReset();
  }

  void _animateReset() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });

    _controller.forward(from: 0);
  }


  @override
  Widget build(BuildContext context) {
    // if it's a public event card, build once without listenable
    if (widget.publicDisplay) {
      final event = upcomingPublicEvents.firstWhere((e) => e.id == widget.eventId);
      hasPermission = event.hasPermission(FirebaseAuth.instance.currentUser!.email!);
      color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;

      return _buildCard(event);
    }

    // otherwise, use ValueListenableBuilder for real-time updates
    final notifier = EventLiveSyncService().getNotifier(widget.eventId)!;

    return ValueListenableBuilder<EventData>(
      valueListenable: notifier,
      builder: (context, liveEvent, _) {
        hasPermission = liveEvent.hasPermission(FirebaseAuth.instance.currentUser!.email!);
        color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;

        return _buildCard(liveEvent);
      },
    );
  }

  Widget _buildCard(EventData event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTap: () {
            if (_dragOffset.abs() < 5) {
              _showEventDetailsPopup(context, event);
            }
          },
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, constraints),
          onHorizontalDragEnd: (_) => _handleDragEnd(constraints, event),
          child: Stack(
            children: [
              if (_dragOffset != 0) _buildBackground(constraints, event),
              _buildForeground(event),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildBackground(BoxConstraints constraints, EventData eventData) {
    return Positioned.fill(
      child: Row(
        children: [
          if (_dragOffset > 0)
            SizedBox(
              width: constraints.maxWidth,
              child: _buildSwipeAction(
                eventData.status == "UPCOMING" && hasPermission ? Icons.edit : Icons.edit_off,
                color,
                Alignment.centerLeft,
                iconColor: inAppBackgroundColor,
                iconSize: 40,
              ),
            )
          else
            const Spacer(),
          if (_dragOffset < 0)
            SizedBox(
              width: constraints.maxWidth,
              child: _buildSwipeAction(
                hasPermission ? Icons.delete : LucideIcons.logOut600,
                Colors.red,
                Alignment.centerRight,
                iconColor: inAppBackgroundColor,
                iconSize: 40,
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildForeground(EventData eventData) {
    final event = eventData;

    return Transform.translate(
      offset: Offset(_dragOffset, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: inAppForegroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(event),
                const SizedBox(height: 14),
                _buildDateTimeRow(event),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeAction(
      IconData icon,
      Color backgroundColor,
      Alignment alignment, {
        Color iconColor = Colors.white,
        double iconSize = 28,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }


  Widget _buildTitleRow(EventData event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              event.eventName,
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusOrJoin(event),
      ],
    );
  }

  Widget _buildStatusOrJoin(EventData event) {
    if (!widget.publicDisplay) {
      return _buildStatusLabel(event);
    }

    final currentEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    final member = event.eventMembers.firstWhere(
          (m) => (m['email'] as String?)?.toLowerCase() == currentEmail,
      orElse: () => {},
    );

    final status = (member['status'] ?? '').toLowerCase();

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.7), width: 2),
        ),
        child: Text(
          "PENDING",
          style: EventCard.statusTextStyle.copyWith(
            color: color,
            fontSize: 14,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => widget.onJoin?.call(event),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: inAppForegroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ).copyWith(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
      child: const Text(
        "JOIN",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusLabel(EventData event) {
    final status = event.status;

    final isCompleted = status == "COMPLETED";
    final isCancelled = status == "CANCELLED";
    final isUpcoming = status == "UPCOMING";

    final Color baseColor = color;
    final Color borderColor = baseColor;
    final Color backgroundColor = isCompleted
        ? baseColor
        : isUpcoming
        ? color.withOpacity(0.2)
        : Colors.transparent;
    final Color textColor = !isCompleted
        ? baseColor
        : inAppForegroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(isCompleted ? 0 : 0.7), width: 2),
      ),
      child: Text(
        status,
        style: EventCard.statusTextStyle.copyWith(color: textColor, fontSize: 14),
      ),
    );
  }

  Widget _buildDateTimeRow(EventData event) {
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
                Icon(Icons.calendar_today, color: color, size: 20),
                const SizedBox(width: 6),
                ValueListenableBuilder<double>(
                  valueListenable: screenScaleNotifier,
                  builder: (_, scale, __) {
                    final fontSize = 16 * scale.clamp(0.8, 1.0);
                    return Text(
                      formatDate(event.selectedDate!),
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(-15, 0),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: color, size: 20),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<double>(
                    valueListenable: screenScaleNotifier,
                    builder: (_, scale, __) {
                      final fontSize = 16 * scale.clamp(0.8, 1.0);
                      return Text(
                        formatTime(event.selectedTime!),
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _showEventDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        title: Column(
          children: [
            Icon(hasPermission ? Icons.delete_outline : LucideIcons.logOut600, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              hasPermission ? "Delete Event" : "Exit event",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          hasPermission
              ? "This will remove the event permanently. This action cannot be undone."
              : "This will remove you from the event. You can get invited again.",
          style: TextStyle(color: textColor, fontSize: 15.5, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context, false),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          TextButtonWithoutIcon(
            label: hasPermission ? "Delete" : "Exit",
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red,
            foregroundColor: inAppForegroundColor,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showEventDetailsPopup(BuildContext context, EventData eventData) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EventDetails",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                onTap: () {},
                child: EventDetails(
                  eventId: widget.eventId,
                  onStatusChange: (_) {
                    widget.onStatusChange?.call(eventData);
                    if (mounted) setState(() {});
                  },
                  publicDisplay: widget.publicDisplay,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }
}
