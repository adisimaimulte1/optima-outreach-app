import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class ReminderStatusCard extends StatefulWidget {
  final bool hasReminder;
  final String initialText;

  const ReminderStatusCard({
    super.key,
    this.hasReminder = false,
    this.initialText = "You're all caught up!",
  });

  @override
  State<ReminderStatusCard> createState() => ReminderStatusCardState();
}

class ReminderStatusCardState extends State<ReminderStatusCard> {
  late String _text;
  late bool _hasReminder;

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;
    _hasReminder = widget.hasReminder;

    Future.microtask(() async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint("[ReminderStatusCard] No user UID found.");
        return;
      }

      debugPrint("[ReminderStatusCard] Fetching UNREAD notifications for UID: $uid");

      final snapshot = await FirebaseFirestore.instance
          .collection('public_data')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false) // 🔥 filter only unread
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      debugPrint("[ReminderStatusCard] Unread fetched: ${snapshot.docs.length}");

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        debugPrint("[ReminderStatusCard] Latest unread notification: ${data.toString()}");
        updateFromNotification(data);
      } else {
        debugPrint("[ReminderStatusCard] No unread notifications found.");
      }
    });
  }

  void update({required String text, required bool hasReminder}) {
    debugPrint("[ReminderStatusCard] update() called with text='$text', hasReminder=$hasReminder");
    setState(() {
      _text = text;
      _hasReminder = hasReminder;
    });
  }

  void updateFromNotification(Map<String, dynamic> notification) {
    final String type = notification['type'] ?? '';
    String message = "notification received";

    debugPrint("[ReminderStatusCard] updateFromNotification() type='$type'");

    switch (type) {
      case 'event_invite':
        message = "new event invitation";
        break;
      case 'event_cancelled':
        message = "event cancelled";
        break;
      case 'event_reminder':
        message = "event starting soon";
        break;
      case 'event_update':
        message = "event updated";
        break;
    }

    update(text: message, hasReminder: true);
  }



  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public_data')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false) // only unread
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildCard("Error loading notifications", false);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildCard(widget.initialText, false);
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final String type = data['type'] ?? '';
        String message = switch (type) {
          'event_invite' => "new event invitation",
          'event_cancelled' => "event cancelled",
          'event_reminder' => "event starting soon",
          'event_update' => "event updated",
          _ => "notification received",
        };

        return _buildCard(message, true);
      },
    );
  }

  Widget _buildCard(String text, bool hasReminder) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: textDimColor,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}
