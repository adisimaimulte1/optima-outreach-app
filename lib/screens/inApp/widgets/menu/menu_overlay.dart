import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class AppMenuOverlay extends StatelessWidget {
  final Widget child;
  const AppMenuOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ValueListenableBuilder<bool>(
      valueListenable: isMenuOpenNotifier,
      builder: (context, isOpen, _) {
        return Stack(
          children: [
            // 🔹 Menu: fully interactive only when open
            IgnorePointer(
              ignoring: !isOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isOpen ? 1.0 : 0.0,
                child: appMenu,
              ),
            ),

            // 🔹 Child: always visible, but doesn't block menu touches
            IgnorePointer(
              ignoring: isOpen, // disable when menu is open
              child: child,
            ),

            // 🔹 Custom Tap Region: allows both layers to receive taps
            if (isOpen)
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: screenSize.width * 0.4,
                  height: screenSize.height * 0.4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      screenScaleNotifier.value = 1.0;
                      isMenuOpenNotifier.value = false;
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
