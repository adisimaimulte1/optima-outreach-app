import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_cache.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  final _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;



  Future<void> initDatabase() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      throw FirebaseAuthException(
        message: "No user is logged in.",
        code: 'user-not-found',
      );
    }

    final userDocRef = _firestore.collection('users').doc(authUser.uid);

    final photoUrlBase64 = authUser.photoURL != null && authUser.photoURL!.isNotEmpty
        ? await convertImageUrlToBase64(authUser.photoURL!)
        : '';

    await userDocRef.set({
      'name': authUser.displayName ?? 'Unknown User',
      'email': authUser.email ?? '',
      'photoUrl': photoUrlBase64,
      'settings': {
        'jamieEnabled': true,
        'wakeWordEnabled': true,
        'jamieReminders': true,
      },
    }, SetOptions(merge: true));
  }



  Future<void> saveUserProfile({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    if (_userId == null) return;

    await _firestore.collection('users').doc(_userId).set({
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> saveUserProfileIndividual(String key, dynamic value) async {
    if (_userId == null) return;

    LocalCache().saveSetting(key, value);
    await _firestore.collection('users').doc(_userId).set({
      key: value
    }, SetOptions(merge: true));
  }

  Future<void> saveUserSetting(String key, dynamic value) async {
    if (_userId == null) return;

    LocalCache().saveSetting(key, value);
    await _firestore.collection('users').doc(_userId).set({
      'settings': { key: value }
    }, SetOptions(merge: true));
  }



  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('users').doc(_userId).get();
    final data = doc.data();

    if (data == null) return null;

    return {
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'photoUrl': data['photoUrl'],
    };
  }
}
