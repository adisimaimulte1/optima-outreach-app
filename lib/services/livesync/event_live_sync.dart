import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_message.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message.dart';
import 'package:optima/services/cache/local_cache.dart';

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
    final notifier = eventNotifiers[eventId] ??= ValueNotifier(events.firstWhere((e) => e.id == eventId));
    combinedEventsListenable.add(notifier);

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
        chatImage: data['chatImage'] ?? '',
      );

      notifier.value = updated;

      // check if the user is still in the event
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      final isStillManager = updated.eventManagers.contains(currentUserEmail);

      if (!isStillManager) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          // Check again after delay
          final latest = notifier.value;
          final stillOut = !latest.eventManagers.contains(currentUserEmail) &&
              !(latest.eventMembers.any((m) => m['email'] == currentUserEmail));

          if (stillOut) {
            stopListeningToEvent(eventId);
            events.removeWhere((e) => e.id == eventId);
          }
        });
      }


      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });

    // 🔁 Listener 2: Members
    final membersSub = ref.collection('members').snapshots().listen((snapshot) {
      final current = notifier.value;

      final updatedMembers = snapshot.docs
          .where((d) => d.id != 'placeholder')
          .map((d) => d.data()).toList();
      final updated = current.copyWith(eventMembers: updatedMembers);

      notifier.value = updated;

      // check if the user is still in the event
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      final isStillMember = updated.eventMembers.any((m) => m['email'] == currentUserEmail);

      if (!isStillMember) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          final latest = notifier.value;
          final stillOut = !latest.eventManagers.contains(currentUserEmail) &&
              !(latest.eventMembers.any((m) => m['email'] == currentUserEmail));

          if (stillOut) {
            stopListeningToEvent(eventId);
            events.removeWhere((e) => e.id == eventId);
          }
        });
      }


      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;

      // re-cache member photos
      for (final member in updatedMembers) {
        String? email = member['email'];
        if (!cachedPhotosForEmail.contains(email)) {
          LocalCache().recacheMemberPhoto(email!);
        }
      }
    });


    // 🔁 Listener 3: AI Chat
    final aiChatSub = ref
        .collection('aichat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final current = notifier.value;

      final aiMessages = snapshot.docs
          .where((doc) => doc.id != 'placeholder')
          .map((doc) => AiChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();

      final updated = current.copyWith(aiChatMessages: aiMessages);

      notifier.value = updated;

      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });


    // 🔁 Listener 4: Members Chat
    final membersChatSub = ref
        .collection('memberschat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final current = notifier.value;

      final membersMessages = snapshot.docs
          .where((doc) => doc.id != 'placeholder')
          .map((doc) => MembersChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();

      final updated = current.copyWith(membersChatMessages: membersMessages);

      notifier.value = updated;

      final index = events.indexWhere((e) => e.id == eventId);
      if (index != -1) events[index] = updated;
    });


    _eventListeners[eventId] = _EventSubscriptions(
      eventSub,
      membersSub,
      aiChatSub,
      membersChatSub,
    );
  }



  void stopListeningToEvent(String eventId) {
    _eventListeners[eventId]?.cancel();
    _eventListeners.remove(eventId);
    combinedEventsListenable.remove(eventNotifiers[eventId]!);
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
  final StreamSubscription aiChatSub;
  final StreamSubscription membersChatSub;

  _EventSubscriptions(this.eventSub, this.membersSub, this.aiChatSub, this.membersChatSub);

  void cancel() {
    eventSub.cancel();
    membersSub.cancel();
    aiChatSub.cancel();
    membersChatSub.cancel();
  }
}