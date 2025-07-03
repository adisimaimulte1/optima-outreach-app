import 'package:flutter/cupertino.dart';

class CombinedListenable extends Listenable {
  final List<Listenable> listenables;

  CombinedListenable(this.listenables);

  @override
  void addListener(VoidCallback listener) {
    for (final l in listenables) {
      l.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final l in listenables) {
      l.removeListener(listener);
    }
  }
}
