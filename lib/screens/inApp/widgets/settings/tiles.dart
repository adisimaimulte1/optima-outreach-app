import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:optima/globals.dart';


typedef EasterEggIconResolver = IconData Function();
typedef ThemeSetter = void Function(AppThemeMode);

class Tiles {

  static Widget tile({
    required IconData icon,
    required String title,
    bool showArrow = true,
    VoidCallback? onTap,
    required bool easterEggMode,
    required EasterEggIconResolver getNextEasterEggIcon,
  })
  {
    return SizedBox(
      height: 44,
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          easterEggMode ? getNextEasterEggIcon() : icon,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: showArrow ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70) : null,
        onTap: onTap,
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
  })
  {
    return SizedBox(
      height: 44,
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          easterEggMode ? getNextEasterEggIcon() : icon,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFFC62D),
          activeTrackColor: Colors.yellow.shade50,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade800,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  static Widget themeDropdownTile({
    required AppThemeMode selectedTheme,
    required ThemeSetter onChanged,
    required bool easterEggMode,
    required EasterEggIconResolver getNextEasterEggIcon,
  })
  {
    const dropdownBgColor = Color(0xFF24324A);

    return SizedBox(
      height: 44,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        minLeadingWidth: 0,
        horizontalTitleGap: 10,
        leading: Icon(
          easterEggMode ? getNextEasterEggIcon() : Icons.color_lens,
          color: const Color(0xFFFFC62D),
          size: 20,
        ),
        title: const Text("App Theme", style: TextStyle(color: Colors.white, fontSize: 15)),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton2<AppThemeMode>(
            isExpanded: false,
            value: selectedTheme,
            onChanged: (mode) {
              if (mode != null) {
                onChanged(mode);
              }
            },
            items: const [
              DropdownMenuItem(
                value: AppThemeMode.system,
                child: Text("System", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppThemeMode.light,
                child: Text("Light", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: AppThemeMode.dark,
                child: Text("Dark", style: TextStyle(color: Colors.white)),
              ),
            ],
            buttonStyleData: const ButtonStyleData(
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 150,
              decoration: BoxDecoration(
                color: dropdownBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
