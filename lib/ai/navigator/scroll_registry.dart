import 'package:flutter/cupertino.dart';
import 'package:optima/globals.dart';

class ScrollRegistry {
  static final Map<ScreenType, ScrollController> _controllers = {};

  static void register(ScreenType screen, ScrollController controller) {
    _controllers[screen] = controller;
  }

  static ScrollController? get(ScreenType screen) => _controllers[screen];

  static void unregister(ScreenType screen) {
    _controllers.remove(screen);
  }
}

class PageRegistry {
  static final Map<ScreenType, PageController> _controllers = {};

  static void register(ScreenType screen, PageController controller) {
    _controllers[screen] = controller;
  }

  static PageController? get(ScreenType screen) => _controllers[screen];

  static void unregister(ScreenType screen) {
    _controllers.remove(screen);
  }
}




class ScrollData {
  final double? offset;
  final int? index;
  final Duration duration;
  final Curve curve;

  const ScrollData({
    this.offset,
    this.index,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
  });

  bool get isIndexBased => index != null;
  bool get isOffsetBased => offset != null;
}


