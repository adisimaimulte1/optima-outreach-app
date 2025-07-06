import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/users/event_chat_preview_card.dart';

class EventsChatTab extends StatefulWidget {
  const EventsChatTab({super.key});

  @override
  State<EventsChatTab> createState() => _EventsChatTabState();
}

class _EventsChatTabState extends State<EventsChatTab> {
  bool _hasUnfocused = false;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          "no events",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: screenScaleNotifier,
      builder: (context, scale, _) {
        if (scale < 0.99 && !_hasUnfocused) {
          _hasUnfocused = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) FocusScope.of(context).unfocus();
          });
        } else if (scale >= 0.99 && _hasUnfocused) {
          _hasUnfocused = false;
        }

        return ListView.builder(
          controller: usersController.eventsChatScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: scale < 0.99
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventChatPreviewCard(
              event: event,
              previewText: 'No messages yet...',
              onTap: () {
                // TODO: Navigate to chat screen with event.id
              },
            );
          },
        );
      },
    );
  }
}
