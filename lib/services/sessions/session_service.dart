import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/services/storage/local_storage_service.dart';

class SessionService {
  static final SessionService instance = SessionService._internal();
  factory SessionService() => instance;
  SessionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registers a new session after login or signup.
  Future<void> registerSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final currentDevice = "${Platform.operatingSystem} • ${Platform.operatingSystemVersion}";
    final sessionsRef = _firestore.collection('users').doc(user.uid).collection('sessions');
    final allSessions = await sessionsRef.get();

    String? matchedSessionId;

    for (var doc in allSessions.docs) {
      final data = doc.data();
      if (data['device'] == currentDevice) {
        matchedSessionId = doc.id;
        break;
      }
    }

    for (var doc in allSessions.docs) {
      await doc.reference.update({'isCurrent': false});
    }

    if (matchedSessionId != null) {
      await sessionsRef.doc(matchedSessionId).update({
        'lastActive': Timestamp.now(),
        'isCurrent': true,
      });

      await LocalStorageService().setSessionId(matchedSessionId);
      await LocalStorageService().setSessionData({
        'device': currentDevice,
        'lastActive': Timestamp.now(),
        'isCurrent': true,
      });
    } else {
      final newSessionId = _firestore.collection('dummy').doc().id;

      final sessionData = {
        'device': currentDevice,
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'isCurrent': true,
      };

      await sessionsRef.doc(newSessionId).set(sessionData);

      await LocalStorageService().setSessionId(newSessionId);
      await LocalStorageService().setSessionData(sessionData);
    }
  }

  /// Updates the current session's last active timestamp.
  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await LocalStorageService().getSessionId();
    if (sessionId == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .update({'lastActive': Timestamp.now()});
  }

  /// Deletes the current session (on logout).
  Future<void> deleteCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await LocalStorageService().getSessionId();
    if (sessionId == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .delete();

    await LocalStorageService().removeSessionId();
    await LocalStorageService().removeSessionData();
  }

  /// Deletes all other sessions except the current one.
  Future<void> deleteAllOtherSessions() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final currentSessionId = await LocalStorageService().getSessionId();
    if (currentSessionId == null) return;

    final sessionsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions');

    final sessions = await sessionsRef.get();

    for (var doc in sessions.docs) {
      if (doc.id != currentSessionId) {
        await doc.reference.delete();
      }
    }
  }

  /// Fetches all sessions for the current user.
  Future<List<Map<String, dynamic>>> getSessions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final currentSessionId = await LocalStorageService().getSessionId();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('lastActive', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'isCurrent': doc.id == currentSessionId,
      };
    }).toList();
  }

  /// Deletes a specific session by ID.
  Future<void> deleteSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .delete();
  }
}
