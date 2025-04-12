import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  Timer? _cooldownTimer;
  bool _cooldownActive = false;
  bool _loopRunning = false;

  Completer<void>? _listeningCompleter;



  Future<void> initPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
  }

  Future<void> playResponseFile(List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/jamie_response.mp3");
    await file.writeAsBytes(bytes);

    debugPrint("📦 Playing from: ${file.path}");
    assistantState.value = JamieState.speaking;

    final completer = Completer<void>();

    _player.onPlayerComplete.listen((_) {
      debugPrint("🔊 Playback completed");
      if (!completer.isCompleted) completer.complete();
    });

    await _player.play(DeviceFileSource(file.path));

    // Wait for playback to finish
    await completer.future;
  }


  Future<List<int>> sendTextToBackend(String message, String userId) async {
    final uri = Uri.parse('https://optima-livekit-token-server.onrender.com/chat');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "message": message,
        "userId": userId,
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      debugPrint("❌ Chat request failed: ${response.statusCode}");
      return [];
    }
  }



  void _startCooldown() {
    _cooldownActive = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(minutes: 2), () {
      _cooldownActive = false;
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

    while (true) {
      if (!keepAiRunning || aiSpeaking || isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      try {
        // Wake word detection
        if (!_cooldownActive && !wakeWordDetected) {
          assistantState.value = JamieState.idle;
          isListening = true;

          await _speech.listenForWakeWordLoop(
            onTranscript: (text) => {},
          );

          isListening = false;
          aiSpeaking = false;
          wakeWordDetected = true;
        }

        // User message capture
        if (wakeWordDetected && !aiSpeaking && !isListening) {
          assistantState.value = JamieState.listening;
          isListening = true;

          _listeningCompleter = Completer<void>();

          await _speech.startListening(
                (text) {
              transcribedText.value = text;
            },
                () async {
              await _speech.stopListening();
              if (_listeningCompleter?.isCompleted ?? false) return;
              _completeListening();

              assistantState.value = JamieState.thinking;

              final rawTranscript = transcribedText.value.trim();

              final match = RegExp(r"hey jamie\s*", caseSensitive: false).firstMatch(rawTranscript);
              final cleaned = match != null
                  ? rawTranscript.substring(match.end).trim()
                  : rawTranscript;

              debugPrint("📝 Raw: $rawTranscript");
              debugPrint("🧹 Cleaned: $cleaned");

              if (cleaned.isEmpty) {
                debugPrint("🚫 Nothing to send after cleaning.");
                isListening = false;
                wakeWordDetected = false;
                return;
              }

              aiSpeaking = true;
              final response = await sendTextToBackend(cleaned, userId);
              await playResponseFile(response);

              aiSpeaking = false;
              isListening = false;
              wakeWordDetected = true;
              _startCooldown();
            },
          );


          await _listeningCompleter?.future;
        }
      } catch (e) {
        handleError(e);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

}
