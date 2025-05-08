import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/icon_switcher.dart';
import 'package:optima/screens/inApp/widgets/settings/theme_dropdown.dart';


typedef EasterEggIconResolver = IconData Function();
typedef ThemeSetter = void Function(ThemeMode);

class Tiles {

  static Widget tile({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool showArrow = true,
    VoidCallback? onTap,
    required bool easterEggMode,
    required EasterEggIconResolver getNextEasterEggIcon,
    double leadingFraction = 1.0, // 👈 NEW: controls how much of the icon is visible
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  maxHeight: double.infinity,
                  child: TweenAnimationBuilder<Offset>(
                    tween: Tween<Offset>(
                      begin: Offset(0, 0),
                      end: Offset(0, 20 * (1 - leadingFraction.clamp(0.0, 1.0))),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: value,
                        child: child,
                      );
                    },
                    child: RevealIconSwitcher(
                      currentIcon: (leadingFraction != 1.0
                          ? (easterEggMode ? icon : Icons.wb_sunny)
                          : (easterEggMode ? getNextEasterEggIcon() : icon)),
                    ),
                  ),

                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }


  static Widget switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool easterEggMode,
    required EasterEggIconResolver getNextEasterEggIcon,
  }) {
    return SizedBox(
      height: 44,
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: RevealIconSwitcher(
          currentIcon: easterEggMode ? getNextEasterEggIcon() : icon,
        ),
        title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: textHighlightedColor,
          activeTrackColor: isDarkModeNotifier.value ? Colors.purple.shade50 : Colors.yellow.shade50,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade800,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  static Widget themeDropdownTile({
    required ThemeMode selectedTheme,
    required ThemeSetter onChanged,
    required bool easterEggMode,
    required EasterEggIconResolver getNextEasterEggIcon,
  }) {
    return Builder(
      builder: (context) {
        return SizedBox(
          height: 44,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            minLeadingWidth: 0,
            horizontalTitleGap: 10,
            leading: RevealIconSwitcher(
              currentIcon: easterEggMode ? getNextEasterEggIcon() : Icons.color_lens,
            ),
            title: Text("App Theme", style: TextStyle(color: textColor, fontSize: 15)),
            trailing: CustomThemeDropdown(
              selectedTheme: selectedTheme,
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

