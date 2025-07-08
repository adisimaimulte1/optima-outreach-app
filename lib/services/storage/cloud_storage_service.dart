import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  final _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;



  Future<void> initDatabaseWithUser(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);

    final photoUrlBase64 = user.photoURL != null && user.photoURL!.isNotEmpty
        ? await convertImageUrlToBase64(user.photoURL!)
        : '';

    await userDocRef.set({
      'name': user.displayName ?? 'Unknown User',
      'email': user.email ?? '',
      'photo': photoUrlBase64,
      'countryCode': 'UNKNOWN',
      'fcmToken': '',
      'lastRewardedAd': '',
      'settings': {
        'jamieEnabled': false,
        'wakeWordEnabled': true,
        'jamieReminders': true,
      },
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('public_data').doc(user.uid).set({
      'email': user.email,
      'name': user.displayName ?? 'Unknown User',
      'photo': photoUrlBase64 ?? '',
    });
  }



  Future<void> saveUserProfile({
    required String name,
    required String email,
    String? photo,
  }) async {
    if (_userId == null) return;

    await _firestore.collection('users').doc(_userId).set({
      'name': name,
      'email': email,
      'photo': photo,
    }, SetOptions(merge: true));
  }

  Future<void> saveUserProfileIndividual(String key, dynamic value) async {
    if (_userId == null) return;

    LocalCache().saveSetting(key, value);
    await _firestore.collection('users').doc(_userId).set({
      key: value
    }, SetOptions(merge: true));
    await _firestore.collection('public_data').doc(_userId).set({
      key: value,
    }, SetOptions(merge: true));
  }

  Future<void> saveUserSetting(String key, dynamic value) async {
    if (_userId == null) return;

    LocalCache().saveSetting(key, value);
    await _firestore.collection('users').doc(_userId).set({
      'settings': { key: value }
    }, SetOptions(merge: true));
  }



  Future<void> saveEvent(EventData event) async {
    if (_userId == null) return;

    final eventsRef = _firestore.collection('events');

    final docRef = event.id != null
        ? eventsRef.doc(event.id)
        : await eventsRef.add(event.toMap());

    if (event.id == null) {
      event.id = docRef.id;
      events.insert(0, event);

      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;

      await http.post(
        Uri.parse('https://optima-livekit-token-server.onrender.com/event/initSubcollections'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'eventId': event.id}),
      );

      await EventLiveSyncService().listenToEvent(docRef.id);
    } else {
      await docRef.set(event.toMap());
    }

    final members = event.eventMembers;
    if (members.isEmpty) return;

    // Step 1: Collect emails
    final emails = members.map((m) => m['email'] as String?).whereType<String>().toList();

    // Step 2: Query all matching UIDs at once
    final userQuery = await _firestore
        .collection('public_data')
        .where('email', whereIn: emails)
        .get();

    // Step 3: Build map of email -> uid
    final emailToUid = {
      for (final doc in userQuery.docs)
        doc['email'].toString().toLowerCase(): doc.id,
    };

    // Step 4: Update each member doc directly
    final batch = _firestore.batch();

    for (final member in members) {
      final email = member['email']?.toString().toLowerCase();
      if (email == null || !emailToUid.containsKey(email)) continue;

      final uid = emailToUid[email]!;
      final memberRef = docRef.collection('members').doc(uid);

      final status = (member['status'] ?? 'pending').toString().toLowerCase();

      batch.set(memberRef, {
        'email': email,
        'status': status,
        'invitedAt': member['invitedAt'] ?? DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('✅ Synced ${emailToUid.length} members to Firestore');

  }

  Future<void> deleteEvent(EventData event) async {
    if (_userId == null || event.id == null) return;

    final docRef = _firestore
        .collection('events')
        .doc(event.id);

    await docRef.delete();
  }

  Future<void> removeMemberFromEvent({
    required EventData event,
    required String email,
  }) async {
    if (_userId == null || event.id == null) return;

    final memberQuery = await _firestore
        .collection('events')
        .doc(event.id)
        .collection('members')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (memberQuery.docs.isEmpty) return;

    final memberDoc = memberQuery.docs.first;
    await memberDoc.reference.delete();


    event.eventMembers = event.eventMembers
        .where((m) => (m['email'] as String?)?.toLowerCase() != email.toLowerCase())
        .toList();

  }







  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('users').doc(_userId).get();
    final data = doc.data();

    if (data == null) return null;

    return {
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'photo': data['photo'],
    };
  }

  Future<void> deleteAll() async {
    final uid = _userId;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);

    _triggerBackendEventLeave();

    final subcollections = ['sessions'];
    for (final sub in subcollections) {
      final subRef = userRef.collection(sub);
      final snapshot = await subRef.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    await userRef.delete();
    await _firestore.collection('public_data').doc(uid).delete();
  }

  void _triggerBackendEventLeave() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('https://optima-livekit-token-server.onrender.com/account/leaveEvents'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': FirebaseAuth.instance.currentUser?.email,
        }),
      );
    } catch (e) {
      debugPrint('⚠️ Failed to notify backend to leave events: $e');
    }
  }


}
