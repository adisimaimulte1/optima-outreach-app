import 'dart:async';

import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class AnimatedVolumeIconWithLabel extends StatefulWidget {
  const AnimatedVolumeIconWithLabel({super.key});

  @override
  State<AnimatedVolumeIconWithLabel> createState() =>
      _AnimatedVolumeIconWithLabelState();
}

class _AnimatedVolumeIconWithLabelState
    extends State<AnimatedVolumeIconWithLabel> {
  int _step = 0;
  late final List<_VolumeIconState> _states;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _states = [
      _VolumeIconState(Icons.volume_mute_rounded, 'turn your volume up'),
      _VolumeIconState(Icons.volume_down_rounded, 'turn your volume up'),
      _VolumeIconState(Icons.volume_up_rounded, 'turn your volume up'),
    ];

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() => _step = (_step + 1) % _states.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _states[_step];
    return Column(
      children: [
        Icon(current.icon, size: 120, color: textHighlightedColor),

      ],
    );
  }
}

class _VolumeIconState {
  final IconData icon;
  final String label;

  _VolumeIconState(this.icon, this.label);
}
