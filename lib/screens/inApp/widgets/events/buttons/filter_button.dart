import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';

class FilterButton extends StatefulWidget {
  final String selectedValue;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const FilterButton({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  double _scale = 1.0;



  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.7 : 1.0;
    });
  }

  void _showMenu() async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    final result = await showMenu<String>(
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
        PopupMenuItem<String>(
          enabled: false, // disable default wrapper
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: inAppForegroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: textDimColor,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.options.map((value) {
                final isSelected = value == widget.selectedValue;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  onTap: () {
                    Navigator.pop(context, value);
                    widget.onSelected(value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2C3C54) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconTheme.merge(
                          data: const IconThemeData(opacity: 1.0),
                          child: Icon(
                            _statusIcon(value),
                            size: 22,
                            color: isSelected ? textHighlightedColor : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value[0] + value.substring(1).toLowerCase(),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),

                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );

    if (result != null) widget.onSelected(result);
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'UPCOMING':
        return LucideIcons.clock;
      case 'COMPLETED':
        return LucideIcons.checkCircle2;
      case 'CANCELLED':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.slidersHorizontal;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        _showMenu();
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: inAppBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: textDimColor,
                  width: 1.2,
                ),
              ),
              child: Icon(
                LucideIcons.filter,
                color: textColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

