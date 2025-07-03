import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:optima/ai/ai_recordings.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/ai/processor/intent_processor.dart';
import 'package:optima/services/credits/credit_service.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:optima/ai/stt/speech_to_text.dart';
import 'package:optima/globals.dart';

class AIVoiceAssistant {
  final AudioPlayer _player = AudioPlayer();
  final SpeechToTextService _speech = SpeechToTextService();

  bool aiSpeaking = false;
  bool isListening = false;
  bool wakeWordDetected = false;
  bool _hasAttachedListener = false;


  Timer? _cooldownTimer;
  bool cooldownActive = false;
  bool _loopRunning = false;

  Completer<void>? _listeningCompleter;
  Completer<void>? _playbackCompleter;

  AIVoiceAssistant() {
    _player.onPlayerComplete.listen((_) {
      if (!(_playbackCompleter?.isCompleted ?? true)) {
        _playbackCompleter?.complete();
      }
    });
  }


  Future<void> initPermissions() async {
    if (jamieEnabledNotifier.value) {
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
  }




  void startLoop(BuildContext context) {
    if (!_hasAttachedListener) {
      _hasAttachedListener = true;
      debugPrint("🔔 Jamie assistant started.");

      jamieEnabledNotifier.addListener(() {
        debugPrint("🎛 Jamie setting changed: ${jamieEnabledNotifier.value}");

        if (jamieEnabledNotifier.value) {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            runAssistant(context, userId: userId);
          }
        } else {
          stopLoop();
          debugPrint("🛑 Jamie disabled via settings.");
        }
      });

      if (jamieEnabledNotifier.value) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          runAssistant(context, userId: userId);
        }
      }
    }
  }


  void stopLoop({settingsStop = false}) {
    _loopRunning = false;
    cooldownActive = false;
    wakeWordDetected = false;
    isListening = false;

    if (assistantState.value != JamieState.thinking && assistantState.value != JamieState.speaking) {
      debugPrint("assistant state: ${assistantState.value}");
      aiSpeaking = false;
      assistantState.value = JamieState.idle;
    }

    if (settingsStop) {
      debugPrint("💤 Jamie assistant manually stopped.");
    }
  }




  Future<void> runAssistant(BuildContext context, {required String userId}) async {
    if (_loopRunning) {
      debugPrint("⚠️ Assistant already running. Skipping second start.");
      return;
    }
    _loopRunning = true;
    debugPrint("👀 runAssistant() called");

    try {
      await initPermissions();
    } catch (e) {
      handleError(e);
      _loopRunning = false;
      return;
    }


    while (_loopRunning) {
      if (aiSpeaking || isListening) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      try {
        if (!cooldownActive && !wakeWordDetected) { await _detectWakeWord(); }
        if (wakeWordDetected && !aiSpeaking && !isListening) { await _captureAndRespond(context, userId); }

      } catch (e) {
        handleError(e);
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    _loopRunning = false;
  }

  Future<void> _detectWakeWord() async {
    if (!wakeWordEnabledNotifier.value || !jamieEnabledNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 10));
      return;
    }

    assistantState.value = JamieState.idle;
    isListening = true;

    String? wakeTranscript;
    await _speech.listenForWakeWordLoop(onTranscript: (text) {
      wakeTranscript = text;
    });

    if (!wakeWordEnabledNotifier.value || !jamieEnabledNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 10));
      isListening = false;
      return;
    }

    isListening = false;
    aiSpeaking = false;

    final transcript = (wakeTranscript ?? "").toLowerCase();
    if (transcript.contains("hey jamie")) {
      debugPrint("👂 Wake word detected: $transcript");

      wakeWordDetected = true;
      assistantState.value = JamieState.thinking;

      final delayMs = 400 + Random().nextInt(100);
      await Future.delayed(Duration(milliseconds: delayMs));

      assistantState.value = JamieState.speaking;

      final wakeResponseText = await AiRecordings.playWakeResponse();
      debugPrint("🎤 Wake response: $wakeResponseText");

      assistantState.value = JamieState.listening;
      startCooldown();
    } else {
      wakeWordDetected = false;
      assistantState.value = JamieState.idle;
    }
  }

  Future<void> _captureAndRespond(BuildContext context, String userId) async {
    debugPrint("Capturing and responding...");

    if (!jamieEnabledNotifier.value) {
      await Future.delayed(const Duration(milliseconds: 10));
      return;
    }

    assistantState.value = JamieState.listening;
    isListening = true;
    _listeningCompleter = Completer<void>();
    bool processed = false;
    bool cancelled = false;
    final cancelLock = Completer<void>();

    Future<void> cancelIfDisabled() async {
      if (!jamieEnabledNotifier.value && !_listeningCompleter!.isCompleted) {
        debugPrint("🛑 Jamie was disabled during capture");
        cancelled = true;

        try {
          await _speech.stopListening();
        } catch (e) {
          debugPrint("❌ Error during stopListening: $e");
        }

        _completeListening();
        assistantState.value = JamieState.idle;
        if (!cancelLock.isCompleted) cancelLock.complete();
      }
    }

    jamieEnabledNotifier.addListener(cancelIfDisabled);

    try {
      await _speech.startListening(
            (text) => transcribedText.value = text,
            () async => await _handleTranscript(context, userId, () => processed = true, () => processed),
      );

      while (!_listeningCompleter!.isCompleted && !cancelled && assistantState.value != JamieState.idle) {
        if (appPaused && _speech.isListening) {
          debugPrint("⏸ Pausing listening due to background");
          await _speech.stopListening();
        }

        if (!appPaused && !_speech.isListening && !processed) {
          debugPrint("▶️ Resuming listening after app resumed");
          transcribedText.value = '';
          await _speech.resumeListeningAfterPlayback(
            onResult: (text) => transcribedText.value = text,
            onDone: () async => await _handleTranscript(context, userId, () => processed = true, () => processed),
          );
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (cancelled) {
        debugPrint("🔁 Waiting for cancellation lock...");
        await cancelLock.future; // wait for cleanup
      }
    } catch (e) {
      debugPrint("💥 Error in _captureAndRespond: $e");
    } finally {
      jamieEnabledNotifier.removeListener(cancelIfDisabled);
    }
  }

  Future<void> _handleTranscript(BuildContext context, String userId, VoidCallback markProcessed, bool Function() isProcessed) async {
    if (isProcessed()) return;
    markProcessed();

    await _speech.stopListening();
    _completeListening();


    final rawTranscript = transcribedText.value.trim();
    final match = RegExp(r"hey jamie\s*", caseSensitive: false).firstMatch(rawTranscript);
    final cleaned = match != null ? rawTranscript.substring(match.end).trim() : rawTranscript;

    debugPrint("📝 Raw: $rawTranscript");
    debugPrint("🧹 Cleaned: $cleaned");

    if (cleaned.isEmpty) {
      debugPrint("🚫 Nothing to send after cleaning.");
      isListening = false;
      return;
    }

    assistantState.value = JamieState.thinking;
    await _respondToUser(context, cleaned, userId);
  }




  Future<void> _respondToUser(BuildContext context, String message, String userId) async {
    aiSpeaking = true;

    // Detect local action intent
    final detectedIntents = IntentProcessor.detectIntents(message);

    if (detectedIntents.isNotEmpty) {
      debugPrint("✅ Detected local Jamie intents: $detectedIntents");

      for (int i = 0; i < detectedIntents.length; i++) {
        final intentId = detectedIntents[i];


        // delay between responses
        assistantState.value = JamieState.thinking;
        await Future.delayed(const Duration(milliseconds: 800));


        while (appPaused) {
          await Future.delayed(const Duration(milliseconds: 30));
        }

        // execute local action
        await execute(context, intentId, message);

        // play local audio for that intent
        final bytes = await rootBundle.load(
          await AiRecordings.getActionResponse(intentId, _getIntentAudioCount(intentId)),
        );

        assistantState.value = JamieState.speaking;
        await playResponseFile(bytes.buffer.asUint8List(), detectedIntents.length - i - 1);
      }

      _finishInteraction();
      return;
    }

    // Fallback to GPT response if no local intent
    if (credits < 1) {
      debugPrint("🚫 No credits left for GPT response");

      final bytes = await rootBundle.load(await AiRecordings.getNoCreditsResponse());

      final delayMs = 400 + Random().nextInt(100);
      await Future.delayed(Duration(milliseconds: delayMs));

      await playResponseFile(bytes.buffer.asUint8List(), 0);
      _finishInteraction();
      return;
    }

    final response = await sendTextToBackend(message, userId);
    while (appPaused) {
      await Future.delayed(const Duration(milliseconds: 30));
    }

    assistantState.value = JamieState.speaking;
    await playResponseFile(response, 0);
    _finishInteraction();

    credits = (await CreditService.getCredits())!;
    if (credits < 1) lastCredit = true;
  }

  void _finishInteraction() {
    aiSpeaking = false;
    isListening = false;

    if (jamieEnabled) {
      assistantState.value = JamieState.listening;
      wakeWordDetected = true;
      startCooldown();
    }
    else {
      assistantState.value = JamieState.idle;
      cooldownActive = false;
      _cooldownTimer?.cancel();
      wakeWordDetected = false;
    }
  }




  Future<void> playResponseFile(List<int> bytes, int queued) async {
    aiSpeaking = true;
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/jamie_response.mp3");
    await file.writeAsBytes(bytes);

    debugPrint("📦 Playing from: ${file.path}");
    assistantState.value = JamieState.speaking;

    _playbackCompleter = Completer<void>();

    try {
      await _player.play(DeviceFileSource(file.path));

      while (!_playbackCompleter!.isCompleted) {
        if (appPaused && _player.state == PlayerState.playing) {
          debugPrint("⏸ App paused — pausing playback");
          await _player.pause();
        }

        if (!appPaused && _player.state == PlayerState.paused) {
          debugPrint("▶️ App resumed — resuming playback");
          await _player.resume();
        }

        await Future.delayed(const Duration(milliseconds: 10));
      }
    } catch (e) {
      debugPrint("🔇 Playback failed or timed out: $e");
    }

    if (queued == 0) { aiSpeaking = false; }
  }



  void pauseImmediately() {
    if (_player.state == PlayerState.playing) {
      _player.pause();
      debugPrint("🛑 Immediate forced pause due to lifecycle");
    }
  }

  void cancelPlayback() {
    debugPrint("❌ Jamie playback cancelled");
    try {
      _player.stop();
    } catch (_) {}

    _playbackCompleter?.complete();
  }




  Future<List<int>> sendTextToBackend(String message, String userId) async {
    final uri = Uri.parse('https://optima-livekit-token-server.onrender.com/chat');
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (token == null) {
      debugPrint("❌ No Firebase token found. User might be logged out.");
      return [];
    }

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "message": message,
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      debugPrint("❌ Chat request failed: ${response.statusCode} ${response.body}");
      return [];
    }
  }



  void startCooldown() {
    cooldownActive = true;
    _cooldownTimer?.cancel();
    debugPrint("🧊 Cooldown started. Assistant will listen for 50 seconds.");

    _cooldownTimer = Timer(const Duration(seconds: 50), () {
      if (aiSpeaking || assistantState.value == JamieState.speaking) {
        debugPrint("🕒 Cooldown skipped — Jamie still busy.");
        return;
      }

      cooldownActive = false;
      wakeWordDetected = false;
      isListening = false;
      aiSpeaking = false;
      assistantState.value = JamieState.idle;
      debugPrint("⌛ Cooldown expired. Wake word required again.");
    });

  }

  void _completeListening() {
    if (!(_listeningCompleter?.isCompleted ?? true)) {
      _listeningCompleter?.complete();
    }
  }



  void handleError(Object e) {
    debugPrint("💥 Error: $e");
    assistantState.value = JamieState.idle;
    aiSpeaking = false;
    isListening = false;
    _completeListening();
  }

  void logStatus() {
    debugPrint("📡 AI Voice Status:");
    debugPrint("• _loopRunning: $_loopRunning");
    debugPrint("• aiSpeaking: $aiSpeaking");
    debugPrint("• isListening: $isListening");
    debugPrint("• cooldownActive: $cooldownActive");
    debugPrint("• wakeWordDetected: $wakeWordDetected");
  }



  Future<void> execute(BuildContext context, String intentId, String message) async {
    if (intentId.startsWith("navigate/")) {
      AiNavigator.navigateToScreen(context, intentId);
    }

    else if (intentId.startsWith("change_setting/")) {
      _performLocalIntentAction(intentId, message);
    }

    else if (intentId.startsWith("tap_widget/")) {
      final scrollData = getScrollDataForIntent(intentId);

      AiNavigator.navigateToWidget(
          context: context,
          intentId: intentId,
          shouldScroll: scrollData != null && scrollData.offset != null,
          shouldScrollToPage: scrollData != null && scrollData.index != null,
          scrollData: scrollData ?? const ScrollData(offset: 0.0));
    }
  }


  void _performLocalIntentAction(String intentId, String message) {
    switch (intentId) {
      case "change_setting/toggle_theme":
        LocalStorageService().setThemeMode(
          isDarkModeNotifier.value ? ThemeMode.light : ThemeMode.dark
        );
        break;

      case "change_setting/change_theme":
        if (message.contains("system")) {
          LocalStorageService().setThemeMode(ThemeMode.system);
        } else if (message.contains("light")) {
          LocalStorageService().setThemeMode(ThemeMode.light);
        } else if (message.contains("dark")) {
          LocalStorageService().setThemeMode(ThemeMode.dark);
        }
        break;

      case "change_setting/toggle_notifications":
        if (message.contains("turn off") || message.contains("disable")
              || message.contains("notifications off") || message.contains("stop")) {
          notificationsPermissionNotifier.value = false;
          CloudStorageService().saveUserSetting('jamieReminders', false);
        } else {
          notificationsPermissionNotifier.value = true;
          CloudStorageService().saveUserSetting('jamieReminders', true);
        }
        break;

      case "change_setting/toggle_location":
        if (message.contains("turn off") || message.contains("disable")
              || message.contains("location off") || message.contains("stop")) {
          LocalStorageService().setLocationAccess(false);
        } else { LocalStorageService().setLocationAccess(true); }
        break;

      case "change_setting/disable_jamie":
        _toggleJamieEnabled(false);
        break;

      case "change_setting/toggle_wakeword":
        if (message.contains("turn off") || message.contains("disable") || message.contains("stop")
              || message.contains("activation phrase off") || message.contains("voice activation off")) {
          wakeWordEnabledNotifier.value = false;
          CloudStorageService().saveUserSetting('wakeWordEnabled', false);
        } else {
          wakeWordEnabledNotifier.value = true;
          CloudStorageService().saveUserSetting('wakeWordEnabled', true);
        }
        break;

      case "change_setting/toggle_reminders":
        if (message.contains("turn off") || message.contains("disable") || message.contains("stop")
            || message.contains("reminders off")) {
          jamieReminders = false;
          jamieRemindersNotifier.value = false;
          CloudStorageService().saveUserSetting('remindersEnabled', false);
        } else {
          jamieReminders = true;
          jamieRemindersNotifier.value = true;
          CloudStorageService().saveUserSetting('remindersEnabled', true);
        }
      default:
        debugPrint("⚠️ No handler for intent: $intentId");
        break;
    }
  }

  Future<void> _toggleJamieEnabled(bool enabled, {VoidCallback? onSetState}) async {
    if (enabled) {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        jamieEnabled = true;
        jamieEnabledNotifier.value = true;
        await CloudStorageService().saveUserSetting('jamieEnabled', true);
        onSetState?.call(); // optional for UI state updates
      } else {
        jamieEnabled = false;
        jamieEnabledNotifier.value = false;
        onSetState?.call();
      }
    } else {
      jamieEnabled = false;
      jamieEnabledNotifier.value = false;
      await CloudStorageService().saveUserSetting('jamieEnabled', false);
      onSetState?.call();
    }
  }


  int _getIntentAudioCount(String intentId) {
    switch (intentId) {
      case "navigate/dashboard":
      case "navigate/settings":
      case "navigate/events":
        return 7;

      case "change_setting/toggle_theme":
      case "change_setting/change_theme":
      case "change_setting/toggle_notifications":
      case "change_setting/toggle_location":
      case "change_setting/disable_jamie":
        return 6;

      case "just_talk/joke":
        return 12;

      default:
        return 3; // fallback
    }
  }

  ScrollData? getScrollDataForIntent(String intentId) {
    switch (intentId) {
      case "tap_widget/settings/show_credits":
        return const ScrollData(offset: 690);

      case "tap_widget/settings/show_sessions":
        return const ScrollData(offset: 540);



      case "tap_widget/contact/tutorial_1":
        return const ScrollData(index: 0);

      case "tap_widget/contact/tutorial_2":
        return const ScrollData(index: 1);

      case "tap_widget/contact/tutorial_3":
        return const ScrollData(index: 2);

      case "tap_widget/contact/tutorial_4":
        return const ScrollData(index: 3);

      case "tap_widget/contact/tutorial_5":
        return const ScrollData(index: 4);



      default:
        return null; // No scroll needed
    }
  }

}