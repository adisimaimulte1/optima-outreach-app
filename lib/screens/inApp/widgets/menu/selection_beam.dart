import 'package:flutter/material.dart';

import 'package:optima/globals.dart';

import 'dart:async';
import 'dart:math';


class ParticleBeamEffect extends StatefulWidget {
  final Offset start;
  final Offset end;
  final int maxParticles;
  final Duration spawnRate;
  final VoidCallback? onComplete;

  const ParticleBeamEffect({
    super.key,
    required this.start,
    required this.end,
    this.maxParticles = 1000,
    this.spawnRate = const Duration(milliseconds: 100),
    this.onComplete,
  });

  @override
  State<ParticleBeamEffect> createState() => ParticleBeamEffectState();
}

class ParticleBeamEffectState extends State<ParticleBeamEffect>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<_FlyingParticle> _particles = [];
  Timer? _spawnTimer;
  bool _spawningStopped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSpawning();
  }



  void _startSpawning() {
    _spawnTimer = Timer.periodic(widget.spawnRate, (_) {
      if (_spawningStopped) return;

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 6000),
      );

      final anim = Tween<Offset>(
        begin: widget.start,
        end: widget.end,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );

      final size = 7.0 + Random().nextDouble() * 6;
      final dx = (Random().nextDouble() - 0.5) * 60;
      final dy = (Random().nextDouble() - 0.5) * 60;

      final particle = _FlyingParticle(
        animation: anim,
        controller: controller,
        offset: Offset(dx, dy),
        size: size,
      );

      controller.forward().then((_) {
        controller.dispose();
        setState(() {
          _particles.remove(particle);
        });
        _checkIfDone();
      });

      setState(() {
        _particles.add(particle);
      });
    });
  }

  void stopSpawning() {
    if (_spawningStopped) return;
    _spawningStopped = true;
    _spawnTimer?.cancel();
  }

  void _pauseSpawning() {
    _spawnTimer?.cancel();
    for (var p in _particles) {
      p.controller.stop(canceled: false);
    }
  }

  void _resumeSpawning() {
    if (!_spawningStopped) {
      _startSpawning();
    }
    for (var p in _particles) {
      if (!p.controller.isAnimating) {
        p.controller.forward();
      }
    }
  }



  void _checkIfDone() {
    if (_spawningStopped && _particles.isEmpty) {
      widget.onComplete?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseSpawning();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSpawning();
    }
  }



  @override
  Widget build(BuildContext context) {

    return Stack(
      children: _particles.map((p) {
        return AnimatedBuilder(
          animation: p.animation,
          builder: (_, __) {
            final pos = p.animation.value + p.offset;
            final start = widget.start;
            final distanceFromStart = (pos - start).distance;
            const fadeStart = 40.0;
            const fadeLength = 8.0;

            final visibility = ((distanceFromStart - fadeStart) / fadeLength).clamp(0.0, 1.0);

            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: Opacity(
                opacity: visibility,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inAppBackgroundColor,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spawnTimer?.cancel();
    for (var p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }
}



class _FlyingParticle {
  final Animation<Offset> animation;
  final AnimationController controller;
  final Offset offset;
  final double size;

  _FlyingParticle({
    required this.animation,
    required this.controller,
    required this.offset,
    required this.size,
  });
}
