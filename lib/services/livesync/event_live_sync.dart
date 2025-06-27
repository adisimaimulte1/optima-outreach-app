import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class EventLiveSyncService {
  static final EventLiveSyncService _instance = EventLiveSyncService._internal();
  factory EventLiveSyncService() => _instance;
  EventLiveSyncService._internal();

  final Map<String, StreamSubscription> _eventListeners = {};

  ValueNotifier<EventData>? getNotifier(String eventId) => eventNotifiers[eventId];

  Future<void> startAll() async {
    stopAll();

    for (final event in events) {
      final eventId = event.id;
      if (eventId != null) {
        await listenToEvent(eventId);
      }
    }
  }

  Future<void> listenToEvent(String eventId) async {
    if (_eventListeners.containsKey(eventId)) return;

    final ref = FirebaseFirestore.instance.collection('events').doc(eventId);

    final sub = ref.snapshots().listen((doc) async {
      if (!doc.exists) return;

      final membersSnap = await doc.reference.collection('members').get();
      final aiChatSnap = await doc.reference
          .collection("aichat")
          .orderBy("timestamp", descending: true)
          .limit(20)
          .get();

      final event = EventData.fromMap(
        doc.data()!,
        memberDocs: membersSnap.docs,
        aiChatDocs: aiChatSnap.docs,
      )..id = doc.id;

      event.eventMembers = membersSnap.docs.map((d) => d.data()).toList();

      eventNotifiers[eventId] ??= ValueNotifier(event);
      eventNotifiers[eventId]!.value = event;

      final index = events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        events[index] = event;
      }
    });

    _eventListeners[eventId] = sub;
  }



  void stopListeningToEvent(String eventId) {
    _eventListeners[eventId]?.cancel();
    _eventListeners.remove(eventId);
    eventNotifiers.remove(eventId);
  }

  void stopAll() {
    for (var sub in _eventListeners.values) {
      sub.cancel();
    }
    _eventListeners.clear();
    eventNotifiers.clear();
  }
}
