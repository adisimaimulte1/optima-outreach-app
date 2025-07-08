import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/users/members_chat/members_chat_message.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class UsersController {
  final ScrollController eventsChatScrollController = ScrollController();
  final ScrollController publicEventsScrollController = ScrollController();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  GlobalKey getBubbleKey(String id) {
    return bubbleKeyMap.putIfAbsent(id, () => GlobalKey());
  }

  final Map<String, GlobalKey> bubbleKeyMap = {};
  final Map<String, GlobalKey> buttonsKeyMap = {};

  TabController? _tabController;
  late TickerProvider _vsync;

  int lastTabIndex = 0;
  String? enteredConversationId;

  ValueNotifier<String?> openMessageId = ValueNotifier(null);




  void openMessageOptions(String id) => openMessageId.value = id;
  void closeMessageOptions() => openMessageId.value = null;
  bool isMessageOptionsOpen(String id) => openMessageId.value == id;




  void handleOutsideTap(TapDownDetails details) {
    final id = openMessageId.value;
    if (id == null) return;

    final tap = details.globalPosition;

    bool isInside(GlobalKey? key) {
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return false;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      return tap.dx >= offset.dx &&
          tap.dx <= offset.dx + size.width &&
          tap.dy >= offset.dy &&
          tap.dy <= offset.dy + size.height;
    }

    final tappedBubble = isInside(bubbleKeyMap[id]);
    final tappedButtons = isInside(buttonsKeyMap[id]);

    if (!tappedBubble && !tappedButtons) closeMessageOptions();
  }

  void init(TabController tabController) {
    _tabController = tabController;
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        lastTabIndex = _tabController!.index;
      }
    });
  }

  void dispose() {
    _tabController?.dispose();
    eventsChatScrollController.dispose();
    publicEventsScrollController.dispose();
    openMessageId.dispose();
  }

  void resetScrollPositions() {
    eventsChatScrollController.jumpTo(0);
    publicEventsScrollController.jumpTo(0);
  }

  void attachVSync(TickerProvider vsync) {
    _vsync = vsync;
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




  Future<int> deleteMessage(MembersChatMessage messageData, EventData eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (user == null || token == null) return -1;

    final eventId = eventData.id;
    final messageId = messageData.id;

    try {
      final res = await http.post(
        Uri.parse(
            'https://optima-livekit-token-server.onrender.com/memberschat/delete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'eventId': eventId,
          'messageId': messageId,
          'userId': user.uid,
        }),
      );

      return res.statusCode;
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      return -1;
    }
  }

  Future<void> addMessage(MembersChatMessage messageData, EventData eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (user == null || token == null) return;

    final eventId = eventData.id;
    final list = eventData.membersChatMessages;

    try {
      final res = await http.post(
        Uri.parse('https://optima-livekit-token-server.onrender.com/memberschat/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'eventId': eventId,
          'userId': messageData.senderId,
          'content': messageData.content,
          'replyTo': messageData.replyTo,
        }),
      );

      if (res.statusCode == 200) {
        final id = jsonDecode(res.body)['id'];
        final index = list.indexWhere((m) => m.id == messageData.id);
        if (index != -1) {
          list[index] = messageData.copyWith(id: id);
        }
      } else {
        list.removeWhere((m) => m.id == messageData.id);
      }
    } catch (e) {
      list.removeWhere((m) => m.id == messageData.id);
      debugPrint('❌ Error adding message: $e');
    }
  }

  Future<void> updateMessageReactions(String eventId, String messageId, String reaction) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('https://optima-livekit-token-server.onrender.com/memberschat/react'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'eventId': eventId,
          'messageId': messageId,
          'userEmail': user.email,
          'reaction': reaction,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to update reactions: ${response.body}');
      } else {
        debugPrint('✅ Reaction updated: ${response.body}');
      }
    } catch (e) {
      debugPrint('🔥 Exception updating reaction: $e');
    }
  }



  // TODO: i̶m̶p̶l̶e̶m̶e̶n̶t̶ (go to sleep)
  Future<void> markMessageAsRead(String messageId) async {
    debugPrint('Marking message as read: $messageId');
  }
}
