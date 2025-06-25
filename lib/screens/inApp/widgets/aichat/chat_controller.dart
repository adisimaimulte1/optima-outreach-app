import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_message.dart';

class ChatController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  EventData? currentEvent;
  bool hasPermission = false;
  bool isLoading = false;

  final searchQuery = ValueNotifier<String>('');
  final isSearchBarVisible = ValueNotifier<bool>(false);

  bool _isScrollDisabled = false;

  int _currentMatch = 0;
  int _totalMatches = 0;
  int get currentMatch => _totalMatches == 0 ? 0 : _currentMatch + 1;
  int get totalMatches => _totalMatches;

  ChatController() {
    if (events.isNotEmpty) {
      setEvent(events.first);
    }
  }

  bool get isScrollDisabled => _isScrollDisabled;



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

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      _currentMatch = 0;
      _totalMatches = 0;
    } else {
      final matches = _matchedMessageIndexes();
      _totalMatches = matches.length;
      _currentMatch = _totalMatches > 0 ? 0 : 0;
    }
    notifyListeners();
  }

  void setEvent(EventData? event) {
    currentEvent = event;
    hasPermission = event!.hasPermission(FirebaseAuth.instance.currentUser!.email!);
    notifyListeners();
  }

  void scrollToMessage(int index) {
    if (_isScrollDisabled || !scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        index * 80.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void goToNextMatch() {
    final matches = _matchedMessageIndexes();
    if (matches.isEmpty) return;

    _currentMatch = (_currentMatch + 1) % matches.length;
    scrollToMessage(matches[_currentMatch]);
    notifyListeners();
  }

  void goToPreviousMatch() {
    final matches = _matchedMessageIndexes();
    if (matches.isEmpty) return;

    _currentMatch = (_currentMatch - 1 + matches.length) % matches.length;
    scrollToMessage(matches[_currentMatch]);
    notifyListeners();
  }

  void disposeAll() {
    scrollController.dispose();
    inputController.dispose();
    focusNode.dispose();
    searchTextController.dispose();
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
          'replyTo': currentEvent!.aiChatMessages.last.replyTo
        }),
      );

      currentEvent!.aiChatMessages.remove(thinkingMsg);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? '[No response]';
        currentEvent!.aiChatMessages.add(AiChatMessage(
          id: UniqueKey().toString(),
          role: 'assistant',
          content: reply,
          timestamp: DateTime.now(),
        ));
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        currentEvent!.aiChatMessages.add(AiChatMessage(
          id: UniqueKey().toString(),
          role: 'assistant',
          content: '[Error: $error]',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint("textChat error: $e");
      currentEvent!.aiChatMessages.add(AiChatMessage(
        id: UniqueKey().toString(),
        role: 'assistant',
        content: '[Error: could not connect to Jamie]',
        timestamp: DateTime.now(),
      ));
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> pickAndSendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || currentEvent == null) return;

    await file.readAsBytes(); // optional use

    currentEvent!.aiChatMessages.add(AiChatMessage(
      id: UniqueKey().toString(),
      role: 'user',
      content: 'IMG',
      timestamp: DateTime.now(),
    ));

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    currentEvent!.aiChatMessages.add(AiChatMessage(
      id: UniqueKey().toString(),
      role: 'assistant',
      content: 'Jamie processed the image and found... pixels.',
      timestamp: DateTime.now(),
    ));

    isLoading = false;
    notifyListeners();
  }



  List<int> _matchedMessageIndexes() {
    final q = searchQuery.value.toLowerCase();
    return List.generate(currentEvent?.aiChatMessages.length ?? 0, (i) => i)
        .where((i) => currentEvent!.aiChatMessages[i].content.toLowerCase().contains(q))
        .toList();
  }
}
