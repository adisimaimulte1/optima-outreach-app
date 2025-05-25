import 'package:optima/ai/processor/intent_registry.dart';

class IntentProcessor {
  static final List<String> _negations = [
    "don't", "do not", "never", "no", "stop", "not", "cancel"
  ];

  static String? detectIntent(String input) {
    for (final intent in IntentRegistry.allIntents) {
      if (intent.matches(input, _negations)) {
        return intent.id;
      }
    }
    return null;
  }
}
