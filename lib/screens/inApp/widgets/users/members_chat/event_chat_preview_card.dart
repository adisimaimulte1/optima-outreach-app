import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/event_avatar.dart';
import 'package:optima/screens/inApp/widgets/users/dialogs/event_grup_info_dialog.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class EventChatPreviewCard extends StatelessWidget {
  final EventData event;
  final VoidCallback onTap;

  const EventChatPreviewCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = EventLiveSyncService().getNotifier(event.id!);

    return ValueListenableBuilder<EventData>(
        valueListenable: notifier!,
        builder: (context, liveEvent, _) {
          final hasPermission = liveEvent.hasPermission(FirebaseAuth.instance.currentUser!.email!);
          final color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;

          final latest = liveEvent.membersChatMessages.isNotEmpty
              ? (liveEvent.membersChatMessages
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
              .first
              : null;

          final previewText = latest?.content ?? "No messages yet";

          return buildCard(context, hasPermission, color, previewText);
        });
  }

  Widget buildCard(BuildContext context, bool hasPermission, Color color, String previewText) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                popupStackCount.value++;
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (_) => EventGroupInfoDialog(
                    event: event,
                    hasPermission: hasPermission,
                  ),
                ).whenComplete(() => popupStackCount.value--);
              },
              child: EventAvatar(
                name: event.eventName,
                imageUrl: event.chatImage,
                size: 64,
                borderColor: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      event.eventName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stripMarkdown(previewText),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _stripMarkdown(String input) {
    return input
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m[1]!) // bold → keep content
        .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m[1]!)     // italic
        .replaceAllMapped(RegExp(r'`(.*?)`'), (m) => m[1]!)       // code
        .replaceAllMapped(RegExp(r'\[(.*?)\]\((.*?)\)'), (m) => m[1]!) // links → keep label
        .replaceAll(RegExp(r'^> ', multiLine: true), '')          // quotes
        .replaceAll(RegExp(r'^#+ ', multiLine: true), '')         // headers
        .replaceAll(RegExp(r'[_~]'), '')                          // stray markdown
        .trim();
  }
}
