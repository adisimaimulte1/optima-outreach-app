import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_message.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class EventLiveSyncService {
  static final EventLiveSyncService _instance =
  EventLiveSyncService._internal();
  factory EventLiveSyncService() => _instance;
  EventLiveSyncService._internal();

  final Map<String, _EventSubscriptions> _eventListeners = {};

  ValueNotifier<EventData>? getNotifier(String eventId) =>
      eventNotifiers[eventId];

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
    final notifier =
    eventNotifiers[eventId] ??= ValueNotifier(events.firstWhere((e) => e.id == eventId));

    // 🔁 Listener 1: Event metadata
    final eventSub = ref.snapshots().listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      final current = notifier.value;

      final updated = current.copyWith(
        eventName: data['eventName'],
        organizationType: data['organizationType'],
        customOrg: data['customOrg'],
        selectedDate: data['selectedDate'] != null
            ? DateTime.tryParse(data['selectedDate'])
            : null,
        selectedTime: _parseTime(data['selectedTime']),
        locationAddress: data['locationAddress'],
        locationLatLng: data['locationLatLng'] != null
            ? LatLng(
          data['locationLatLng']['lat'],
          data['locationLatLng']['lng'],
        )
            : null,
        eventGoals: List<String>.from(data['eventGoals'] ?? []),
        audienceTags: List<String>.from(data['audienceTags'] ?? []),
        isPublic: data['isPublic'] ?? true,
        isPaid: data['isPaid'] ?? false,
        eventPrice: (data['eventPrice'] as num?)?.toDouble(),
        eventCurrency: data['eventCurrency'],
        jamieEnabled: data['jamieEnabled'] ?? false,
        status: data['status'] ?? "UPCOMING",
        eventManagers: List<String>.from(data['eventManagers'] ?? []),
        createdBy: data['createdBy'] ?? '',
      );

      notifier.value = updated;

      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });

    // 🔁 Listener 2: Members
    final membersSub = ref.collection('members').snapshots().listen((snapshot) {
      final current = notifier.value;

      final updated = current.copyWith(
        eventMembers: snapshot.docs.map((d) => d.data()).toList(),
      );

      notifier.value = updated;

      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });

    // 🔁 Listener 3: AI Chat
    final chatSub = ref
        .collection('aichat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final current = notifier.value;

      final aiMessages = snapshot.docs
          .map((doc) => AiChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();

      final updated = current.copyWith(aiChatMessages: aiMessages);

      notifier.value = updated;

      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });

    _eventListeners[eventId] = _EventSubscriptions(
      eventSub,
      membersSub,
      chatSub,
    );
  }

  void stopListeningToEvent(String eventId) {
    _eventListeners[eventId]?.cancel();
    _eventListeners.remove(eventId);
    eventNotifiers.remove(eventId);
  }

  void stopAll() {
    for (final sub in _eventListeners.values) {
      sub.cancel();
    }
    _eventListeners.clear();
    eventNotifiers.clear();
  }

  TimeOfDay? _parseTime(dynamic raw) {
    if (raw == null) return null;
    final parts = (raw as String).split(":");
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _EventSubscriptions {
  final StreamSubscription eventSub;
  final StreamSubscription membersSub;
  final StreamSubscription chatSub;

  _EventSubscriptions(this.eventSub, this.membersSub, this.chatSub);

  void cancel() {
    eventSub.cancel();
    membersSub.cancel();
    chatSub.cancel();
  }
}