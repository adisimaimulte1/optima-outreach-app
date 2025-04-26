import 'package:flutter/material.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:optima/globals.dart';

class BackgroundParticles extends StatefulWidget {
  const BackgroundParticles({super.key});

  @override
  State<BackgroundParticles> createState() => _BackgroundParticlesState();
}

class _BackgroundParticlesState extends State<BackgroundParticles> {
  @override
  Widget build(BuildContext context) {
    final particleColor = isDarkModeNotifier.value
        ? Colors.white.withOpacity(0.3)
        : inAppBackgroundColor.withOpacity(0.3);

    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          ignoring: true,
          child: CircularParticle(
            awayRadius: 80,
            numberOfParticles: 110,
            speedOfParticles: 1.2,
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            onTapAnimation: false,
            particleColor: particleColor,
            awayAnimationDuration: const Duration(milliseconds: 600),
            maxParticleSize: 4,
            isRandSize: true,
            isRandomColor: false,
            connectDots: false,
          ),
        );
      },
    );
  }
}
