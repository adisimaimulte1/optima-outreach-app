import 'package:flutter/material.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:optima/globals.dart';

class BackgroundParticles extends StatefulWidget {
  const BackgroundParticles({super.key});

  @override
  State<BackgroundParticles> createState() => _BackgroundParticlesState();
}

class _BackgroundParticlesState extends State<BackgroundParticles> with WidgetsBindingObserver {
  double _currentHeight = 0;
  double _currentWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _currentHeight = size.height;
      _currentWidth = size.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final particleColor = isDarkModeNotifier.value
        ? Colors.white.withOpacity(0.3)
        : inAppBackgroundColor.withOpacity(0.3);

    final mediaSize = MediaQuery.of(context).size;

    // Initialize once if not set
    if (_currentHeight == 0) _currentHeight = mediaSize.height;
    if (_currentWidth == 0) _currentWidth = mediaSize.width;

    return IgnorePointer(
      ignoring: true,
      child: CircularParticle(
        awayRadius: 80,
        numberOfParticles: 110,
        speedOfParticles: 1.2,
        height: _currentHeight,
        width: _currentWidth,
        onTapAnimation: false,
        particleColor: particleColor,
        awayAnimationDuration: const Duration(milliseconds: 600),
        maxParticleSize: 4,
        isRandSize: true,
        isRandomColor: false,
        connectDots: false,
      ),
    );
  }
}
