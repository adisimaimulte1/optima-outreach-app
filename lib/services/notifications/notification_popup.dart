import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_audience_step.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/notifications/local_notification_service.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';

class NotificationPopup extends StatelessWidget {
  final String userId;

  const NotificationPopup({super.key, required this.userId});



  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: inAppBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 500, maxHeight: 500, minWidth: 320),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const HighlightedTitle("Notifications"),
            const SizedBox(height: 12),
            Expanded(child: _buildNotificationList(context)),
          ],
        ),
      ),
    );
  }



  Widget _buildNotificationList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: LocalNotificationService().getNotifications(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'no notifications here',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildNotificationTile(context, docs[index]),
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context, Map<String, dynamic> data) {
    final message = data['message'] ?? '';
    final type = data['type'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final read = data['read'] ?? false;
    final sender = data['sender'] ?? '';
    final docId = data['id'];

    return GestureDetector(
      onTap: () async {
        if (!read) {
          await LocalNotificationService().markAsRead(
            userId: FirebaseAuth.instance.currentUser!.uid,
            notificationId: docId,
          );
        }
        _showEventConfirmationDialog(
          context,
          notificationId: docId,
          eventId: docId,
          userEmail: FirebaseAuth.instance.currentUser!.email!,
        );


      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? inAppForegroundColor.withOpacity(0.4) : inAppForegroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: read ? Colors.white24 : textHighlightedColor.withOpacity(0.7),
            width: 3,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              type == 'event_invite' ? Icons.calendar_month_rounded : Icons.notifications_none_rounded,
              color: read ? Colors.white24 : textHighlightedColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by $sender',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(timestamp),
                    style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showEventConfirmationDialog(
      BuildContext context, {
        required String notificationId,
        required String eventId,
        required String userEmail,
      }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: _buildDialogTitle(),
        content: _buildDialogContent(),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          _buildDeclineButton(context, notificationId, eventId, userEmail),
          _buildEnterButton(context, notificationId, eventId, userEmail),
        ],
      ),
    );
  }

  Widget _buildDialogTitle() {
    return Column(
      children: [
        Icon(Icons.calendar_month_rounded, color: textHighlightedColor, size: 48),
        const SizedBox(height: 16),
        Text(
          "Enter Event?",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
      child: Text(
        getRandomInviteMessage(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor.withOpacity(0.85),
          fontSize: 14.5,
        ),
      ),
    );
  }

  Widget _buildDeclineButton(
      BuildContext context,
      String notificationId,
      String eventId,
      String userEmail,
      ) {
    return TextButtonWithoutIcon(
      label: "Decline",
      onPressed: () async {
        Navigator.pop(context); // close dialog

        await _handleDecline(eventId, notificationId, userEmail);
      },
      foregroundColor: Colors.white70,
      fontSize: 16,
      borderColor: Colors.white70,
      borderWidth: 1,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    );
  }

  Widget _buildEnterButton(
      BuildContext context,
      String notificationId,
      String eventId,
      String userEmail,
      ) {
    return TextButtonWithoutIcon(
      label: "Enter",
      onPressed: () async {
        final rootNavigator = Navigator.of(context, rootNavigator: true);

        // show loading dialog using root navigator
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.5),
          useRootNavigator: true,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await _handleAccept(eventId, notificationId, userEmail);

        rootNavigator.pop(); // pop loading
        rootNavigator.pop(); // pop confirmation dialog
        rootNavigator.pop(); // pop notifications popup

        selectedScreenNotifier.value = ScreenType.events;
      },
      foregroundColor: inAppBackgroundColor,
      backgroundColor: textHighlightedColor,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    );
  }






  Future<void> _handleDecline(String eventId, String notificationId, String email) async {
    await LocalNotificationService().deleteNotification(
      userId: userId,
      notificationId: notificationId,
    );

    final publicQuery = await FirebaseFirestore.instance
        .collection('public_data')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (publicQuery.docs.isEmpty) return;

    final memberUid = publicQuery.docs.first.id;

    final memberDocRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('members')
        .doc(memberUid);

    final memberDoc = await memberDocRef.get();
    if (!memberDoc.exists) return;

    await memberDocRef.delete();
  }

  Future<void> _handleAccept(String eventId, String notificationId, String email) async {
    // Step 1: Delete notification
    await LocalNotificationService().deleteNotification(
      userId: userId,
      notificationId: notificationId,
    );

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Step 2: Check and update member status
    final memberDocRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('members')
        .doc(uid);

    final memberSnap = await memberDocRef.get();
    if (!memberSnap.exists) return;

    final currentStatus = memberSnap.data()?['status'];
    if (currentStatus != 'pending') return;

    await memberDocRef.update({'status': 'accepted'});

    // Step 3: Fetch event doc and members
    final eventDocRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final eventSnap = await eventDocRef.get();
    if (!eventSnap.exists) return;

    // Step 5: Cache the updated event
    await LocalCache().cacheUserEventsFromFirestore();
  }





  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  String getRandomInviteMessage() {
    const messages = [
      "You’ve got an invite. Ready to dive in in this event?",
      "This event looks important, I'd enter it if I were you. Want to check it out?",
      "Open sesame! Tap ‘Enter’ to collaborate with other in the event.",
      "Someone tagged you in. Let’s see what’s happening in this event.",
      "You've received an invitation. Would you like to be part of this event?",
    ];

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}