import 'package:flutter/material.dart';

class UsersController {
  final ScrollController eventsChatScrollController = ScrollController();
  final ScrollController publicEventsScrollController = ScrollController();

  TabController? _tabController;
  late TickerProvider _vsync;

  int lastTabIndex = 0;

  String? enteredConversationId;

  void attachVSync(TickerProvider vsync) {
    _vsync = vsync;
  }

  void init(TabController tabController) {
    _tabController = tabController;
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        lastTabIndex = _tabController!.index;
      }
    });
  }

  TabController get tabController {
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: _vsync, initialIndex: lastTabIndex);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          lastTabIndex = _tabController!.index;
        }
      });
    }
    return _tabController!;
  }

  void resetScrollPositions() {
    eventsChatScrollController.jumpTo(0);
    publicEventsScrollController.jumpTo(0);
  }

  void dispose() {
    _tabController?.dispose();
    eventsChatScrollController.dispose();
    publicEventsScrollController.dispose();
  }
}
