import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_message.dart';
import 'package:optima/services/livesync/event_live_sync.dart';

class ChatController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final Map<String, GlobalKey> _buttonsKeyMap = {};
  final Map<String, GlobalKey> _bubbleKeyMap = {};

  GlobalKey getButtonsKey(String id) { return _buttonsKeyMap.putIfAbsent(id, () => GlobalKey()); }
  GlobalKey getBubbleKey(String id) { return _bubbleKeyMap.putIfAbsent(id, () => GlobalKey()); }

  EventData? currentEvent;
  bool hasPermission = false;
  bool isLoading = false;

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

  ChatController() {
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
      if (shouldDisable && scrollController.hasClients) {
        scrollController.jumpTo(scrollController.offset);
        scrollController.position.activity?.dispose();
      }
    }
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
    }
    notifyListeners();
  }

  void scrollToMessage(String messageId) {
    final context = _bubbleKeyMap[messageId]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
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
    scrollController.dispose();
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

    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

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

      currentEvent!.aiChatMessages.remove(thinkingMsg);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? '[No response]';
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

  Future<void> pickAndSendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || currentEvent == null) return;

    await file.readAsBytes(); // optional use

    currentEvent!.aiChatMessages.add(
      AiChatMessage(
        id: UniqueKey().toString(),
        role: 'user',
        content: 'IMG',
        timestamp: DateTime.now(),
      ),
    );

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    currentEvent!.aiChatMessages.add(
      AiChatMessage(
        id: UniqueKey().toString(),
        role: 'assistant',
        content: 'Jamie processed the image and found... pixels.',
        timestamp: DateTime.now(),
      ),
    );

    isLoading = false;
    notifyListeners();
  }
}
