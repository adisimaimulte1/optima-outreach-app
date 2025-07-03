import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';

class CreditHistoryLiveSyncService {
  static final CreditHistoryLiveSyncService _instance = CreditHistoryLiveSyncService._internal();
  factory CreditHistoryLiveSyncService() => _instance;
  CreditHistoryLiveSyncService._internal();

  StreamSubscription? _subscription;

  Future<void> start() async {
    _subscription?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final startKey = DateFormat('yyyy-MM-dd').format(startDate);

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('creditHistory')
        .snapshots()
        .listen((snapshot) {
      final Map<String, CreditHistory> newMap = {};
      for (final doc in snapshot.docs) {
        final dateKey = doc.id;
        if (dateKey.compareTo(startKey) >= 0) {
          newMap[dateKey] = CreditHistory.fromMap(doc.data());
        }
      }
      creditHistoryMap.value = {...newMap};
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    creditHistoryMap.value = {};
  }
}



class CreditHistory {
  final int usedCredits;
  final double usedSubCredits;

  CreditHistory({required this.usedCredits, required this.usedSubCredits});

  factory CreditHistory.fromMap(Map<String, dynamic> data) {
    return CreditHistory(
      usedCredits: (data['usedCredits'] as num?)?.toInt() ?? 0,
      usedSubCredits: data['usedSubCredits'] ?? 0.0,
    );
  }
}
