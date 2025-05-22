import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/services/cache/local_cache.dart';

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
        'jamieEnabled': true,
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
    } else {
      await docRef.set(event.toMap());
    }

    final members = event.eventMembers;
    for (final member in members) {
      final email = member['email'];
      if (email == null) continue;

      final query = await _firestore
          .collection('public_data')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final uid = query.docs.first.id;

        final memberDoc = await docRef.collection('members').doc(uid).get();
        final existingStatus = (memberDoc.data()?['status'] ?? '').toString().toLowerCase();

        final updatedStatus = existingStatus == 'accepted'
            ? 'accepted'
            : (member['status'] ?? 'pending');

        await docRef.collection('members').doc(uid).set({
          'email': email,
          'status': updatedStatus,
          'invitedAt': member['invitedAt'] ?? DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    }

    await LocalCache().cacheSingleEvent(event);
  }

  Future<void> deleteEvent(EventData event) async {
    if (_userId == null || event.id == null) return;

    final docRef = _firestore
        .collection('events')
        .doc(event.id);

    await docRef.delete();
    await LocalCache().deleteCachedEvent(event.id!);
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

    await LocalCache().cacheSingleEvent(event);
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

}
