import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
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

  Future<String?> getCachedMemberPhoto(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('member_photo_$memberId');
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
