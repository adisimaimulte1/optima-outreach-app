import 'package:flutter/foundation.dart';

class CombinedListenable extends ChangeNotifier {
  final Set<Listenable> _listenables = {};
  final Map<Listenable, VoidCallback> _callbacks = {};

  CombinedListenable([List<Listenable>? initial]) {
    if (initial != null) {
      addAll(initial);
    }
  }

  void add(Listenable listenable) {
    if (_listenables.contains(listenable)) return;

    final callback = () => notifyListeners();
    _listenables.add(listenable);
    _callbacks[listenable] = callback;
    listenable.addListener(callback);
    notifyListeners(); // fire once on new addition
  }

  void remove(Listenable listenable) {
    if (!_listenables.contains(listenable)) return;

    listenable.removeListener(_callbacks[listenable]!);
    _callbacks.remove(listenable);
    _listenables.remove(listenable);
    notifyListeners(); // fire once on removal
  }

  void addAll(Iterable<Listenable> list) {
    for (final l in list) {
      add(l);
    }
  }

  void clear() {
    for (final l in _listenables) {
      l.removeListener(_callbacks[l]!);
    }
    _listenables.clear();
    _callbacks.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
