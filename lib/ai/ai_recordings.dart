import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:optima/globals.dart';

class AiRecordings {
  static final _random = Random();
  static final _player = AudioPlayer();

  static final List<Map<String, String>> _wakeQueue = List.from(_wakeResponses)..shuffle();
  static int _wakeIndex = 0;

  static final List<Map<String, String>> _intros = [
    {
      'file': 'intro1.mp3',
      'text': "Hey there, welcome back! What's your plan for today?"
    },
    {
      'file': 'intro2.mp3',
      'text': "Ah, you're here! Time to turn strategy into success."
    },
    {
      'file': 'intro3.mp3',
      'text': "Long time no see! Ready for some action today?"
    },
    {
      'file': 'intro4.mp3',
      'text': "Reboot complete. Outreach engine warmed and ready."
    },
    {
      'file': 'intro5.mp3',
      'text': "Oh, didn't see you there! What's up?"
    },
    {
      'file': 'intro6.mp3',
      'text': "You're back! Let's make some outreach magic happen."
    },
    {
      'file': 'intro7.mp3',
      'text': "How can I help you today my friend?"
    },
    {
      'file': 'introSecret.mp3',
      'text': "Hi! Do you know what's the AI's favorite drink? Strawberry juice!"
    }
  ];
  static final List<Map<String, String>> _wakeResponses = [
    {
      'file': 'wake_ack_1.mp3',
      'text': "Hey! I'm right here, ready when you are."
    },
    {
      'file': 'wake_ack_2.mp3',
      'text': "Welcome back. What can I help you with today?"
    },
    {
      'file': 'wake_ack_3.mp3',
      'text': "Hi again! Let’s get something done."
    },
    {
      'file': 'wake_ack_4.mp3',
      'text': "Here I am. Your mission control is standing by."
    },
    {
      'file': 'wake_ack_5.mp3',
      'text': "Listening. Just say the word."
    },
    {
      'file': 'wake_ack_6.mp3',
      'text': "Nice to hear from you! Let’s make this easy."
    },
    {
      'file': 'wake_ack_7.mp3',
      'text': "Jamie online. Ready to optimize your day."
    },
    {
      'file': 'wake_ack_8.mp3',
      'text': "Hello! Need help planning something awesome?"
    },
    {
      'file': 'wake_ack_9.mp3',
      'text': "Always glad to assist. What's next?"
    },
    {
      'file': 'wake_ack_10.mp3',
      'text': "Back in action. Let’s do something amazing."
    },
    {
      'file': 'wake_ack_11.mp3',
      'text': "Hi there! Let’s make this efficient and fun."
    },
    {
      'file': 'wake_ack_12.mp3',
      'text': "Ready when you are. Let's make this event shine."
    },
    {
      'file': 'wake_ack_13.mp3',
      'text': "Welcome back, superstar. What’s the plan?"
    },
    {
      'file': 'wake_ack_14.mp3',
      'text': "Let’s get organized — one brilliant step at a time."
    },
    {
      'file': 'wake_ack_15.mp3',
      'text': "Online and smiling. Well, internally."
    }
  ];

  /// Plays a random intro using AIVoiceAssistant and returns the transcript
  static Future<String> playRandomIntro() async {
    final response = _intros[_random.nextInt(_intros.length)];
    final bytes = await rootBundle.load('assets/audio/intro/${response['file']}');

    await aiVoice.playResponseFile(bytes.buffer.asUint8List());
    assistantState.value = JamieState.idle;

    return response['text']!;
  }


  /// Plays a random friendly wake-word response (no credit used)
  static Future<String> playWakeResponse() async {
    if (_wakeQueue.isEmpty) {
      _wakeQueue.addAll(_wakeResponses);
      _wakeQueue.shuffle();
      _wakeIndex = 0;
    }

    final response = _wakeQueue[_wakeIndex];
    _wakeIndex = (_wakeIndex + 1) % _wakeQueue.length;

    final bytes = await rootBundle.load('assets/audio/wake/${response['file']}');

    await aiVoice.playResponseFile(bytes.buffer.asUint8List());
    assistantState.value = JamieState.idle;

    return response['text']!;
  }


  /// Stops any currently playing audio
  static Future<void> stop() async {
    await _player.stop();
  }
}
