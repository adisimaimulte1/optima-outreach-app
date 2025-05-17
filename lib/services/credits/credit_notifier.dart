import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';

class CreditNotifier extends ValueNotifier<int> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  CreditNotifier() : super(0) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        final crd = snapshot.data()?['credits'] ?? 0;
        if (crd != value) {
          value = crd;
          credits = crd;
        }
      });
    }
  }

  void cancel() {
    _subscription?.cancel();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
