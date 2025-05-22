import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  StreamSubscription? _unreadCounterSub;

  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// Starts listening for unread notifications
  void startListening(String userId) {
    _unreadCounterSub = FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
        unreadCount.value = snapshot.docs.length;
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
        .doc(eventId);

    await notifRef.set({
      'type': type,
      'message': message,
      'sender': sender,
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
    await FirebaseFirestore.instance
        .collection('public_data')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}
