import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  final _firestore = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

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
