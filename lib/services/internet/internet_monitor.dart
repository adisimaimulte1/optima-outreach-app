import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:optima/screens/beforeApp/no_internet_screen.dart';

class InternetMonitor {
  static final InternetMonitor _instance = InternetMonitor._internal();
  factory InternetMonitor() => _instance;
  InternetMonitor._internal();

  bool _isDialogOpen = false;
  late BuildContext _rootContext;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void init(BuildContext context) {
    _rootContext = context;
    _subscription ??= Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectionChange);
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleConnectionChange(List<ConnectivityResult> result) {
    final isConnected = result.any((r) => r != ConnectivityResult.none);

    if (!isConnected && !_isDialogOpen) {
      _isDialogOpen = true;
      showGeneralDialog(
        context: _rootContext,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const NoInternetScreen(),
      );
    } else if (isConnected && _isDialogOpen) {
      Navigator.of(_rootContext, rootNavigator: true).pop();
      _isDialogOpen = false;
    }
  }
}
