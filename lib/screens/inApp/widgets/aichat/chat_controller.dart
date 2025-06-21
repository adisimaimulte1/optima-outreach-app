import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class ChatController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final TextEditingController searchTextController = TextEditingController();

  final FocusNode focusNode = FocusNode();

  EventData? currentEvent;
  bool hasPermission = false;

  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  final searchQuery = ValueNotifier<String>('');
  final isSearchBarVisible = ValueNotifier<bool>(false);

  int _currentMatch = 0;
  int _totalMatches = 0;
  int get currentMatch => _totalMatches == 0 ? 0 : _currentMatch + 1;
  int get totalMatches => _totalMatches;


  ChatController() {
    if (events.isNotEmpty) {
      setEvent(events.first);
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
    messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isLoading || currentEvent == null) return;

    messages.add({"role": "user", "content": text, "timestamp": DateTime.now().toIso8601String()});
    messages.add({"role": "assistant", "content": "...thinking", "timestamp": DateTime.now().toIso8601String()});

    isLoading = true;
    notifyListeners();

    inputController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

    await Future.delayed(const Duration(seconds: 2));

    messages.removeLast();
    messages.add({
      "role": "assistant",
      "content": "Jamie says: \"$text\" interpreted with sarcasm.",
      "timestamp": DateTime.now().toIso8601String(),
    });

    isLoading = false;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  Future<void> pickAndSendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || currentEvent == null) return;

    await file.readAsBytes(); // not used yet
    messages.add({"role": "user", "content": "IMG", "timestamp": DateTime.now().toIso8601String()});
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    messages.add({
      "role": "assistant",
      "content": "Jamie processed the image and found... pixels.",
      "timestamp": DateTime.now().toIso8601String(),
    });

    isLoading = false;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void disposeAll() {
    scrollController.dispose();
    inputController.dispose();
    focusNode.dispose();
    searchTextController.dispose();
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



  List<int> _matchedMessageIndexes() {
    final q = searchQuery.value;
    return List.generate(messages.length, (i) => i)
        .where((i) => messages[i]["content"]?.toLowerCase().contains(q) ?? false)
        .toList();
  }

  void scrollToMessage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        index * 80.0, // adjust if message height varies
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }
}
