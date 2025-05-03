import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:optima/globals.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _doneCalled = false;

  Future<void> init() async { _isInitialized = await _speech.initialize(); }
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

  Future<String> listenForWakeWordLoop({required Function(String) onTranscript,}) async {
    if (!jamieEnabledNotifier.value || !wakeWordEnabledNotifier.value) return '';
    if (!_isInitialized) await init();
    if (!_isInitialized) return '';

    final completer = Completer<String>();
    String currentTranscript = '';
    bool cancelled = false;

    void cancelIfDisabled() {
      if (!jamieEnabledNotifier.value || !wakeWordEnabledNotifier.value) {
        if (!completer.isCompleted) {
          debugPrint("🛑 Wake loop cancelled by setting change");
          cancelled = true;
          _speech.cancel();
          completer.complete('');
        }
      }
    }

    wakeWordEnabledNotifier.addListener(cancelIfDisabled);
    jamieEnabledNotifier.addListener(cancelIfDisabled);

    Future<void> beginListening() async {
      if (_speech.isListening || completer.isCompleted || cancelled) return;
      if (!jamieEnabledNotifier.value || !wakeWordEnabledNotifier.value) return;

      _speech.listen(
        onResult: (result) {
          if (cancelled) return;
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

    _speech.statusListener = (status) async {
      if (cancelled) return;

      if (status == 'listening') debugPrint("🎤 Wake listener status: $status");
      if (status == 'notListening' && !completer.isCompleted) {
        if (appPaused) _speech.cancel();
        while (appPaused) {
          await Future.delayed(const Duration(milliseconds: 200));
        }

        if (!cancelled && jamieEnabledNotifier.value && wakeWordEnabledNotifier.value) {
          Future.delayed(const Duration(milliseconds: 100), beginListening);
        } else {
          debugPrint("🛑 Wake listener disabled mid-session");
          completer.complete('');
          _speech.stop();
        }
      }
    };

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (cancelled || completer.isCompleted) {
        timer.cancel();
        return;
      }

      if (appPaused) _speech.cancel();
      while (appPaused) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      Future.delayed(const Duration(milliseconds: 100), beginListening);

      if (!_speech.isListening) {
        timer.cancel();
      } else if (!currentTranscript.contains("hey jamie")) {
        currentTranscript = '';
      }
    });

    if (!cancelled && jamieEnabledNotifier.value && wakeWordEnabledNotifier.value) {
      beginListening();
    }

    try {
      return await completer.future;
    } finally {
      wakeWordEnabledNotifier.removeListener(cancelIfDisabled);
      jamieEnabledNotifier.removeListener(cancelIfDisabled);
    }
  }

}
