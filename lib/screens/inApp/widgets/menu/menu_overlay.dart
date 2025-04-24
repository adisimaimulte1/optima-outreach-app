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
            IgnorePointer(
              ignoring: !isOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isOpen ? 1.0 : 0.0,
                child: appMenu,
              ),
            ),

            IgnorePointer(
              ignoring: isOpen,
              child: child,
            ),

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
