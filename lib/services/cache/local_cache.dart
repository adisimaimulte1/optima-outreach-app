import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/credits/credit_service.dart';
import 'package:optima/services/livesync/credit_history_live_sync.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static final LocalCache instance = LocalCache._internal();

  factory LocalCache() => instance;

  LocalCache._internal();


  Future<void> saveProfile({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
    if (photoUrl != null) {
      await prefs.setString('profile_photoUrl', photoUrl);
    }
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      throw ArgumentError(
          'Unsupported SharedPreferences type: ${value.runtimeType}');
    }
  }



  Future<Map<String, dynamic>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('profile_name'),
      'email': prefs.getString('profile_email'),
      'photoUrl': prefs.getString('profile_photoUrl'),
      'jamieEnabled': prefs.getBool('jamieEnabled'),
      'wakeWordEnabled': prefs.getBool('wakeWordEnabled'),
      'jamieReminders': prefs.getBool('jamieReminders'),
    };
  }

  Future<void> loadAndCacheUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    name = data['name'] ?? user.displayName ?? 'Unknown User';
    email = data['email'] ?? user.email ?? '';
    photoUrl = data['photo'];
    credits = data['credits'] ?? 0;
    subCredits = (data['subCredits'] ?? 0).toDouble();
    plan = data['plan'] ?? 'free';

    final settings = Map<String, dynamic>.from(data['settings'] ?? {});

    jamieEnabled = settings['jamieEnabled'] ?? true;
    wakeWordEnabled = settings['wakeWordEnabled'] ?? true;
    jamieReminders = settings['jamieReminders'] ?? true;


    jamieEnabledNotifier.value = jamieEnabled;
    jamieRemindersNotifier.value = jamieReminders;
    wakeWordEnabledNotifier.value = wakeWordEnabled;


    await saveProfile(name: name, email: email, photoUrl: photoUrl,);
    await saveSetting('jamieEnabled', jamieEnabled);
    await saveSetting('wakeWordEnabled', wakeWordEnabled);
    await saveSetting('jamieReminders', jamieReminders);
  }

  Future<void> initializeAndCacheUserData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    await cacheUserEventsFromFirestore();

    if (authUser == null) return;
    if (await isCacheComplete()) {
      await loadAndCacheUserData();
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(
        authUser.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final photoUrl = authUser.photoURL ?? '';
      String? photoBase64;

      if (photoUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(photoUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          photoBase64 = base64Encode(bytes);
        }
      }

      CreditService.initializeCredits();

      await docRef.set({
        'name': authUser.displayName ?? 'Unknown User',
        'email': authUser.email ?? '',
        'photo': photoBase64 ?? '',
        'settings': {
          'jamieEnabled': false,
          'wakeWordEnabled': true,
          'jamieReminders': true,
        },
      }, SetOptions(merge: true));

      final publicDataRef = FirebaseFirestore.instance.collection('public_data').doc(authUser.uid);

      await publicDataRef.set({
        'name': authUser.displayName ?? 'Unknown User',
        'email': authUser.email ?? '',
        'photo': photoBase64 ?? '',
      });

      // create placeholders
      try {
        await docRef.collection('creditHistory').doc('placeholder').set({'placeholder': true});
        await docRef.collection('sessions').doc('placeholder').set({'placeholder': true});
      } catch (e) {
        debugPrint("🔥 Failed to create placeholders: $e");
      }
    }

    await loadAndCacheUserData();
  }



  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_photoUrl');
    await prefs.remove('jamieEnabled');
    await prefs.remove('wakeWordEnabled');
    await prefs.remove('jamieReminders');
  }

  Future<bool> isCacheComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('profile_name') &&
        prefs.containsKey('profile_email') &&
        prefs.containsKey('profile_photoUrl') &&
        prefs.containsKey('jamieEnabled') &&
        prefs.containsKey('wakeWordEnabled') &&
        prefs.containsKey('jamieReminders');
  }



  Future<void> cacheMemberPhoto(String memberId, String base64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('member_photo_$memberId', base64);
  }

  Future<void> recacheMemberPhoto(String email) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('public_data').where('email', isEqualTo: email).limit(1).get();
      if (doc.docs.isEmpty) return;

      final photo = doc.docs.first['photo'] ?? '';
      if (photo.isEmpty) return;

      await cacheMemberPhoto(email, photo);
    } catch (e) {}
  }



  Future<void> cacheMemberStatus(String email, String eventId, String status) async {
    final index = events.indexWhere((event) => event.id == eventId);
    if (index == -1) return;

    final event = events[index];

    final updatedMembers = event.eventMembers.map((member) {
      final match = (member['email'] as String?)?.toLowerCase() == email.toLowerCase();
      return match
          ? {
        ...member,
        'status': status,
      }
          : member;
    }).toList();

    events[index].eventMembers = updatedMembers;

    // update the cache too
    final membersSnap = await FirebaseFirestore.instance
        .collection('events')
        .doc(event.id)
        .collection('members')
        .get();

    final filteredMemberDocs = membersSnap.docs.where((m) => m.id != 'placeholder').toList();
    final memberList = filteredMemberDocs.map((m) => m.data()).toList();

    event.eventMembers = memberList; // attach members for cache
  }

  Future<void> recacheMemberStatus(String email, String eventID, {String fallbackStatus = 'pending'}) async {
    try {
      // Step 1: Get the user's UID from public_data
      final query = await FirebaseFirestore.instance
          .collection('public_data')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await cacheMemberStatus(email, eventID, fallbackStatus);
        return;
      }

      final uid = query.docs.first.id;

      // Step 2: Get member status from subcollection
      final memberDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventID)
          .collection('members')
          .doc(uid)
          .get();

      final status = memberDoc.exists
          ? (memberDoc.data()?['status'] ?? fallbackStatus).toString().toLowerCase()
          : fallbackStatus;

      await cacheMemberStatus(email, eventID, status);
    } catch (_) {
      await cacheMemberStatus(email, eventID, fallbackStatus);
    }
  }



  Future<String?> getCachedMemberPhoto(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('member_photo_$memberId');
  }




  Future<void> cacheUserEventsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userEmail = user.email?.toLowerCase();
    if (userEmail == null) return;

    final now = DateTime.now();
    final currentLocation = await getCurrentLocation();

    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('selectedDate')
        .get();

    final List<Future<void>> eventTasks = [];
    final List<EventData> relevantEvents = [];
    final List<EventData> upcomingAndNotMemberEvents = [];

    for (final doc in snapshot.docs) {
      eventTasks.add(_processEvent(doc, userEmail, now, relevantEvents, upcomingAndNotMemberEvents, currentLocation));
    }

    await Future.wait(eventTasks);

    events = relevantEvents;
    upcomingPublicEvents = upcomingAndNotMemberEvents;

    await EventLiveSyncService().startAll();
    await CreditHistoryLiveSyncService().start();
  }

  Future<void> _processEvent(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String userEmail,
      DateTime now,
      List<EventData> relevantEvents,
      List<EventData> upcomingAndNotMemberEvents,
      Position? currentLocation,
      ) async
  {
    final data = doc.data();
    final selectedDate = DateTime.tryParse(data['selectedDate'] ?? '');
    final isPublic = data['isPublic'];

    if (selectedDate == null) return;

    final eventManagers = List<String>.from(data['eventManagers'] ?? []);
    final isManager = eventManagers.contains(userEmail);

    final membersSnap = await doc.reference.collection('members').get();
    final filteredMemberDocs = membersSnap.docs.where((m) => m.id != 'placeholder').toList();
    final memberList = filteredMemberDocs.map((m) => m.data()).toList();

    final memberEntry = memberList.firstWhere(
          (m) => (m['email'] as String?)?.toLowerCase() == userEmail,
      orElse: () => {},
    );

    final hasAccepted = memberEntry['status'] == 'accepted';
    final isMemberOrManager = isManager || hasAccepted;

    if (!isMemberOrManager) {
      if (selectedDate.isAfter(now) && isPublic) {
        final event = EventData.fromMap(
          data,
          memberDocs: filteredMemberDocs,
          aiChatDocs: [],
          membersChatDocs: [],
        )..id = doc.id;

        event.tags = await getTagsForEvent(event, currentLocation);
        upcomingAndNotMemberEvents.add(event);
      }
      return;
    }

    final aiChatSnap = await doc.reference
        .collection("aichat")
        .orderBy("timestamp", descending: true)
        .get();
    final filteredAiChatDocs = aiChatSnap.docs.where((d) => d.id != 'placeholder').toList();


    final membersChatSnap = await doc.reference
        .collection("memberschat")
        .orderBy("timestamp", descending: true)
        .get();
    final filteredMembersChatDocs = membersChatSnap.docs.where((d) => d.id != 'placeholder').toList();

    final event = EventData.fromMap(
      data,
      memberDocs: filteredMemberDocs,
      aiChatDocs: filteredAiChatDocs,
      membersChatDocs: filteredMembersChatDocs,
    )..id = doc.id;

    // Run all member photo caching in parallel
    await Future.wait(memberList.map((member) async {
      final email = member['email'];
      if (email != null && email.toString().isNotEmpty) {
        await LocalCache().recacheMemberPhoto(email);
      }
    }));

    relevantEvents.add(event);
  }




  Future<void> logout() async {
    clearCache();
    aiVoice.stopLoop();

    LocalStorageService().setIsGoogleUser(false);
    EventLiveSyncService().stopAll();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAll() async {
    clearCache();
    aiVoice.stopLoop();
  }
}