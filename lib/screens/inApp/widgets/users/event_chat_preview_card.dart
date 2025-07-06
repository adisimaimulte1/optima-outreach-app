import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class EventChatPreviewCard extends StatelessWidget {
  final EventData event;
  final String previewText;
  final VoidCallback onTap;

  const EventChatPreviewCard({
    super.key,
    required this.event,
    required this.previewText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPermission = event.hasPermission(FirebaseAuth.instance.currentUser!.email!);
    final color = hasPermission ? textHighlightedColor : textSecondaryHighlightedColor;

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
            _buildEventAvatar(event, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, size: 18, color: Colors.white38),
                SizedBox(width: 6),
                Icon(Icons.whatshot, size: 18, color: Colors.orangeAccent),
                SizedBox(width: 6),
                Icon(Icons.priority_high, size: 18, color: Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventAvatar(EventData event, Color color) {
    const double size = 64;
    final imageUrl = event.chatImage;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        if (imageUrl.startsWith('http')) {
          return _imageAvatar(NetworkImage(imageUrl), size, color);
        } else {
          final bytes = base64Decode(imageUrl.split(',').last);
          return _imageAvatar(MemoryImage(bytes), size, color);
        }
      } catch (_) {
        return _initialsAvatar(event.eventName, size, color);
      }
    }

    return _initialsAvatar(event.eventName, size, color);
  }

  Widget _imageAvatar(ImageProvider image, double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 6),
      ),
      child: ClipOval(
        child: Image(
          image: image,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _initialsAvatar(String name, double size, Color color) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 6),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
