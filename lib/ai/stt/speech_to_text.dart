import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:optima/globals.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _doneCalled = false;

  Future<void> init() async {
    _isInitialized = await _speech.initialize();
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening(
      Function(String) onResult,
      Function() onDone,
      ) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return;

    _doneCalled = false;

    _speech.statusListener = (status) {
      debugPrint("🎤 Speech status: $status");
      if (status == 'notListening' && !_doneCalled) {
        _doneCalled = true;
        onDone();
      }
    };

    _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    if (_isInitialized) {
      _doneCalled = true;
      _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_isInitialized) _speech.cancel();
  }

  Future<void> resumeListeningAfterPlayback({
    required Function(String) onResult,
    required Function() onDone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100)); // small buffer
    await startListening(onResult, onDone);
  }

  Future<String> listenForWakeWordLoop({
    required Function(String) onTranscript,
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return '';

    final completer = Completer<String>();
    String currentTranscript = '';

    Future<void> beginListening() async {
      if (_speech.isListening || completer.isCompleted) return;

      debugPrint("🎧 Starting (or restarting) wake listener...");

      _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase().trim();
          currentTranscript = text;
          onTranscript(text);

          if (text.contains("hey jamie") && !completer.isCompleted) {
            stopListening();
            final index = text.indexOf("hey jamie");
            final cleaned = text.substring(index).trim();
            debugPrint("✅ Wake word detected: $cleaned");
            completer.complete(cleaned);
            _speech.cancel();
          }
        },
        listenMode: ListenMode.dictation,
        partialResults: true,
      );
    }

    _speech.statusListener = (status) {
      debugPrint("🎤 Wake listener status: $status");
      if (status == 'notListening' && !completer.isCompleted) {
        debugPrint("🔁 Restarting due to auto-stop");
        Future.delayed(const Duration(milliseconds: 200), beginListening);
      }
    };

    // Clean stale transcript every few seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_speech.isListening || completer.isCompleted) {
        timer.cancel();
      } else if (!currentTranscript.contains("hey jamie")) {
        debugPrint("🧹 Clearing junk transcript");
        currentTranscript = '';
      }
    });

    beginListening(); // Start first time
    return completer.future;
  }
}
