import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/screens/inApp/globals.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - topPadding - bottomPadding;

    final BoxDecoration backgroundGradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF292727), const Color(0xFF000000)]
            : [const Color(0xFFFFE8A7), const Color(0xFFFFC62D)],
      ),
    );

    Widget circularMenuItem(IconData icon, double opacity) {
      return AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey[800] : Colors.white,
          ),
          child: Icon(
            icon,
            size: 40,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    List<Widget> positionIconsInArc({
      required List<IconData> icons,
      required Offset center,
      required double horizontalOffset,
      required double verticalOffset,
      required double opacity,
    }) {
      return List.generate(icons.length, (index) {
        double dx = center.dx;
        double dy = center.dy;

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
          child: circularMenuItem(icons[index], opacity),
        );
      });
    }

    final List<IconData> topIcons = [
      LucideIcons.layoutDashboard,
      LucideIcons.calendarDays,
      LucideIcons.users,
    ];
    final List<IconData> bottomIcons = [
      LucideIcons.contact,
      LucideIcons.brain,
      LucideIcons.settings,
    ];

    final Offset topArcCenter = Offset(screenWidth / 2, usableHeight * 0.23);
    final Offset bottomArcCenter = Offset(screenWidth / 2, usableHeight * 0.77);

    return ValueListenableBuilder<double>(
      valueListenable: dashboardScaleNotifier,
      builder: (context, scale, _) {
        final double opacity = ((1.0 - scale) / (1.0 - 0.4)).clamp(0.0, 1.0);

        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: backgroundGradient,
              child: Stack(
                children: [
                  ...positionIconsInArc(
                    icons: topIcons,
                    center: topArcCenter,
                    horizontalOffset: 125,
                    verticalOffset: 60,
                    opacity: opacity,
                  ),
                  ...positionIconsInArc(
                    icons: bottomIcons,
                    center: bottomArcCenter,
                    horizontalOffset: 125,
                    verticalOffset: -60,
                    opacity: opacity,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
