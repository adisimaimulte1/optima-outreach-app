import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optima/screens/inApp/widgets/events/event_data.dart';

class ChatController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  EventData? currentEvent;
  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  void setEvent(EventData? event) {
    currentEvent = event;
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
  }
}
