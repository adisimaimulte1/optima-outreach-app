import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/tiles.dart';

class CustomThemeDropdown extends StatefulWidget {
  final ThemeMode selectedTheme;
  final ThemeSetter onChanged;

  const CustomThemeDropdown({
    super.key,
    required this.selectedTheme,
    required this.onChanged,
  });

  @override
  State<CustomThemeDropdown> createState() => _CustomThemeDropdownState();
}

class _CustomThemeDropdownState extends State<CustomThemeDropdown> {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.0 && _scale != 1.0) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _showMenu() async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    final result = await showMenu<ThemeMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 6,
        offset.dx + box.size.width,
        offset.dy,
      ),
      elevation: 0,
      color: Colors.transparent,
      items: [
        PopupMenuItem<ThemeMode>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: inAppForegroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textDimColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _customOption(ThemeMode.system, "System", Icons.devices),
                _customOption(ThemeMode.light, "Light", Icons.wb_sunny_rounded),
                _customOption(ThemeMode.dark, "Dark", Icons.nightlight_round),
              ],
            ),
          ),
        ),
      ],
    );

    if (result != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.onChanged(result);
      });
    }
  }

  IconData _iconForTheme(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return Icons.devices;
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.nightlight_round;
    }
  }

  Widget _customOption(ThemeMode mode, String label, IconData icon) {
    final isSelected = widget.selectedTheme == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap: () {
        Navigator.pop(context, mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3C54) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconTheme.merge(
              data: const IconThemeData(opacity: 1.0),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? textHighlightedColor : Colors.white70,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        if (screenScaleNotifier.value == 1.0) {
          _setPressed(false);
          _showMenu();
        }
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 64, // or adjust as needed (56–68 usually works)
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: inAppBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: textDimColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconTheme.merge(
                      data: const IconThemeData(opacity: 1.0),
                      child: Icon(
                        _iconForTheme(widget.selectedTheme),
                        color: textHighlightedColor,
                        size: 18,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: textColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


