import 'package:optima/ai/processor/intent_registry.dart';

class IntentProcessor {
  static final List<String> _negations = [
    "don't", "do not", "never", "no", "stop", "not", "cancel"
  ];

  static final List<String> _splitters = [
    ",", "and", "then", "also", "after that", "next", "plus", "but"
  ];

  static final List<String> _reverseHints = [
    "before", "prior to that", "earlier", "first",
  ];





  static List<String> detectIntents(String input) {
    final parts = _splitInput(input.toLowerCase());
    final matchedIntents = <String>[];

    bool shouldReverse = parts.any((part) {
      return _reverseHints.any((hint) => part.trim().startsWith(hint));
    });

    final processedParts = shouldReverse ? parts.reversed : parts;

    for (final part in processedParts) {
      for (final intent in IntentRegistry.allIntents) {
        if (intent.matches(part, _negations)) {
          matchedIntents.add(intent.id);
          break;
        }
      }
    }

    return matchedIntents;
  }

  static List<String> _splitInput(String input) {
    var result = <String>[input];
    for (final splitter in _splitters) {
      result = result.expand((chunk) => chunk.split(splitter)).toList();
    }
    return result.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
