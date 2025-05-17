import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/credits/credit_service.dart';
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
    wakeWordEnabledNotifier.value = wakeWordEnabled;


    await saveProfile(name: name, email: email, photoUrl: photoUrl,);
    await saveSetting('jamieEnabled', jamieEnabled);
    await saveSetting('wakeWordEnabled', wakeWordEnabled);
    await saveSetting('jamieReminders', jamieReminders);
  }

  Future<void> initializeAndCacheUserData() async {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) return;
    if (await isCacheComplete()) {
      await loadAndCacheUserData();
      await _cacheUserEventsFromFirestore();

      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(
        authUser.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final photoUrl = authUser.photoURL ?? '';
      CreditService.initializeCredits();
      await docRef.set({
        'name': authUser.displayName ?? 'Unknown User',
        'email': authUser.email ?? '',
        'photoUrl': photoUrl,
        'settings': {
          'jamieEnabled': true,
          'wakeWordEnabled': true,
          'jamieReminders': true,
        },

      }, SetOptions(merge: true));
    }

    await loadAndCacheUserData();
    await _cacheUserEventsFromFirestore();
  }



  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_photoUrl');
    await prefs.remove('jamieEnabled');
    await prefs.remove('wakeWordEnabled');
    await prefs.remove('jamieReminders');

    clearCachedEvents();
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

  Future<String?> getCachedMemberPhoto(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('member_photo_$memberId');
  }




  Future<void> cacheUserEventsFromApp(List<EventData> events) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
    events.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('cached_user_events', jsonList);
  }

  Future<void> _cacheUserEventsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .orderBy('selectedDate')
        .get();

    final e = snapshot.docs.map((doc) {
      final data = doc.data();
      final event = EventData.fromMap(data)..id = doc.id;
      return event;
    }).toList();

    await cacheUserEventsFromApp(e);
    events = e;
  }

  Future<void> cacheSingleEvent(EventData event) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('cached_user_events') ?? [];

    final updated = existing.map((e) {
      final decoded = jsonDecode(e);
      return decoded['id'] == event.id
          ? jsonEncode(event.toMap())
          : e;
    }).toList();

    final contains = updated.any((e) {
      final decoded = jsonDecode(e);
      return decoded['id'] == event.id;
    });

    // If it wasn't found (new), add it
    if (!contains) {
      updated.insert(0, jsonEncode(event.toMap()));
    }

    await prefs.setStringList('cached_user_events', updated);
  }



  Future<List<EventData>> getCachedUserEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('cached_user_events');
    if (jsonList == null) return [];

    return jsonList.map((jsonStr) {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return EventData.fromMap(map);
    }).toList();
  }

  Future<void> deleteCachedEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('cached_user_events') ?? [];

    final updated = existing.where((e) {
      final decoded = jsonDecode(e);
      return decoded['id'] != eventId;
    }).toList();

    await prefs.setStringList('cached_user_events', updated);
  }

  Future<void> clearCachedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_events');
  }




  Future<void> logout() async {
    clearCache();
    aiVoice.stopLoop();

    LocalStorageService().setIsGoogleUser(false);
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAll() async {
    clearCache();
    aiVoice.stopLoop();
  }
}
