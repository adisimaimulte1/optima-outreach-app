import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
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
  bool _cooldownActive = false;
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
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
  }




  void startLoop() {
    if (!_hasAttachedListener) {
      _hasAttachedListener = true;

      jamieEnabledNotifier.addListener(() {
        debugPrint("🎛 Jamie setting changed: ${jamieEnabledNotifier.value}");

        if (jamieEnabledNotifier.value) {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            runAssistant(userId: userId);
          }
        } else {
          stopLoop();
          debugPrint("🛑 Jamie disabled via settings.");
        }
      });
    }
  }

  void stopLoop({settingsStop = false}) {
    _loopRunning = false;
    _cooldownActive = false;
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




  Future<void> runAssistant({required String userId}) async {
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
        if (!_cooldownActive && !wakeWordDetected) { await _detectWakeWord(); }
        if (wakeWordDetected && !aiSpeaking && !isListening) { await _captureAndRespond(userId); }

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
    wakeWordDetected = true;
    assistantState.value = JamieState.thinking;

    if ((wakeTranscript ?? "").toLowerCase().contains("hey jamie")) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _respondToUser("hey jamie", userId);
      }
    }
  }

  Future<void> _captureAndRespond(String userId) async {
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
            () async => await _handleTranscript(userId, () => processed = true, () => processed),
      );

      while (!_listeningCompleter!.isCompleted && !cancelled) {
        if (appPaused && _speech.isListening) {
          debugPrint("⏸ Pausing listening due to background");
          await _speech.stopListening();
        }

        if (!appPaused && !_speech.isListening && !processed) {
          debugPrint("▶️ Resuming listening after app resumed");
          transcribedText.value = '';
          await _speech.resumeListeningAfterPlayback(
            onResult: (text) => transcribedText.value = text,
            onDone: () async => await _handleTranscript(userId, () => processed = true, () => processed),
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

  Future<void> _handleTranscript(String userId, VoidCallback markProcessed, bool Function() isProcessed) async {
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
    await _respondToUser(cleaned, userId);
  }

  Future<void> _respondToUser(String message, String userId) async {
    aiSpeaking = true;
    final response = await sendTextToBackend(message, userId);

    while (appPaused) {
      await Future.delayed(const Duration(milliseconds: 30));
    }

    assistantState.value = JamieState.speaking;
    await playResponseFile(response);

    aiSpeaking = false;
    isListening = false;

    if (jamieEnabledNotifier.value) {
      wakeWordDetected = true;
      assistantState.value = JamieState.listening;
      _startCooldown();
    } else {
      wakeWordDetected = false;
      assistantState.value = JamieState.idle;
    }
  }

  Future<void> playResponseFile(List<int> bytes) async {
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
  }



  void pauseImmediately() {
    if (_player.state == PlayerState.playing) {
      _player.pause();
      debugPrint("🛑 Immediate forced pause due to lifecycle");
    }
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

  Future<void> warmUpAssistant(String userId) async {
    final tempSpeech = SpeechToTextService();
    await tempSpeech.startListening((_) {}, () {});
    await tempSpeech.stopListening();

    try {
      debugPrint("🌡️ Warming up Jamie...");
      final dummyResponse = await sendTextToBackend("This is a warm-up request", userId);
      debugPrint(dummyResponse.isNotEmpty ? "🔥 Jamie is warmed up." : "⚠️ Warm-up returned no audio.");
    } catch (e) {
      debugPrint("❌ Warm-up failed: $e");
    }
  }



  void _startCooldown() {
    _cooldownActive = true;
    _cooldownTimer?.cancel();
    debugPrint("🧊 Cooldown started. Assistant will pause for 50 seconds.");

    _cooldownTimer = Timer(const Duration(seconds: 50), () {
      _cooldownActive = false;
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
}