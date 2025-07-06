import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  StreamSubscription? _unreadCounterSub;

  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// Starts listening for unread notifications
  void startListening(String userId) {
    debugPrint('🔔 Starting notification listener for user: $userId');
    _unreadCounterSub = FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) async {
        unreadCount.value = snapshot.docs.length;

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final data = change.doc.data();
          if (data == null) continue;

          final type = data['type']?.toString();
          final eventId = data['eventId']?.toString();

          if (eventId == null) continue;

          if (type == 'event_join_request_accepted') {
            await _handleJoinRequestAccepted(eventId);
          } else if (type == 'event_join_request_declined') {
            _handleJoinRequestDeclined(eventId);
          } else if (type == 'event_invite') {
            _handleInvite(eventId);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Firestore stream error: $error');
      },
    );
  }

  void stopListening() {
    _unreadCounterSub?.cancel();
  }


  Future<void> addNotification({
    required String userId,
    required String message,
    required String eventId,
    required String sender,
    String type = 'event_invite',
  }) async {
    final notifRef = FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .doc();

    await notifRef.set({
      'type': type,
      'message': message,
      'sender': sender,
      'eventId': eventId,
      'timestamp': Timestamp.now(),
      'read': false,
    });
  }

  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final notifRef = FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    await notifRef.delete();
  }


  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    await docRef.update({'read': true});

    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null) { return; }

    Future.delayed(const Duration(milliseconds: 500)).whenComplete(() async {
          final type = data['type']?.toString();

          if (type == 'event_join_request_accepted' || type == 'event_join_request_declined') {
            await docRef.delete();
          }
        }
    );

  }





  Future<void> _handleJoinRequestAccepted(String eventId) async {
    if (events.any((e) => e.id == eventId)) return;

    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final eventSnap = await eventRef.get();
    if (!eventSnap.exists) return;

    final eventData = eventSnap.data();
    if (eventData == null) return;

    final memberDocs = await eventRef
        .collection('members')
        .get()
        .then((snapshot) => snapshot.docs);

    final aiChatDocs = await eventRef
        .collection('aichat')
        .orderBy('timestamp', descending: false)
        .get()
        .then((snapshot) => snapshot.docs);

    final newEvent = EventData.fromMap(
      eventData,
      memberDocs: memberDocs,
      aiChatDocs: aiChatDocs,
    )..id = eventId;

    events.add(newEvent);
    await EventLiveSyncService().listenToEvent(eventId);
    upcomingPublicEvents.removeWhere((e) => e.id == eventId);

    rebuildUI();
  }

  void _handleJoinRequestDeclined(String eventId) {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    final index = upcomingPublicEvents.indexWhere((e) => e.id == eventId);

    if (index != -1 && email != null) {
      final updated = upcomingPublicEvents[index];
      updated.eventMembers.removeWhere((m) => (m['email'] as String?)?.toLowerCase() == email);
      upcomingPublicEvents[index] = updated;
    }
  }

  void _handleInvite(String eventId) {
    final index = upcomingPublicEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final original = upcomingPublicEvents[index];
      final updated = original.copyWith(
        eventMembers: List.from(original.eventMembers)
          ..add({
            'email': FirebaseAuth.instance.currentUser!.email,
            'status': 'pending',
          }),
      );
      upcomingPublicEvents[index] = updated;
    }

    rebuildUI();
  }
}
