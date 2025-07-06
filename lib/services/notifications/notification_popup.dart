import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/steps/event_audience_step.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/notifications/dialogs/event_invite_dialog.dart';
import 'package:optima/services/notifications/dialogs/event_join_request_dialog.dart';
import 'package:optima/services/notifications/local_notification_service.dart';

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
        final user = FirebaseAuth.instance.currentUser!;
        final email = user.email!;
        final eventId = data['eventId'] ?? docId;

        if (!read) {
          await LocalNotificationService().markAsRead(
            userId: user.uid,
            notificationId: docId,
          );
        }

        // Delay the dialog to after this frame to avoid StreamBuilder rebuild conflict
        WidgetsBinding.instance.addPostFrameCallback((_) {
          popupStackCount.value++;

          switch (type) {
            case 'event_invite':
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (_) => EventInviteDialog(
                  onAccept: () async {
                    final nav = Navigator.of(context, rootNavigator: true);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withOpacity(0.5),
                      useRootNavigator: true,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    await _handleEventInvitationAccept(eventId, docId, email);
                    nav.pop(); // loading
                    nav.pop(); // dialog
                    nav.pop(); // notification popup
                    selectedScreenNotifier.value = ScreenType.events;
                  },
                  onDecline: () async {
                    final nav = Navigator.of(context, rootNavigator: true);
                    _handleEventInvitationDecline(eventId, docId, email);
                    nav.pop();
                  },
                ),
              ).whenComplete(() => popupStackCount.value--);
              break;

            case 'event_join_request':
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (_) => EventJoinRequestDialog(
                  requesterEmail: sender,
                  onApprove: () async { await _handleJoinRequestApprove(context, eventId, docId, sender); },
                  onDecline: () async { await _handleJoinRequestDecline(context, eventId, docId, sender); },
                ),
              ).whenComplete(() => popupStackCount.value--);
              break;

            default:
              break;
          }
        });
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
              type == 'event_invite'
                  ? Icons.calendar_month_rounded
                  : Icons.notifications_none_rounded,
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




  Future<void> _handleEventInvitationDecline(String eventId, String notificationId, String email) async {
    final event = upcomingPublicEvents.firstWhere((e) => e.id == eventId);

    event.eventMembers = event.eventMembers
        .where((m) => (m['email'] as String?)?.toLowerCase() != email.toLowerCase())
        .toList();

    rebuildUI();

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

  Future<void> _handleEventInvitationAccept(String eventId, String notificationId, String email) async {
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
    EventLiveSyncService().listenToEvent(eventId);
  }



  Future<void> _handleJoinRequestApprove(BuildContext context, String eventId, String notificationId, String senderEmail) async {
    final nav = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    final publicQuery = await FirebaseFirestore.instance
        .collection('public_data')
        .where('email', isEqualTo: senderEmail)
        .limit(1)
        .get();

    if (publicQuery.docs.isEmpty) {
      nav.pop(); // close loading
      return;
    }

    final memberId = publicQuery.docs.first.id;

    // 1. Accept the member
    await eventRef.collection('members').doc(memberId).update({
      'status': 'accepted',
    });

    // 2. Get event data (for name)
    final eventSnap = await eventRef.get();
    final eventData = eventSnap.data();
    final eventName = eventData?['eventName'] ?? 'an event';

    // 3. Send notification
    await LocalNotificationService().addNotification(
      userId: memberId,
      message: 'You were accepted to join "$eventName"!',
      eventId: eventId,
      sender: FirebaseAuth.instance.currentUser!.email!,
      type: 'event_join_request_accepted',
    );

    // 4. Clean up
    _deleteNotificationFromManagers(eventId, notificationId);

    nav.pop(); // loading
    nav.pop(); // dialog
    nav.pop(); // notification popup

    showCardOnLaunch = MapEntry(
      true,
      MapEntry(events.firstWhere((e) => e.id == eventId), 'ALL'),
    );
    selectedScreenNotifier.value = ScreenType.events;
  }

  Future<void> _handleJoinRequestDecline(BuildContext context, String eventId, String notificationId, String senderEmail) async {
    final membersRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('members');

    final memberQuery = await membersRef
        .where('email', isEqualTo: senderEmail)
        .limit(1)
        .get();

    if (memberQuery.docs.isNotEmpty) {
      final memberDoc = memberQuery.docs.first;
      final memberDocId = memberDoc.id;

      // Delete the membership request
      await membersRef.doc(memberDocId).delete();

      // Send rejection notification
      final eventSnap = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      final eventName = eventSnap.data()?['eventName'] ?? 'an event';

      await LocalNotificationService().addNotification(
        userId: memberDocId,
        message: 'You were declined from joining "$eventName".',
        eventId: eventId,
        sender: FirebaseAuth.instance.currentUser!.email!,
        type: 'event_join_request_declined',
      );
    }

    _deleteNotificationFromManagers(eventId, notificationId);

    Navigator.pop(context);
  }

  Future<void> _deleteNotificationFromManagers(String eventId, String notificationId) async {
    final List<String> managers = events.firstWhere((event) => event.id == eventId).eventManagers;

    for (final managerEmail in managers) {
      final managerQuery = await FirebaseFirestore.instance
          .collection('public_data')
          .where('email', isEqualTo: managerEmail)
          .limit(1)
          .get();

      if (managerQuery.docs.isNotEmpty) {
        final managerUid = managerQuery.docs.first.id;

        await LocalNotificationService().deleteNotification(
          userId: managerUid,
          notificationId: notificationId,
        );
      }
    }
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