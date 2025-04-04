import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final BoxDecoration backgroundGradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
          Color(0xFF292727), // dark grey-black
          Color(0xFF000000), // pure black
        ]
            : [
          Color(0xFFFFE8A7), // light yellow
          Color(0xFFFFC62D), // golden yellow
        ],
        stops: const [0.0, 1.0],
      ),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(32, statusBarHeight + 32, 32, 64),
      decoration: backgroundGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Menu items go here
        ],
      ),
    );
  }
}
