import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class EventCard extends StatefulWidget {
  final EventData eventData;
  final void Function(EventData oldEvent, EventData newEvent)? onReplace;
  final void Function(EventData event)? onEdit;
  final void Function(EventData event)? onDelete;


  const EventCard({
    super.key,
    required this.eventData,
    this.onReplace,
    this.onEdit,
    this.onDelete
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

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _dragOffset = 0;
  final double _threshold = 0.86;

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
    setState(() {
      _dragOffset += details.primaryDelta!;
      final limit = constraints.maxWidth * _threshold;
      _dragOffset = _dragOffset.clamp(-limit, limit);
    });
  }

  Future<void> _handleDragEnd(BoxConstraints constraints) async {
    final width = constraints.maxWidth;
    final progress = _dragOffset.abs() / width;

    if (progress > _threshold) {
      if (_dragOffset > 0) {
        widget.onEdit?.call(widget.eventData);
      } else {
        final shouldDelete = await _showEventDeleteDialog(context);
        if (shouldDelete) {
          widget.onDelete?.call(widget.eventData);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, constraints),
          onHorizontalDragEnd: (_) => _handleDragEnd(constraints),
          child: Stack(
            children: [
              if (_dragOffset != 0) _buildBackground(constraints),
              _buildForeground(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(BoxConstraints constraints) {
    return Positioned.fill(
      child: Row(
        children: [
          if (_dragOffset > 0)
            SizedBox(
              width: constraints.maxWidth,
              child: _buildSwipeAction(Icons.edit, textHighlightedColor, Alignment.centerLeft),
            )
          else
            const Spacer(),
          if (_dragOffset < 0)
            SizedBox(
              width: constraints.maxWidth,
              child: _buildSwipeAction(Icons.delete, Colors.red, Alignment.centerRight),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildForeground() {
    final event = widget.eventData;

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

  Widget _buildSwipeAction(IconData icon, Color color, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(icon, color: Colors.white, size: 28),
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
        _buildStatusLabel(event),
      ],
    );
  }

  Widget _buildStatusLabel(EventData event) {
    final offset = _calculateOffset(event.status);
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: EventCard.statusColor[event.status]?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          event.status,
          style: EventCard.statusTextStyle.copyWith(color: EventCard.statusColor[event.status]),
        ),
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
                Icon(Icons.calendar_today, color: textHighlightedColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  formatDate(event.selectedDate!),
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(-15, 0),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: textHighlightedColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    formatTime(event.selectedTime!),
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
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
            Icon(Icons.delete_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Delete Event",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "This will remove the event permanently. This action cannot be undone.",
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
            label: "Delete",
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

  double _calculateOffset(String status) {
    if (status == "UPCOMING") return 0;
    final currentWidth = _measureWidth(status);
    final referenceWidth = _measureWidth("UPCOMING");
    return (currentWidth - referenceWidth) / 2;
  }

  double _measureWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: EventCard.statusTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }
}
