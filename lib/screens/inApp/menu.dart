import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/util/aichat.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/settings.dart';

import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/widgets/menu/selection_beam.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';


class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => MenuState();
}

class MenuState extends State<Menu> {
  Offset? selectedTarget;

  final List<Widget> _activeBeams = [];
  ScreenType? _pendingScreenChange;


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
    screenScaleNotifier.addListener(_onScreenScaleChanged);

    // Delay the execution to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (screenScaleNotifier.value == 0.4 && _activeBeams.isEmpty) {
        _handleIncomingSource();
      }
    });
  }



  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<UniqueKey>(
        valueListenable: appReloadKey,
        builder: (_, key, __) {
          return KeyedSubtree(
              key: key, // ← this forces subtree to rebuild
              child: ValueListenableBuilder<double>(
                valueListenable: screenScaleNotifier,
                builder: (context, scale, _) {
                  final double opacity = ((1.0 - scale) / (1.0 - 0.4)).clamp(0.0, 1.0);
                  return _buildMenu(context, opacity, scale);
                  },
              ));
        });
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
            ? [darkColorSecondary, darkColorPrimary]
            : [lightColorSecondary, lightColorPrimary],
      ),
    );
  }



  void _onScreenScaleChanged() {
    final isFull = screenScaleNotifier.value >= 0.99;
    final isMinimized = screenScaleNotifier.value == 0.4;

    if (isMinimized && _activeBeams.isEmpty) {
      if (selectedScreenNotifier.value != ScreenType.settings) {
        ScrollPersistence.offset = 0.0;
      }

      _handleIncomingSource();
    } else if (isFull && _activeBeams.isNotEmpty) {
      setState(() {
        _activeBeams.clear();
      });
    }
  }



  void _handleIncomingSource() {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final usableHeight = screenSize.height - padding.top - padding.bottom;
    final Offset center = Offset(screenSize.width / 2, padding.top + usableHeight / 2);

    final Offset topArcCenter = Offset(screenSize.width / 2, usableHeight * 0.23);
    final Offset bottomArcCenter = Offset(screenSize.width / 2, usableHeight * 0.77);

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
      else if (index == 1) { return Offset(dx, dy + 140); }
      else if (index == 1) { return Offset(dx, dy + 140); }
      else if (index == 2) { return Offset(dx + 130, dy + 80); }

      return Offset(dx, dy);
    });

    // find the right icon to pre-select
    final source = custom_menu.MenuController.instance.sourceScreen;
    Offset? iconPosition;


    // now find the position of that icon
    if (source == DashboardScreen) {
      _pendingScreenChange = ScreenType.dashboard;
      iconPosition = topIconsPositions[0];
    } else if (source == SettingsScreen) {
      _pendingScreenChange = ScreenType.settings;
      iconPosition = bottomIconsPositions[2];
    } else if (source == EventsScreen){
      _pendingScreenChange = ScreenType.events;
      iconPosition = topIconsPositions[1];
    } else if (source == ChatScreen){
      _pendingScreenChange = ScreenType.chat;
      iconPosition = bottomIconsPositions[1];
    } else {
      _pendingScreenChange = ScreenType.dashboard;
      iconPosition = topIconsPositions[0];
    }


    // start the beam bby
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



  List<Widget> _positionIconsInArc({
    required List<IconData> icons,
    required Offset center,
    required double horizontalOffset,
    required double verticalOffset,
    required double opacity,
    required double scale,
  })
  {
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




                        if (icons[index] == LucideIcons.layoutDashboard) {
                          _pendingScreenChange = ScreenType.dashboard;
                        } else if (icons[index] == LucideIcons.settings) {
                          _pendingScreenChange = ScreenType.settings;
                        } else if (icons[index] == LucideIcons.calendarDays) {
                          _pendingScreenChange = ScreenType.events;
                        } else if (icons[index] == LucideIcons.users) {
                          _pendingScreenChange = ScreenType.users;
                        } else if (icons[index] == LucideIcons.contact) {
                          _pendingScreenChange = ScreenType.contact;
                        } else if (icons[index] == LucideIcons.brain) {
                          _pendingScreenChange = ScreenType.chat;
                        } else {
                          _pendingScreenChange = ScreenType.dashboard;
                        }



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
                          return Transform.scale(
                            scale: scaleVal,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: inAppBackgroundColor,
                                  width: selectedTarget == Offset(dx, verticalOffset > 0 ? dy : dy + 80) ? 10 : 6,
                                ),
                              ),
                              child: Icon(icons[index], size: 40, color: inAppBackgroundColor),
                            ),
                          );
                        },
                        onEnd: () {
                          if (_pendingScreenChange != null) {
                            selectedScreenNotifier.value = _pendingScreenChange!;
                            _pendingScreenChange = null;
                          }
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




  void simulateTap(ScreenType screenType) {
    late Offset iconPosition;
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final usableHeight = screenSize.height - padding.top - padding.bottom;
    final center = Offset(screenSize.width / 2, padding.top + usableHeight / 2);

    // Determine the correct icon position
    switch (screenType) {
      case ScreenType.dashboard:
        custom_menu.MenuController.instance.selectSource(DashboardScreen);
        iconPosition = Offset(center.dx - 130, usableHeight * 0.23); break;
      case ScreenType.events:
        custom_menu.MenuController.instance.selectSource(EventsScreen);
        iconPosition = Offset(center.dx, usableHeight * 0.23 - 60); break;
      case ScreenType.users:
        custom_menu.MenuController.instance.selectSource(DashboardScreen);
        iconPosition = Offset(center.dx + 130, usableHeight * 0.23); break;
      case ScreenType.contact:
        custom_menu.MenuController.instance.selectSource(DashboardScreen);
        iconPosition = Offset(center.dx - 130, usableHeight * 0.77); break;
      case ScreenType.chat:
        custom_menu.MenuController.instance.selectSource(DashboardScreen);
        iconPosition = Offset(center.dx, usableHeight * 0.77 + 140); break;
      case ScreenType.settings:
        custom_menu.MenuController.instance.selectSource(SettingsScreen);
        iconPosition = Offset(center.dx + 130, usableHeight * 0.77 + 80); break;
      case ScreenType.menu:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    // Start beam
    final newBeamKey = GlobalKey<ParticleBeamEffectState>();
    final newBeam = ParticleBeamEffect(
      key: newBeamKey,
      start: iconPosition,
      end: center,
      spawnRate: const Duration(milliseconds: 90), // slower for realism
      maxParticles: 50,
    );

    for (final beam in _activeBeams) {
      if (beam.key is GlobalKey) {
        final currentState = (beam.key as GlobalKey).currentState;
        if (currentState is ParticleBeamEffectState) {
          currentState.stopSpawning();
        }
      }
    }

    setState(() {
      selectedTarget = iconPosition;
      selectedScreenNotifier.value = screenType;
      _activeBeams.add(newBeam);
      _pendingScreenChange = screenType;
    });



  }


  void clearBeams() {
    _activeBeams.clear();
  }




  @override
  void dispose() {
    screenScaleNotifier.removeListener(_onScreenScaleChanged);
    super.dispose();
  }
}
