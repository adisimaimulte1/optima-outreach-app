import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';

class PlanNotifier extends ValueNotifier<String> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  PlanNotifier() : super("free") {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        final String p = snapshot.data()?['plan'] ?? "free";
        if (p != value) {
          value = p;
          plan = p;
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
