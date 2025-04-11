import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:optima/globals.dart';

class AIVoiceAssistant {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> initPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }

    if (!await _recorder.hasPermission()) {
      throw Exception("Recorder permission not granted");
    }
  }

  Future<String> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/input.wav';

    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      sampleRate: 16000,
    );

    await _recorder.start(config, path: path);
    debugPrint("🎙️ Recording started at: $path");

    return path;
  }

  Future<File> monitorAmplitude({
    required String filePath,
    double thresholdDb = -15.0,
    Duration minDuration = const Duration(seconds: 3),
    Duration silenceDuration = const Duration(seconds: 2),
  })
  async {
    bool voiceDetected = false;
    bool silenceOngoing = false;
    Timer? silenceTimer;
    final completer = Completer<File>();

    late StreamSubscription<Amplitude> subscription;
    subscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
      final db = amp.current;

      if (db > thresholdDb) {
        if (!voiceDetected) {
          assistantState.value = JamieState.listening;
          debugPrint("🗣️ Voice detected. Waiting for silence to stop it...");
        }
        voiceDetected = true;
        silenceOngoing = false;
        silenceTimer?.cancel();
      } else {
        if (voiceDetected && !silenceOngoing) {
          silenceOngoing = true;
          debugPrint("🤫 Silence detected. Waiting for ${silenceDuration.inSeconds}s...");
          silenceTimer?.cancel();
          silenceTimer = Timer(silenceDuration, () async {
            final recordedPath = await _recorder.stop();
            debugPrint("🛑 Voice ended. Recording stopped.");
            await subscription.cancel();
            assistantState.value = JamieState.thinking;
            completer.complete(File(recordedPath!));
          });
        }
      }
    });

    await Future.delayed(minDuration);

    if (!voiceDetected) {
      debugPrint("❌ No voice detected in initial $minDuration. Stopping early.");
      final recordedPath = await _recorder.stop();
      await subscription.cancel();
      assistantState.value = JamieState.idle;
      return File(recordedPath!);
    }

    return completer.future;
  }

  Future<File> recordWithVoiceExtension({
    double thresholdDb = -15.0,
    Duration minDuration = const Duration(seconds: 3),
    Duration silenceDuration = const Duration(seconds: 2),
  })
  async {
    final path = await startRecording();
    return await monitorAmplitude(
      filePath: path,
      thresholdDb: thresholdDb,
      minDuration: minDuration,
      silenceDuration: silenceDuration,
    );
  }

  Future<http.StreamedResponse> sendAudioToBackend(File audio, String userId) async {
    final uri = Uri.parse('https://optima-livekit-token-server.onrender.com/voiceStream');

    final request = http.MultipartRequest('POST', uri)
      ..fields['userId'] = userId
      ..files.add(await http.MultipartFile.fromPath('audio', audio.path));

    return await request.send();
  }

  Future<void> processServerResponse(http.StreamedResponse response) async {
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      if (bytes.isEmpty) {
        debugPrint("😶 No response from Jamie (inactive or cooldown).");
            assistantState.value = JamieState.idle;
            } else {
            await playResponseFile(bytes);
            }
            } else {
            debugPrint('❌ VoiceStream failed: ${response.statusCode}');
            assistantState.value = JamieState.idle;
            }
        }

  Future<void> playResponseFile(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/response.mp3';
    final file = File(path);
    await file.writeAsBytes(bytes);

    assistantState.value = JamieState.speaking;
    await _player.setAudioSource(AudioSource.file(path));
    await _player.play();
    await _player.playerStateStream.firstWhere(
            (s) => s.processingState == ProcessingState.completed);

    debugPrint("✅ Playback finished, resuming loop.");
  }

  void handleError(Object e) {
    debugPrint("💥 Error: $e");
    assistantState.value = JamieState.idle;
  }




  Future<void> runAssistant({required String userId}) async {
    try {
      await initPermissions();
    } catch (e) {
      handleError(e);
      return;
    }

    while (true) {
      if (!keepAiRunning) {
        assistantState.value = JamieState.idle;
        continue;
      }

      try {
        final audio = await recordWithVoiceExtension();

        if (!audio.existsSync()) {
          debugPrint("❌ Audio file doesn't exist.");
          assistantState.value = JamieState.idle;
          continue;
        }

        final response = await sendAudioToBackend(audio, userId);
        await processServerResponse(response);
        assistantState.value = JamieState.idle;
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        handleError(e);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
