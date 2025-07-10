import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/ai_navigator.dart';
import 'package:optima/globals.dart';

class TriggerProxy extends StatefulWidget {
  final VoidCallback onTriggered;

  const TriggerProxy({super.key, required this.onTriggered});

  @override
  State<TriggerProxy> createState() => TriggerProxyState();
}

class TriggerProxyState extends State<TriggerProxy> implements Triggerable {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> triggerFromAI() async {
    if (screenScaleNotifier.value >= 0.99) {
      widget.onTriggered();
    } else {
      debugPrint("🔒 TriggerProxy ignored — screen not ready");
    }
  }
}
