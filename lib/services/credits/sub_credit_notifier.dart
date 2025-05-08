import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optima/globals.dart';

class SubCreditNotifier extends ValueNotifier<double> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  SubCreditNotifier() : super(0.0) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        final subcr = (snapshot.data()?['subCredits'] as num).toDouble();
        if (subcr != value) {
          value = subcr;
          subCredits = subcr; // update global if you use one
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
