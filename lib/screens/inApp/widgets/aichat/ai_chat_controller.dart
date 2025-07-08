import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/aichat/ai_chat_message.dart';
import 'package:optima/services/livesync/event_live_sync.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AiChatController extends ChangeNotifier {
  ItemScrollController itemScrollController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  final TextEditingController inputController = TextEditingController();
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final Map<String, GlobalKey> _buttonsKeyMap = {};
  final Map<String, GlobalKey> _bubbleKeyMap = {};

  EventData? currentEvent;
  bool hasPermission = false;
  bool isLoading = false;

  GlobalKey getBubbleKey(String id) {
    return GlobalObjectKey('bubble-${id}_${showPinnedOnly.value}');
  }

  final searchQuery = ValueNotifier<String>('');
  final isSearchBarVisible = ValueNotifier<bool>(false);

  final ValueNotifier<String?> openMessageId = ValueNotifier(null);
  final ValueNotifier<bool> showPinnedOnly = ValueNotifier(false);
  ValueNotifier<EventData>? _liveNotifier;

  void openMessageOptions(String id) => openMessageId.value = id;
  void closeMessageOptions() => openMessageId.value = null;

  bool _isScrollDisabled = false;

  int _currentMatch = 0;
  int _totalMatches = 0;
  int get currentMatch => _totalMatches == 0 ? 0 : _currentMatch + 1;
  int get totalMatches => _totalMatches;

  bool get isScrollDisabled => _isScrollDisabled;

  final Map<String, int> animatedCharCount = {};

  AiChatController() {
    if (events.isNotEmpty) {
      setEvent(events.first);
    }
  }

  Future<void> deleteChatMessage({required String messageId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || currentEvent == null) return;

    final idToken = await user.getIdToken();

    final msgIndex = currentEvent!.aiChatMessages.indexWhere(
          (m) => m.id == messageId,
    );
    if (msgIndex == -1) return;
    final removedMsg = currentEvent!.aiChatMessages.removeAt(msgIndex);

    notifyListeners();

    final response = await http.post(
      Uri.parse(
        'https://optima-livekit-token-server.onrender.com/textChat/delete',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'eventId': currentEvent!.id,
        'messageId': messageId,
        'userId': user.uid,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint("deleteChatMessage error: ${response.body}");
      currentEvent!.aiChatMessages.insert(msgIndex, removedMsg);
      notifyListeners();
    }
  }

  Future<void> pinChatMessage({
    required String messageId,
    required bool pin,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || currentEvent == null) return;

    final idToken = await user.getIdToken();

    await http.post(
      Uri.parse('https://optima-livekit-token-server.onrender.com/textChat/pinMessage'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'eventId': currentEvent!.id,
        'messageId': messageId,
        'userId': user.uid,
        'pin': pin,
      }),
    );
  }




  void handleScaleChange(double value) {
    final shouldDisable = value < 0.99;
    if (_isScrollDisabled != shouldDisable) {
      _isScrollDisabled = shouldDisable;

      if (_isScrollDisabled) {
        focusNode.unfocus();

        if (currentEvent != null && currentEvent!.aiChatMessages.isNotEmpty) {
          // Check if index 0 is already visible
          final positions = itemPositionsListener.itemPositions.value;
          final isAtTop = positions.any((pos) => pos.index == 0 && pos.itemLeadingEdge >= 0);

          if (!isAtTop) {
            Future.delayed(const Duration(milliseconds: 50), () {
              itemScrollController.scrollTo(
                index: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                alignment: 0.0,
              );
            });
          }
        }
      }
    }
  }

  void resetScrollController() {
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
  }




  void toggleSearchBar(bool visible) {
    isSearchBarVisible.value = visible;
    if (!visible) updateSearchQuery('');
  }




  void setEvent(EventData? event) {
    if (_liveNotifier != null) {
      _liveNotifier!.removeListener(_handleLiveUpdate);
      _liveNotifier = null;
    }

    if (event != null && event.id != null) {
      _liveNotifier = EventLiveSyncService().getNotifier(event.id!);
      _liveNotifier?.addListener(_handleLiveUpdate);
      _handleLiveUpdate(); // immediately sync state
    }
  }

  void _handleLiveUpdate() {
    final live = _liveNotifier?.value;
    if (live == null) return;

    currentEvent = live;
    hasPermission = live.hasPermission(FirebaseAuth.instance.currentUser?.email ?? '');
    notifyListeners();
  }



  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      _currentMatch = 0;
      _totalMatches = 0;
    } else {
      final matches = _matchedMessageIds();
      _totalMatches = matches.length;
      _currentMatch = _totalMatches > 0 ? 0 : 0;

      if (_totalMatches == 1) {
        scrollToMessage(matches[0]);
      }
    }
    notifyListeners();
  }

  void scrollToMessage(String messageId) {
    final messages = showPinnedOnly.value
        ? currentEvent!.aiChatMessages.where((m) => m.isPinned).toList()
        : currentEvent!.aiChatMessages;

    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    itemScrollController.scrollTo(
      index: messages.length - 1 - index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  void goToNextMatch() {
    final matches = _matchedMessageIds();
    if (matches.isEmpty) return;

    _currentMatch = (_currentMatch + 1) % matches.length;
    scrollToMessage(matches[_currentMatch]);

    notifyListeners();
  }

  void goToPreviousMatch() {
    final matches = _matchedMessageIds();
    if (matches.isEmpty) return;

    _currentMatch = (_currentMatch - 1 + matches.length) % matches.length;
    scrollToMessage(matches[_currentMatch]);
    notifyListeners();
  }

  List<String> _matchedMessageIds() {
    final q = searchQuery.value.toLowerCase();
    return currentEvent?.aiChatMessages
        .where((msg) => msg.content.toLowerCase().contains(q))
        .map((msg) => msg.id)
        .toList() ??
        [];
  }



  void disposeAll() {
    inputController.dispose();
    focusNode.dispose();
    searchTextController.dispose();
  }

  void handleOutsideTap(TapDownDetails details, BuildContext context) {
    if (openMessageId.value == null) return;

    final buttonsBox =
    _buttonsKeyMap[openMessageId.value]?.currentContext?.findRenderObject()
    as RenderBox?;
    final bubbleBox =
    _bubbleKeyMap[openMessageId.value]?.currentContext?.findRenderObject()
    as RenderBox?;
    final tap = details.globalPosition;

    bool isInside(RenderBox? box) {
      if (box == null) return false;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      return tap.dx >= offset.dx &&
          tap.dx <= offset.dx + size.width &&
          tap.dy >= offset.dy &&
          tap.dy <= offset.dy + size.height;
    }

    final tappedBubble = isInside(bubbleBox);
    final tappedButtons = isInside(buttonsBox);

    if (!tappedBubble && !tappedButtons) closeMessageOptions();
  }



  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isLoading || currentEvent == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userMsg = AiChatMessage(
      id: UniqueKey().toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    final thinkingMsg = AiChatMessage(
      id: UniqueKey().toString(),
      role: 'assistant',
      content: '...thinking',
      timestamp: DateTime.now(),
    );

    currentEvent!.aiChatMessages.add(userMsg);
    currentEvent!.aiChatMessages.add(thinkingMsg);
    isLoading = true;

    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }


    notifyListeners();

    inputController.clear();

    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('https://optima-livekit-token-server.onrender.com/textChat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventId': currentEvent!.id,
          'userId': user.uid, // checked by backend if it's a manager
          'message': text,
          'replyTo': currentEvent!.aiChatMessages.last.replyTo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? '[No response]';

        currentEvent!.aiChatMessages.remove(thinkingMsg);
        currentEvent!.aiChatMessages.add(
          AiChatMessage(
            id: UniqueKey().toString(),
            role: 'assistant',
            content: reply,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';

        currentEvent!.aiChatMessages.remove(thinkingMsg);
        currentEvent!.aiChatMessages.add(
          AiChatMessage(
            id: UniqueKey().toString(),
            role: 'assistant',
            content: '[Error: $error]',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint("textChat error: $e");
      currentEvent!.aiChatMessages.add(
        AiChatMessage(
          id: UniqueKey().toString(),
          role: 'assistant',
          content: '[Error: could not connect to Jamie]',
          timestamp: DateTime.now(),
        ),
      );
    }

    isLoading = false;
    notifyListeners();
  }
}