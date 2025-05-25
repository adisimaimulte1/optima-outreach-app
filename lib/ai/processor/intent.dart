class Intent {
  final String id;
  final List<String> triggers;
  final List<String> targets;

  Intent({
    required this.id,
    required this.triggers,
    required this.targets,
  });

  bool matches(String input, List<String> negations) {
    final normalized = input.toLowerCase();

    for (final trigger in triggers) {
      if (!normalized.contains(trigger)) continue;

      for (final target in targets) {
        if (!normalized.contains(target)) continue;

        final triggerIndex = normalized.indexOf(trigger);
        final targetIndex = normalized.indexOf(target);

        final isNegated = negations.any((neg) {
          final negIndex = normalized.indexOf(neg);
          return negIndex != -1 &&
              (negIndex < triggerIndex || negIndex < targetIndex);
        });

        if (!isNegated) return true;
      }
    }

    return false;
  }
}
