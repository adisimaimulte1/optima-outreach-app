import 'package:flutter/material.dart';

import 'package:optima/screens/inApp/widgets/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/widgets/selection_beam.dart';
import 'package:optima/screens/inApp/dashboard.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';


class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  Offset? selectedTarget;
  final List<Widget> _activeBeams = [];

  Offset? _queuedTarget;

  final List<IconData> _topIcons = [
    LucideIcons.layoutDashboard,
    LucideIcons.calendarDays,
    LucideIcons.users,
  ];
  final List<IconData> _bottomIcons = [
    LucideIcons.contact,
    LucideIcons.brain,
    LucideIcons.settings,
  ];

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_onDashboardScaleChanged);
  }



  @override
  Widget build(BuildContext context) {


    return ValueListenableBuilder<double>(
      valueListenable: screenScaleNotifier,
      builder: (context, scale, _) {
        final double opacity = ((1.0 - scale) / (1.0 - 0.4)).clamp(0.0, 1.0);
        return _buildMenu(context, opacity, scale);
      },
    );
  }

  Widget _buildMenu(BuildContext context, double opacity, double scale) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - topPadding - bottomPadding;

    final Offset topArcCenter = Offset(screenWidth / 2, usableHeight * 0.23);
    final Offset bottomArcCenter = Offset(screenWidth / 2, usableHeight * 0.77);

    final backgroundGradient = _buildBackgroundGradient();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: backgroundGradient,
        ),
        Stack(
          children: [
            ..._activeBeams,
            ..._positionIconsInArc(
              icons: _topIcons,
              center: topArcCenter,
              horizontalOffset: 130,
              verticalOffset: 60,
              opacity: opacity,
              scale: scale,
            ),
            ..._positionIconsInArc(
              icons: _bottomIcons,
              center: bottomArcCenter,
              horizontalOffset: 130,
              verticalOffset: -60,
              opacity: opacity,
              scale: scale,
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDarkModeNotifier.value
            ? [const Color(0xFF292727), const Color(0xFF000000)]
            : [const Color(0xFFFFE8A7), const Color(0xFFFFC62D)],
      ),
    );
  }



  void _onDashboardScaleChanged() {
    final isDashboardFull = screenScaleNotifier.value >= 0.99;
    final isDashboardMinimized = screenScaleNotifier.value == 0.4;

    if (isDashboardMinimized && _activeBeams.isEmpty) {
      _handleIncomingSource();
    } else if (isDashboardFull && _activeBeams.isNotEmpty) {
      setState(() {
        _activeBeams.clear();
        _queuedTarget = null;
      });
    }
  }

  void _onBeamComplete() {
    setState(() {
      if (_queuedTarget != null) {
        final Offset target = _queuedTarget!;
        _queuedTarget = null;

        final screenSize = MediaQuery.of(context).size;
        final padding = MediaQuery.of(context).padding;
        final usableHeight = screenSize.height - padding.top - padding.bottom;
        final Offset center = Offset(screenSize.width / 2, padding.top + usableHeight / 2);

        _startBeam(target, center);
      }
    });
  }



  void _startBeam(Offset start, Offset end) {
    setState(() {
      _activeBeams.add(
        ParticleBeamEffect(
          key: UniqueKey(),
          start: start,
          end: end,
          spawnRate: const Duration(milliseconds: 80),
          maxParticles: 60,
          onComplete: _onBeamComplete,
        ),
      );
    });
  }

  void _handleIncomingSource() {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final usableHeight = screenSize.height - padding.top - padding.bottom;
    final Offset center = Offset(screenSize.width / 2, padding.top + usableHeight / 2);

    final Offset topArcCenter = Offset(screenSize.width / 2, usableHeight * 0.23);
    final Offset bottomArcCenter = Offset(screenSize.height / 2, usableHeight * 0.77);

    // get the position of all icons
    List<Offset>
    topIconsPositions = List.generate(3, (index) {
      double dx = topArcCenter.dx;
      double dy = topArcCenter.dy;

      if (index == 0) { return Offset(dx - 130, dy); }
      else if (index == 1) { return Offset(dx, dy - 60); }
      else if (index == 2) { return Offset(dx + 130, dy); }

      return Offset(dx, dy);
    }),
    bottomIconsPositions = List.generate(3, (index) {
      double dx = bottomArcCenter.dx;
      double dy = bottomArcCenter.dy;

      if (index == 0) { return Offset(dx - 130, dy); }
      else if (index == 1) { return Offset(dx, dy + 60); }
      else if (index == 2) { return Offset(dx + 130, dy); }

      return Offset(dx, dy);
    });

    // find the right icon to pre-select
    final source = custom_menu.MenuController.instance.sourceScreen;
    Offset? iconPosition;


    // now find the position of that icon
    if (source == DashboardScreen) {
      iconPosition = topIconsPositions[0];
    } else { iconPosition = topIconsPositions[0]; }


    // start the beam bby
    if (iconPosition != null) {
      final newBeamKey = GlobalKey<ParticleBeamEffectState>();
      final newBeam = ParticleBeamEffect(
        key: newBeamKey,
        start: iconPosition,
        end: center,
        spawnRate: const Duration(milliseconds: 80),
        maxParticles: 60,
      );

      setState(() {
        selectedTarget = iconPosition;
        _activeBeams.add(newBeam);
      });
    }
  }



  List<Widget> _positionIconsInArc({
    required List<IconData> icons,
    required Offset center,
    required double horizontalOffset,
    required double verticalOffset,
    required double opacity,
    required double scale,
  }) {
    final Map<int, double> pressScales = {};

    return List.generate(icons.length, (index) {
      double dx = center.dx;
      double dy = center.dy;

      pressScales[index] = 1.0;

      if (index == 0) {
        dx -= horizontalOffset;
      } else if (index == 1) {
        dy -= verticalOffset;
      } else if (index == 2) {
        dx += horizontalOffset;
      }

      return Positioned(
        left: dx - 40,
        top: verticalOffset > 0 ? dy - 40 : dy + 40,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: AnimatedSlide(
            offset: Offset(0, (1 - opacity) * (verticalOffset > 0 ? -3 : 3)),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: ((1.0 - scale) / (1.0 - 0.4)).clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: StatefulBuilder(
                  builder: (context, setInnerState) {
                    return GestureDetector(
                      onTapDown: (_) {
                        setInnerState(() => pressScales[index] = 0.70);
                      },
                      onTapUp: (_) {
                        setInnerState(() => pressScales[index] = 1.0);

                        final Offset iconPosition = Offset(dx, verticalOffset > 0 ? dy : dy + 80);
                        final screenSize = MediaQuery.of(context).size;
                        final padding = MediaQuery.of(context).padding;
                        final usableHeight = screenSize.height - padding.top - padding.bottom;
                        final Offset center = Offset(screenSize.width / 2, padding.top + usableHeight / 2);

                        for (final beam in _activeBeams) {
                          if (beam.key is GlobalKey) {
                            final currentState = (beam.key as GlobalKey).currentState;
                            if (currentState is ParticleBeamEffectState) {
                              currentState.stopSpawning();
                            }
                          }
                        }

                        final newBeamKey = GlobalKey<ParticleBeamEffectState>();
                        final newBeam = ParticleBeamEffect(
                          key: newBeamKey,
                          start: iconPosition,
                          end: center,
                          spawnRate: const Duration(milliseconds: 80),
                          maxParticles: 60,
                        );

                        setState(() {
                          selectedTarget = iconPosition;
                          _activeBeams.add(newBeam);
                        });
                      },
                      onTapCancel: () => setInnerState(() => pressScales[index] = 1.0),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: pressScales[index]!),
                        duration: const Duration(milliseconds: 100),
                        builder: (context, scaleVal, child) {
                          final iconColor = isDarkModeNotifier.value ? Colors.white : const Color(0xFF1C2837);
                          return Transform.scale(
                            scale: scaleVal,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: iconColor,
                                  width: selectedTarget == Offset(dx, verticalOffset > 0 ? dy : dy + 80) ? 10 : 6,
                                ),
                              ),
                              child: Icon(icons[index], size: 40, color: iconColor),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

    });
  }



  @override
  void dispose() {
    screenScaleNotifier.removeListener(_onDashboardScaleChanged);
    super.dispose();
  }
}
